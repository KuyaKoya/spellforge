import 'dart:math';
import 'node_type.dart';
import 'map_node.dart';
import 'depth_level.dart';
import 'node_selector.dart';

/// Manages the node map with path choices and progression.
///
/// The node map represents the player's journey through a run,
/// with each depth level offering 1-2 node choices. The system
/// handles generation, selection, and progression through nodes.
class NodeMapSystem {
  final List<DepthLevel> _depths;
  int _currentDepth;
  final NodeSelector _nodeSelector;
  final Random _random;

  /// Default number of depths in a run.
  static const int defaultMaxDepth = 10;

  /// Probability of having a choice at any depth (after depth 1).
  static const double choiceProbability = 0.7;

  NodeMapSystem({int? seed})
    : _depths = [],
      _currentDepth = 0,
      _nodeSelector = NodeSelector(seed: seed),
      _random = seed != null ? Random(seed) : Random();

  // ==================== ACCESSORS ====================

  /// Current depth level.
  DepthLevel? get currentDepthLevel =>
      _currentDepth < _depths.length ? _depths[_currentDepth] : null;

  /// Current selected node.
  MapNode? get currentNode => currentDepthLevel?.selectedNode;

  /// Current depth (1-indexed for display).
  int get currentDepth => _currentDepth + 1;

  /// Current depth (0-indexed for internal use).
  int get currentDepthIndex => _currentDepth;

  /// Phase 7.9.3: Current node index for save/load.
  int get currentNodeIndex => _currentDepth;

  /// Total depths in the run.
  int get totalDepths => _depths.length;

  /// Whether the run is complete.
  bool get isRunComplete => _currentDepth >= _depths.length;

  /// All depth levels (read-only).
  List<DepthLevel> get depths => List.unmodifiable(_depths);

  /// Progress as a percentage (0.0 to 1.0).
  double get progress => _depths.isEmpty ? 0 : _currentDepth / _depths.length;

  // ==================== RUN GENERATION ====================

  /// Generates a new run with strategic node placement.
  /// Implements Phase 7.6: Pre-elite and pre-boss path safety.
  ///
  /// [overrideMaxDepth] - Optional specific depth. If null, randomizes between 10-15.
  void generateRun({int? overrideMaxDepth}) {
    _depths.clear();
    _currentDepth = 0;
    _nodeSelector.reset();

    // Determine total depths for this run
    // If no override, pick random between 10 and 15 (inclusive)
    final int runDepth = overrideMaxDepth ?? (10 + _random.nextInt(6));

    // ========== PHASE 7.6: TWO-PASS GENERATION ==========
    // Pass 1: Pre-plan where elites will appear
    // Pass 2: Generate nodes with path safety context

    // Pre-determine elite positions (roughy every 3-4 depths after depth 4)
    final eliteDepths = _planEliteDepths(runDepth);

    for (int d = 0; d < runDepth; d++) {
      // Set path safety context for this depth
      final isPreBoss = d == runDepth - 2; // Depth before boss
      final nextDepthHasElite = eliteDepths.contains(d + 1);
      final nextDepthIsBoss = d == runDepth - 2;

      _nodeSelector.setPathSafetyContext(
        nextDepthHasEliteOrBoss: nextDepthHasElite || nextDepthIsBoss,
        isPreBossDepth: isPreBoss,
      );

      final nodeChoices = _generateNodesForDepth(
        d,
        runDepth,
        forceElite: eliteDepths.contains(d),
        isPreBoss: isPreBoss,
      );
      _depths.add(DepthLevel(depth: d + 1, nodeChoices: nodeChoices));
    }
  }

  /// Pre-plans where elite nodes should appear based on depth distribution.
  /// Returns a set of depth indices (0-indexed) that should have elites.
  Set<int> _planEliteDepths(int maxDepth) {
    final eliteDepths = <int>{};

    // Elites can appear starting at depth 4 (index 3)
    // Roughly one elite every 3-4 depths, with some randomness
    // Guaranteed 1-2 elites in a standard 10-depth run

    int nextPossibleElite = 3; // First possible elite at depth 4

    while (nextPossibleElite < maxDepth - 1) {
      // Don't place on the depth before boss
      if (nextPossibleElite == maxDepth - 2) break;

      // ~40% chance of elite at eligible depths
      if (_random.nextDouble() < 0.4) {
        eliteDepths.add(nextPossibleElite);
        nextPossibleElite += 3; // Minimum 3 depths between elites
      } else {
        nextPossibleElite++;
      }
    }

    // Ensure at least one elite if none were placed
    if (eliteDepths.isEmpty && maxDepth > 5) {
      // Place elite at depth 5 or 6 (index 4 or 5)
      final fallbackDepth = _random.nextBool() ? 4 : 5;
      if (fallbackDepth < maxDepth - 2) {
        eliteDepths.add(fallbackDepth);
      }
    }

    return eliteDepths;
  }

  /// Generates 1-2 node choices for a specific depth.
  /// [forceElite] - If true, this depth must contain an elite encounter.
  /// [isPreBoss] - If true, this is the pre-boss depth (Phase 7.6 calm before gate).
  List<MapNode> _generateNodesForDepth(
    int depthIndex,
    int maxDepth, {
    bool forceElite = false,
    bool isPreBoss = false,
  }) {
    final depth = depthIndex + 1; // 1-indexed

    // Final depth is always boss
    if (depthIndex == maxDepth - 1) {
      final bossNode = MapNode(
        depth: depth,
        pathIndex: 0,
        type: NodeType.bossCombat,
      );
      _nodeSelector.onNodeCompleted(bossNode.type);
      return [bossNode];
    }

    // Force elite if this depth was pre-planned for elite
    if (forceElite) {
      final eliteNode = MapNode(
        depth: depth,
        pathIndex: 0,
        type: NodeType.elite,
      );
      _nodeSelector.onNodeCompleted(eliteNode.type);
      return [eliteNode];
    }

    // Pre-boss depth: single guaranteed non-combat node (Phase 7.6)
    // No choices - player must take the calm before the gate
    if (isPreBoss) {
      final nodeType = _nodeSelector.selectNodeType(depth);
      final preBossNode = MapNode(
        depth: depth,
        pathIndex: 0,
        type: nodeType,
        isPreBoss: true,
      );
      _nodeSelector.onNodeCompleted(preBossNode.type);
      return [preBossNode];
    }

    // Determine node count (1 or 2)
    final hasChoice = depth > 1 && _random.nextDouble() < choiceProbability;
    final nodeCount = hasChoice ? 2 : 1;

    final nodes = <MapNode>[];

    for (int i = 0; i < nodeCount; i++) {
      final nodeType = _nodeSelector.selectNodeType(
        depth,
        excludeTypes: nodes.map((n) => n.type).toList(),
      );
      nodes.add(MapNode(depth: depth, pathIndex: i, type: nodeType));
    }

    // Update selector with the first/only node - this tracks combat frequency
    // Note: When there are 2 choices, we track based on the first choice
    // since player will only complete one of them
    if (nodes.isNotEmpty) {
      // If ANY choice is combat, consider it combat for tracking purposes
      // This ensures if player picks non-combat, the next depth still respects the limit
      final hasCombatChoice = nodes.any((n) => n.type.isCombat);
      if (hasCombatChoice) {
        _nodeSelector.onNodeCompleted(NodeType.combat);
      } else {
        _nodeSelector.onNodeCompleted(nodes.first.type);
      }
    }

    return nodes;
  }

  // ==================== NODE SELECTION ====================

  /// Selects a node choice at the current depth.
  ///
  /// Returns true if selection was successful.
  bool selectNode(int pathIndex) {
    final depthLevel = currentDepthLevel;
    if (depthLevel == null) return false;

    if (pathIndex < 0 || pathIndex >= depthLevel.nodeChoices.length) {
      return false;
    }

    // Mark the selected node
    for (int i = 0; i < depthLevel.nodeChoices.length; i++) {
      depthLevel.nodeChoices[i].isSelected = (i == pathIndex);
    }

    return true;
  }

  /// Completes the current node and advances to the next depth.
  void completeCurrentNode() {
    final node = currentNode;
    if (node == null) return;

    node.isCompleted = true;

    // Update selector tracking
    _nodeSelector.onNodeCompleted(node.type);

    _currentDepth++;
  }

  // ==================== PREVIEW & NAVIGATION ====================

  /// Gets a preview of upcoming depths.
  ///
  /// [count] - Number of upcoming depths to return
  List<DepthLevel> getUpcomingDepths({int count = 3}) {
    final start = _currentDepth;
    final end = (start + count).clamp(0, _depths.length);
    return _depths.sublist(start, end);
  }

  /// Gets the depth level at a specific index.
  DepthLevel? getDepthAt(int index) {
    if (index < 0 || index >= _depths.length) return null;
    return _depths[index];
  }

  /// Gets all completed depth levels.
  List<DepthLevel> get completedDepths {
    return _depths.where((d) => d.isCompleted).toList();
  }

  // ==================== LIFECYCLE ====================

  /// Resets the node map for a new run.
  void reset() {
    _depths.clear();
    _currentDepth = 0;
    _nodeSelector.reset();
  }

  // ==================== PHASE 7.9.3: SAVE/LOAD ====================

  /// Restores the node map to a specific node index (for save/load).
  void restoreToNode(int nodeIndex) {
    if (nodeIndex >= 0 && nodeIndex <= _depths.length) {
      _currentDepth = nodeIndex;

      // Mark all previous depths as completed
      for (int i = 0; i < nodeIndex; i++) {
        final depthLevel = _depths[i];
        if (depthLevel.nodeChoices.isNotEmpty) {
          depthLevel.nodeChoices.first.isCompleted = true;
          depthLevel.nodeChoices.first.isSelected = true;
        }
      }
    }
  }

  @override
  String toString() {
    return 'NodeMapSystem(depth: $currentDepth/$totalDepths, '
        'complete: $isRunComplete)';
  }
}
