import 'map_node.dart';
import 'node_type.dart';

/// Represents a depth level with 1-2 node choices.
///
/// A depth level is a horizontal "slice" of the node map where the player
/// must choose one path (if multiple choices exist) before proceeding.
class DepthLevel {
  /// The depth number (1-indexed).
  final int depth;

  /// Available node choices at this depth (1-2 nodes).
  final List<MapNode> nodeChoices;

  DepthLevel({required this.depth, required this.nodeChoices});

  /// Whether there's a choice to make at this depth.
  bool get hasChoice => nodeChoices.length > 1;

  /// Whether this depth has been completed.
  bool get isCompleted => nodeChoices.any((node) => node.isCompleted);

  /// Get the selected node (if any is completed or selected).
  MapNode? get selectedNode {
    for (final node in nodeChoices) {
      if (node.isSelected || node.isCompleted) return node;
    }
    return null;
  }

  /// Get the node type(s) available at this depth.
  List<NodeType> get availableTypes => nodeChoices.map((n) => n.type).toList();

  /// Whether any node at this depth involves combat.
  bool get hasCombat => nodeChoices.any((node) => node.type.isCombat);

  /// Get a formatted summary for display.
  String get displaySummary {
    if (hasChoice) {
      return nodeChoices.map((n) => n.shortDisplay).join(' or ');
    }
    return nodeChoices.first.shortDisplay;
  }

  @override
  String toString() => 'DepthLevel($depth, choices: ${nodeChoices.length})';
}
