import '../domain/element.dart';
import 'node_modifier.dart';

/// Represents a single node in an elemental path.
/// Each node has a cost, a benefit effect, and a tradeoff.
class ElementalNode {
  /// The element this node belongs to.
  final Element element;

  /// The index of this node in the path (0-9).
  final int index;

  /// The tier of this node (1-3).
  /// Tier 1: Nodes 0-2, Tier 2: Nodes 3-5, Tier 3: Nodes 6-9
  int get tier {
    if (index < 3) return 1;
    if (index < 6) return 2;
    return 3;
  }

  /// Crystal cost to unlock this node.
  final int cost;

  /// The name/title of this node.
  final String name;

  /// Description of the benefit effect.
  final String effectDescription;

  /// Description of the tradeoff.
  final String tradeoffDescription;

  /// The benefit modifier this node provides.
  final NodeModifier benefit;

  /// The tradeoff modifier this node applies.
  final NodeModifier tradeoff;

  /// Whether this is a passive ability (tier 3, node 10).
  final bool isPassive;

  /// Passive ability name (if applicable).
  final String? passiveName;

  const ElementalNode({
    required this.element,
    required this.index,
    required this.cost,
    required this.name,
    required this.effectDescription,
    required this.tradeoffDescription,
    required this.benefit,
    required this.tradeoff,
    this.isPassive = false,
    this.passiveName,
  });

  /// Display name for the node (e.g., "Fire I" or "Infernal Momentum").
  String get displayName =>
      isPassive && passiveName != null ? passiveName! : name;

  /// Gets the tier icon.
  String get tierIcon {
    switch (tier) {
      case 1:
        return '●';
      case 2:
        return '◆';
      case 3:
        return '★';
      default:
        return '○';
    }
  }

  @override
  String toString() => '$displayName (${element.displayName} T$tier)';
}

/// Cost scaling for elemental nodes.
class NodeCostScale {
  /// Gets the cost for a node at the given index.
  static int getCost(int index) {
    switch (index) {
      case 0:
        return 10;
      case 1:
        return 15;
      case 2:
        return 20;
      case 3:
        return 30;
      case 4:
        return 40;
      case 5:
        return 50;
      case 6:
        return 75;
      case 7:
        return 90;
      case 8:
        return 105;
      case 9:
        return 120;
      default:
        return 150 + (index - 10) * 30; // Future expansion
    }
  }

  /// Gets the total cost to unlock all nodes up to and including the given index.
  static int getTotalCost(int index) {
    int total = 0;
    for (int i = 0; i <= index; i++) {
      total += getCost(i);
    }
    return total;
  }

  /// Tier 1 total: 10 + 15 + 20 = 45 crystals
  static const int tier1Total = 45;

  /// Tier 2 total: 30 + 40 + 50 = 120 crystals
  static const int tier2Total = 120;

  /// Tier 3 total: 75 + 90 + 105 + 120 = 390 crystals
  static const int tier3Total = 390;

  /// Total for all 10 nodes: 555 crystals
  static const int allNodesTotal = 555;
}
