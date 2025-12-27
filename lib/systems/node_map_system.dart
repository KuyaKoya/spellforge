import 'dart:math';

/// Types of nodes in the game.
enum NodeType {
  combat,
  spellLearn,
  enhancementShrine,
  shop,
  rest,
  elite,
  randomEvent,
  bossCombat;

  String get displayName {
    switch (this) {
      case NodeType.combat:
        return 'Combat';
      case NodeType.spellLearn:
        return 'Spell Shrine';
      case NodeType.enhancementShrine:
        return 'Enhancement Shrine';
      case NodeType.shop:
        return 'Shop';
      case NodeType.rest:
        return 'Rest Site';
      case NodeType.elite:
        return 'Elite Combat';
      case NodeType.randomEvent:
        return 'Random Event';
      case NodeType.bossCombat:
        return 'Boss Battle';
    }
  }

  String get description {
    switch (this) {
      case NodeType.combat:
        return 'Battle against elemental creatures.';
      case NodeType.spellLearn:
        return 'Learn a new spell from the arcane pool.';
      case NodeType.enhancementShrine:
        return 'Upgrade one of your spells.';
      case NodeType.shop:
        return 'Trade resources for powerful items.';
      case NodeType.rest:
        return 'Rest and recover HP.';
      case NodeType.elite:
        return 'Face a powerful foe for great rewards.';
      case NodeType.randomEvent:
        return 'Something unexpected awaits...';
      case NodeType.bossCombat:
        return 'Face the elemental guardian!';
    }
  }

  String get icon {
    switch (this) {
      case NodeType.combat:
        return '⚔️';
      case NodeType.spellLearn:
        return '📖';
      case NodeType.enhancementShrine:
        return '⭐';
      case NodeType.shop:
        return '🏪';
      case NodeType.rest:
        return '🛏️';
      case NodeType.elite:
        return '💀';
      case NodeType.randomEvent:
        return '❓';
      case NodeType.bossCombat:
        return '👹';
    }
  }

  /// Whether this node type involves combat.
  bool get isCombat =>
      this == NodeType.combat ||
      this == NodeType.elite ||
      this == NodeType.bossCombat;
}

/// Represents a single node in the run.
class MapNode {
  final int depth;
  final int pathIndex; // 0 or 1 for branching paths
  final NodeType type;
  bool isCompleted;
  bool isSelected;

  MapNode({
    required this.depth,
    required this.pathIndex,
    required this.type,
    this.isCompleted = false,
    this.isSelected = false,
  });

  String get displayText => '${type.icon} Depth $depth: ${type.displayName}';

  String get shortDisplay => '${type.icon} ${type.displayName}';
}

/// Represents a depth level with 1-2 node choices.
class DepthLevel {
  final int depth;
  final List<MapNode> nodeChoices;

  DepthLevel({required this.depth, required this.nodeChoices});

  /// Whether there's a choice to make at this depth.
  bool get hasChoice => nodeChoices.length > 1;

  /// Get the selected node (if any is completed or selected).
  MapNode? get selectedNode {
    for (final node in nodeChoices) {
      if (node.isSelected || node.isCompleted) return node;
    }
    return null;
  }
}

/// Manages the node map with path choices and progression.
class NodeMapSystem {
  final List<DepthLevel> _depths;
  int _currentDepth;
  final Random _random;

  // Track last node type for sequencing rules
  NodeType? _lastNodeType;
  int _turnsSinceCombat = 0;

  NodeMapSystem({int? seed})
    : _depths = [],
      _currentDepth = 0,
      _random = seed != null ? Random(seed) : Random();

  // ==================== ACCESSORS ====================

  /// Current depth level.
  DepthLevel? get currentDepthLevel =>
      _currentDepth < _depths.length ? _depths[_currentDepth] : null;

  /// Current selected node.
  MapNode? get currentNode => currentDepthLevel?.selectedNode;

  /// Current depth (1-indexed for display).
  int get currentDepth => _currentDepth + 1;

  /// Total depths in the run.
  int get totalDepths => _depths.length;

  /// Whether the run is complete.
  bool get isRunComplete => _currentDepth >= _depths.length;

  /// All depth levels.
  List<DepthLevel> get depths => List.unmodifiable(_depths);

  // ==================== RUN GENERATION ====================

  /// Generates a new run with strategic node placement.
  void generateRun({int maxDepth = 10}) {
    _depths.clear();
    _currentDepth = 0;
    _lastNodeType = null;
    _turnsSinceCombat = 0;

    for (int d = 0; d < maxDepth; d++) {
      final nodeChoices = _generateNodesForDepth(d);
      _depths.add(DepthLevel(depth: d + 1, nodeChoices: nodeChoices));
    }
  }

  /// Generates 1-2 node choices for a specific depth.
  List<MapNode> _generateNodesForDepth(int depthIndex) {
    final depth = depthIndex + 1; // 1-indexed

    // Final depth is always boss
    if (depthIndex == 9) {
      return [MapNode(depth: depth, pathIndex: 0, type: NodeType.bossCombat)];
    }

    // Determine node count (1 or 2)
    final hasChoice = depth > 1 && _random.nextDouble() < 0.7;
    final nodeCount = hasChoice ? 2 : 1;

    final nodes = <MapNode>[];

    for (int i = 0; i < nodeCount; i++) {
      final nodeType = _selectNodeType(
        depth,
        existingTypes: nodes.map((n) => n.type).toList(),
      );
      nodes.add(MapNode(depth: depth, pathIndex: i, type: nodeType));
    }

    return nodes;
  }

  /// Selects a node type based on depth and constraints.
  NodeType _selectNodeType(int depth, {List<NodeType>? existingTypes}) {
    final available = _getAvailableNodeTypes(depth);

    // Filter out existing types for this depth (avoid duplicates in choices)
    final filtered = existingTypes != null
        ? available.where((t) => !existingTypes.contains(t)).toList()
        : available;

    if (filtered.isEmpty) return NodeType.combat;

    // Weighted selection based on depth
    return _weightedSelect(filtered, depth);
  }

  /// Gets available node types based on depth and constraints.
  List<NodeType> _getAvailableNodeTypes(int depth) {
    final available = <NodeType>[];

    // Combat is always available
    available.add(NodeType.combat);

    // Shrine: Low early, Medium later
    if (depth >= 2) {
      available.add(NodeType.spellLearn);
      available.add(NodeType.enhancementShrine);
    }

    // Shop: Not available depth 1-2
    if (depth >= 3) {
      available.add(NodeType.shop);
    }

    // Rest: Low availability throughout
    if (depth >= 2) {
      available.add(NodeType.rest);
    }

    // Elite: Not available before depth 4
    if (depth >= 4) {
      available.add(NodeType.elite);
    }

    // Random event
    if (depth >= 3) {
      available.add(NodeType.randomEvent);
    }

    // Apply global constraints
    return _applyConstraints(available, depth);
  }

  /// Applies global sequencing constraints.
  List<NodeType> _applyConstraints(List<NodeType> types, int depth) {
    var filtered = List<NodeType>.from(types);

    // Constraint: Same node type cannot appear twice in a row
    if (_lastNodeType != null) {
      filtered.remove(_lastNodeType);
    }

    // Constraint: Combat must appear at least once every 2 depths
    if (_turnsSinceCombat >= 2) {
      return [NodeType.combat];
    }

    // Ensure we still have options
    if (filtered.isEmpty) {
      filtered = [NodeType.combat];
    }

    return filtered;
  }

  /// Weighted random selection based on depth.
  NodeType _weightedSelect(List<NodeType> types, int depth) {
    final weights = <NodeType, double>{};

    for (final type in types) {
      weights[type] = _getWeight(type, depth);
    }

    // Normalize and select
    final totalWeight = weights.values.fold(0.0, (a, b) => a + b);
    double roll = _random.nextDouble() * totalWeight;

    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll <= 0) return entry.key;
    }

    return types.first;
  }

  /// Gets the weight for a node type at a given depth.
  double _getWeight(NodeType type, int depth) {
    // Depth ranges: 1-2, 3-4, 5-7, 8+
    switch (type) {
      case NodeType.combat:
        if (depth <= 2) return 3.0; // High
        return 2.0; // Medium

      case NodeType.spellLearn:
      case NodeType.enhancementShrine:
        if (depth <= 2) return 0.5; // Low
        if (depth <= 4) return 1.5; // Medium
        if (depth <= 7) return 1.5; // Medium
        return 1.0; // Low

      case NodeType.shop:
        if (depth <= 2) return 0.0; // None
        if (depth <= 4) return 0.5; // Low
        return 1.5; // Medium

      case NodeType.rest:
        return 0.5; // Low throughout

      case NodeType.elite:
        if (depth < 4) return 0.0; // None
        if (depth <= 4) return 0.5; // Low
        if (depth <= 7) return 1.5; // Medium
        return 2.5; // High

      case NodeType.randomEvent:
        return 0.5; // Low

      case NodeType.bossCombat:
        return 0.0; // Only at depth 10
    }
  }

  // ==================== NODE SELECTION ====================

  /// Selects a node choice at the current depth.
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

  /// Completes the current node and advances.
  void completeCurrentNode() {
    final node = currentNode;
    if (node == null) return;

    node.isCompleted = true;

    // Update tracking
    _lastNodeType = node.type;
    if (node.type.isCombat) {
      _turnsSinceCombat = 0;
    } else {
      _turnsSinceCombat++;
    }

    _currentDepth++;
  }

  /// Gets a preview of upcoming depths.
  List<DepthLevel> getUpcomingDepths({int count = 3}) {
    final start = _currentDepth;
    final end = (start + count).clamp(0, _depths.length);
    return _depths.sublist(start, end);
  }

  /// Resets the node map for a new run.
  void reset() {
    _depths.clear();
    _currentDepth = 0;
    _lastNodeType = null;
    _turnsSinceCombat = 0;
  }
}
