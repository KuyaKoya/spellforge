import 'node_type.dart';

/// Represents a single node in the run.
///
/// Each node has a depth (position in the run), a path index (for branching),
/// and a type that determines what encounter/event the player will face.
class MapNode {
  /// The depth level of this node (1-indexed).
  final int depth;

  /// Path index for branching (0 or 1).
  final int pathIndex;

  /// The type of node (combat, shop, etc.).
  final NodeType type;

  /// Whether this node has been completed.
  bool isCompleted;

  /// Whether this node is currently selected (for path choices).
  bool isSelected;

  /// Whether this is the pre-boss node (Phase 7.6).
  /// Used for "calm before the gate" narrative framing.
  final bool isPreBoss;

  MapNode({
    required this.depth,
    required this.pathIndex,
    required this.type,
    this.isCompleted = false,
    this.isSelected = false,
    this.isPreBoss = false,
  });

  /// Formatted display text with depth info.
  /// Phase 7.6: Pre-boss nodes show "calm before the gate" narrative.
  String get displayText {
    if (isPreBoss) {
      return '${type.icon} The calm before the gate...';
    }
    return '${type.icon} Depth $depth: ${type.displayName}';
  }

  /// Short display text without depth.
  String get shortDisplay {
    if (isPreBoss) {
      return '${type.icon} Prepare yourself...';
    }
    return '${type.icon} ${type.displayName}';
  }

  /// Whether this node is accessible (not completed and not blocked).
  bool get isAccessible => !isCompleted;

  /// Whether this node can be rerolled (Phase 7.6).
  /// Pre-boss nodes cannot be rerolled - they are guaranteed non-combat.
  bool get canReroll => !isPreBoss;

  /// Creates a copy of this node with optional overrides.
  MapNode copyWith({
    int? depth,
    int? pathIndex,
    NodeType? type,
    bool? isCompleted,
    bool? isSelected,
    bool? isPreBoss,
  }) {
    return MapNode(
      depth: depth ?? this.depth,
      pathIndex: pathIndex ?? this.pathIndex,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      isSelected: isSelected ?? this.isSelected,
      isPreBoss: isPreBoss ?? this.isPreBoss,
    );
  }

  @override
  String toString() =>
      'MapNode($depth, $type, completed: $isCompleted, preBoss: $isPreBoss)';
}
