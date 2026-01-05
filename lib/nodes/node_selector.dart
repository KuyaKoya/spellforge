import 'dart:math';
import 'node_type.dart';

/// Configuration for node selection weights at different depth ranges.
class NodeWeightConfig {
  /// Depth ranges and their associated weights.
  static const Map<NodeType, List<double>> weights = {
    // Format: [depth 1-2, depth 3-4, depth 5-7, depth 8+]
    NodeType.combat: [3.0, 2.0, 2.0, 2.0],
    NodeType.spellLearn: [0.5, 1.5, 1.5, 1.0],
    NodeType.enhancementShrine: [0.5, 1.5, 1.5, 1.0],
    NodeType.shop: [0.0, 0.5, 1.5, 1.5],
    NodeType.rest: [0.5, 0.5, 0.5, 0.5],
    NodeType.elite: [0.0, 0.5, 1.5, 2.5],
    NodeType.randomEvent: [0.5, 0.5, 0.5, 0.5],
    NodeType.bossCombat: [0.0, 0.0, 0.0, 0.0], // Only at depth 10
  };

  /// Get the weight for a node type at a specific depth.
  static double getWeight(NodeType type, int depth) {
    final typeWeights = weights[type] ?? [1.0, 1.0, 1.0, 1.0];

    if (depth <= 2) return typeWeights[0];
    if (depth <= 4) return typeWeights[1];
    if (depth <= 7) return typeWeights[2];
    return typeWeights[3];
  }
}

/// Configuration for node availability constraints.
class NodeAvailabilityConfig {
  /// Minimum depth for each node type to become available.
  static const Map<NodeType, int> minDepth = {
    NodeType.combat: 1,
    NodeType.spellLearn: 2,
    NodeType.enhancementShrine: 2,
    NodeType.shop: 3,
    NodeType.rest: 2,
    NodeType.elite: 4,
    NodeType.randomEvent: 3,
    NodeType.bossCombat: 10, // Only at final depth
  };

  /// Check if a node type is available at the given depth.
  static bool isAvailable(NodeType type, int depth) {
    return depth >= (minDepth[type] ?? 1);
  }
}

/// Handles node type selection with weighted randomization and constraints.
///
/// This class encapsulates the logic for choosing what type of node
/// appears at each depth, considering:
/// - Depth-based availability
/// - Weight-based probability
/// - Sequencing constraints (no repeats, combat frequency)
/// - Pre-elite/pre-boss path safety (Phase 7.6)
class NodeSelector {
  final Random _random;

  /// Track last node type for sequencing rules.
  NodeType? lastNodeType;

  /// Turns since last combat node.
  int turnsSinceCombat = 0;

  /// Maximum turns allowed without combat.
  static const int maxTurnsWithoutCombat = 1;

  /// Whether the next depth after current selection will have an elite/boss.
  /// Used for pre-elite/pre-boss path safety (Phase 7.6).
  bool _nextDepthHasEliteOrBoss = false;

  /// Whether current depth is immediately before boss.
  /// Used to enforce guaranteed non-combat before boss (Phase 7.6).
  bool _isPreBossDepth = false;

  NodeSelector({int? seed}) : _random = seed != null ? Random(seed) : Random();

  /// Sets the context for path safety enforcement (Phase 7.6).
  /// Call this before selecting nodes for a depth when generating the map.
  void setPathSafetyContext({
    required bool nextDepthHasEliteOrBoss,
    required bool isPreBossDepth,
  }) {
    _nextDepthHasEliteOrBoss = nextDepthHasEliteOrBoss;
    _isPreBossDepth = isPreBossDepth;
  }

  /// Selects a node type for the given depth.
  ///
  /// [depth] - The depth level (1-indexed)
  /// [excludeTypes] - Types to exclude (e.g., other choices at same depth)
  NodeType selectNodeType(int depth, {List<NodeType>? excludeTypes}) {
    final available = getAvailableNodeTypes(depth);

    // Filter out excluded types (avoid duplicates in choices)
    var filtered = excludeTypes != null
        ? available.where((t) => !excludeTypes.contains(t)).toList()
        : available;

    if (filtered.isEmpty) return NodeType.combat;

    return _weightedSelect(filtered, depth);
  }

  /// Gets available node types for a depth, applying all constraints.
  List<NodeType> getAvailableNodeTypes(int depth) {
    final available = <NodeType>[];

    // Add all types that are available at this depth
    for (final type in NodeType.values) {
      if (NodeAvailabilityConfig.isAvailable(type, depth)) {
        // Skip boss combat except at final depth
        if (type == NodeType.bossCombat && depth != 10) continue;
        available.add(type);
      }
    }

    // Apply sequencing constraints
    return _applyConstraints(available, depth);
  }

  /// Applies global sequencing constraints and path safety rules (Phase 7.6).
  List<NodeType> _applyConstraints(List<NodeType> types, int depth) {
    var filtered = List<NodeType>.from(types);

    // ========== PHASE 7.6: PATH SAFETY (highest priority) ==========

    // Rule 13.2: Pre-Boss depth MUST be non-combat
    // This cannot be overridden by any other constraint
    if (_isPreBossDepth) {
      final safeTypes = filtered
          .where((t) => t.isAllowedBeforeEliteOrBoss)
          .toList();
      if (safeTypes.isNotEmpty) {
        // Prefer Enhancement Shrine > Rest > Spell Learn > Shop
        const preBossPreference = [
          NodeType.enhancementShrine,
          NodeType.rest,
          NodeType.spellLearn,
          NodeType.shop,
        ];
        for (final preferred in preBossPreference) {
          if (safeTypes.contains(preferred)) {
            return [preferred];
          }
        }
        return safeTypes;
      }
      // Fallback: if no safe types available at this depth, force rest
      return [NodeType.rest];
    }

    // Rule 13.1: If next depth has elite, ensure non-combat options available
    // This ensures at least one adjacent non-combat node is reachable before elite
    if (_nextDepthHasEliteOrBoss) {
      final nonCombatTypes = filtered.where((t) => t.isNonCombat).toList();
      if (nonCombatTypes.isNotEmpty) {
        // Boost weight of non-combat but don't force - player has agency
        filtered = nonCombatTypes;
      }
    }

    // ========== STANDARD CONSTRAINTS ==========

    // Constraint: Same node type cannot appear twice in a row
    if (lastNodeType != null) {
      filtered.remove(lastNodeType);
    }

    // Constraint: Combat must appear at least once every N depths
    // BUT this is overridden by pre-elite/pre-boss path safety
    if (turnsSinceCombat >= maxTurnsWithoutCombat &&
        !_nextDepthHasEliteOrBoss) {
      return [NodeType.combat];
    }

    // Ensure we still have options
    if (filtered.isEmpty) {
      // If pre-elite, default to non-combat; otherwise default to combat
      if (_nextDepthHasEliteOrBoss) {
        return [NodeType.rest];
      }
      filtered = [NodeType.combat];
    }

    return filtered;
  }

  /// Weighted random selection based on depth.
  NodeType _weightedSelect(List<NodeType> types, int depth) {
    final weights = <NodeType, double>{};

    for (final type in types) {
      weights[type] = NodeWeightConfig.getWeight(type, depth);
    }

    // Normalize and select
    final totalWeight = weights.values.fold(0.0, (a, b) => a + b);
    if (totalWeight == 0) return types.first;

    double roll = _random.nextDouble() * totalWeight;

    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll <= 0) return entry.key;
    }

    return types.first;
  }

  /// Updates tracking after a node is completed.
  void onNodeCompleted(NodeType type) {
    lastNodeType = type;
    if (type.isCombat) {
      turnsSinceCombat = 0;
    } else {
      turnsSinceCombat++;
    }
  }

  /// Resets selector state for a new run.
  void reset() {
    lastNodeType = null;
    turnsSinceCombat = 0;
    _nextDepthHasEliteOrBoss = false;
    _isPreBossDepth = false;
  }
}
