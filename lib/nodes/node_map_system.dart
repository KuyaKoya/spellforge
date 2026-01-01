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
  ///
  /// [maxDepth] - Number of depths to generate (default: 10)
  void generateRun({int maxDepth = defaultMaxDepth}) {
    _depths.clear();
    _currentDepth = 0;
    _nodeSelector.reset();

    for (int d = 0; d < maxDepth; d++) {
      final nodeChoices = _generateNodesForDepth(d, maxDepth);
      _depths.add(DepthLevel(depth: d + 1, nodeChoices: nodeChoices));
    }
  }

  /// Generates 1-2 node choices for a specific depth.
  List<MapNode> _generateNodesForDepth(int depthIndex, int maxDepth) {
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

  @override
  String toString() {
    return 'NodeMapSystem(depth: $currentDepth/$totalDepths, '
        'complete: $isRunComplete)';
  }
}
