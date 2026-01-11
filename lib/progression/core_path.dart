import 'node_modifier.dart';

/// The currency type used for unlocking a core node.
enum CoreCurrency { fragments, crystals }

/// Represents a single node in the core path.
/// Core nodes provide generic bonuses that apply to all elements.
class CoreNode {
  /// The index of this node in the path (0-9).
  final int index;

  /// The tier of this node (1-3).
  /// Tier 1: Nodes 0-2 (fragments), Tier 2: Nodes 3-5, Tier 3: Nodes 6-9 (crystals)
  int get tier {
    if (index < 3) return 1;
    if (index < 6) return 2;
    return 3;
  }

  /// The currency required to unlock this node.
  CoreCurrency get currency =>
      tier == 1 ? CoreCurrency.fragments : CoreCurrency.crystals;

  /// Cost to unlock this node.
  final int cost;

  /// The name/title of this node.
  final String name;

  /// Description of the benefit effect.
  final String effectDescription;

  /// The benefit modifier this node provides.
  final NodeModifier benefit;

  /// Whether this is the capstone passive ability.
  final bool isCapstone;

  const CoreNode({
    required this.index,
    required this.cost,
    required this.name,
    required this.effectDescription,
    required this.benefit,
    this.isCapstone = false,
  });

  /// Display name for the node.
  String get displayName => name;

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

  /// Gets the currency icon.
  String get currencyIcon => currency == CoreCurrency.fragments ? '🔮' : '✨';

  @override
  String toString() => '$displayName (Core T$tier)';
}

/// The complete core path definition.
class CorePath {
  static const String icon = '🌟';
  static const String name = 'Core';
  static const String theme = 'Universal Power';
  static const String description =
      'Foundational bonuses that enhance all abilities. '
      'Early nodes use fragments, later ones require crystals.';

  /// All nodes in the core path.
  final List<CoreNode> nodes;

  const CorePath({required this.nodes});

  /// Gets the maximum number of nodes.
  int get maxNodes => nodes.length;

  /// Gets nodes by tier.
  List<CoreNode> getNodesByTier(int tier) {
    return nodes.where((n) => n.tier == tier).toList();
  }
}

/// Cost scaling for core nodes.
/// Tier 1 uses fragments (cheaper), Tier 2-3 use crystals.
class CoreNodeCostScale {
  /// Gets the cost for a node at the given index.
  static int getCost(int index) {
    switch (index) {
      // Tier 1: Fragments (affordable)
      case 0:
        return 25; // fragments
      case 1:
        return 40; // fragments
      case 2:
        return 60; // fragments
      // Tier 2: Crystals (moderate)
      case 3:
        return 15; // crystals
      case 4:
        return 25; // crystals
      case 5:
        return 35; // crystals
      // Tier 3: Crystals (expensive)
      case 6:
        return 50; // crystals
      case 7:
        return 65; // crystals
      case 8:
        return 80; // crystals
      case 9:
        return 100; // crystals
      default:
        return 120 + (index - 10) * 25;
    }
  }

  /// Tier 1 total: 25 + 40 + 60 = 125 fragments
  static const int tier1TotalFragments = 125;

  /// Tier 2 total: 15 + 25 + 35 = 75 crystals
  static const int tier2TotalCrystals = 75;

  /// Tier 3 total: 50 + 65 + 80 + 100 = 295 crystals
  static const int tier3TotalCrystals = 295;
}

/// Registry/singleton for the core path.
class CorePathRegistry {
  static CorePath? _path;

  /// Registers the core path.
  static void register(CorePath path) {
    _path = path;
  }

  /// Gets the core path.
  static CorePath? get path => _path;

  /// Whether the path has been initialized.
  static bool get isInitialized => _path != null;

  /// Clears the path (for testing).
  static void clear() => _path = null;

  /// Gets active modifiers from unlocked core nodes.
  static List<NodeModifier> getActiveModifiers(int unlockedCount) {
    if (_path == null) return [];

    final modifiers = <NodeModifier>[];
    for (int i = 0; i < unlockedCount && i < _path!.nodes.length; i++) {
      modifiers.add(_path!.nodes[i].benefit);
    }
    return modifiers;
  }
}
