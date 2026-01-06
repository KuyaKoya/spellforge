import '../domain/element.dart';
import 'elemental_node.dart';
import 'node_modifier.dart';

/// Represents a complete elemental path with all its nodes.
class ElementalPath {
  /// The element this path represents.
  final Element element;

  /// The thematic focus of this path.
  final String theme;

  /// Description of the path's playstyle.
  final String description;

  /// All nodes in this path (typically 10).
  final List<ElementalNode> nodes;

  const ElementalPath({
    required this.element,
    required this.theme,
    required this.description,
    required this.nodes,
  });

  /// Gets the icon for this path's element.
  String get icon => element.icon;

  /// Gets the display color for this element.
  int get colorValue {
    switch (element) {
      case Element.fire:
        return 0xFFFF9800; // Orange
      case Element.water:
        return 0xFF2196F3; // Blue
      case Element.earth:
        return 0xFF795548; // Brown
      case Element.air:
        return 0xFF009688; // Teal
    }
  }

  /// Gets nodes by tier.
  List<ElementalNode> getNodesByTier(int tier) {
    return nodes.where((n) => n.tier == tier).toList();
  }

  /// Gets the maximum number of nodes.
  int get maxNodes => nodes.length;

  /// Gets a summary of what this path offers.
  String get summary {
    return '${element.icon} ${element.displayName}: $theme';
  }
}

/// Central registry for all elemental paths.
class ElementalPathRegistry {
  static final Map<Element, ElementalPath> _paths = {};

  /// Registers a path for an element.
  static void register(ElementalPath path) {
    _paths[path.element] = path;
  }

  /// Gets the path for an element.
  static ElementalPath? getPath(Element element) => _paths[element];

  /// Gets all registered paths.
  static List<ElementalPath> get allPaths => _paths.values.toList();

  /// Clears all paths (for testing).
  static void clear() => _paths.clear();

  /// Whether paths have been initialized.
  static bool get isInitialized => _paths.isNotEmpty;

  /// Gets all unlocked modifiers given the unlock state.
  static List<NodeModifier> getActiveModifiers(
    Map<Element, int> unlockedNodes,
  ) {
    final modifiers = <NodeModifier>[];

    for (final entry in unlockedNodes.entries) {
      final path = getPath(entry.key);
      if (path == null) continue;

      final unlockedCount = entry.value;
      for (int i = 0; i < unlockedCount && i < path.nodes.length; i++) {
        final node = path.nodes[i];
        modifiers.add(node.benefit);
        modifiers.add(node.tradeoff);
      }
    }

    return modifiers;
  }
}
