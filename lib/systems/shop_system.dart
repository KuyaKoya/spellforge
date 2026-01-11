import 'dart:math';
import '../domain/spell.dart';
import '../data/spell_definitions.dart';
import '../data/item_definitions.dart';
import '../domain/mage.dart';
import '../progression/run_state.dart';
import '../progression/spell_pool_manager.dart';
import 'progression_system.dart';

export '../progression/run_state.dart' show TemporaryBuff;

/// Types of items available in the shop.
enum ShopItemType {
  spellFragments,
  spellCrystal,
  randomSpell,
  heal,
  tempBuff,
  consumable,
  relic;

  String get displayName {
    switch (this) {
      case ShopItemType.spellFragments:
        return 'Spell Fragments';
      case ShopItemType.spellCrystal:
        return 'Spell Crystal';
      case ShopItemType.randomSpell:
        return 'Random Spell';
      case ShopItemType.heal:
        return 'Health Potion';
      case ShopItemType.tempBuff:
        return 'Power Surge';
      case ShopItemType.consumable:
      case ShopItemType.relic:
        return 'Item';
    }
  }

  String get icon {
    switch (this) {
      case ShopItemType.spellFragments:
        return '💎';
      case ShopItemType.spellCrystal:
        return '✨';
      case ShopItemType.randomSpell:
        return '📜';
      case ShopItemType.heal:
        return '❤️';
      case ShopItemType.tempBuff:
        return '⚡';
      case ShopItemType.consumable:
        return '🧪';
      case ShopItemType.relic:
        return '💍';
    }
  }

  String get description {
    switch (this) {
      case ShopItemType.spellFragments:
        return 'A bundle of spell fragments for upgrading.';
      case ShopItemType.spellCrystal:
        return 'A rare crystal with immense magical power.';
      case ShopItemType.randomSpell:
        return 'Learn a random spell (rarity based on depth).';
      case ShopItemType.heal:
        return 'Restores a portion of your HP.';
      case ShopItemType.tempBuff:
        return 'Gain a temporary damage boost for 3 nodes.';
      case ShopItemType.consumable:
      case ShopItemType.relic:
        return 'An item for your journey.';
    }
  }
}

/// Represents a purchasable item in the shop.
class ShopItem {
  final ShopItemType type;
  final int cost;
  final int value; // Amount for fragments, HP for heal, etc.
  final Spell? spell; // For random spell type
  final ItemDefinition? itemDefinition; // For consumables/relics
  bool isPurchased;

  ShopItem({
    required this.type,
    required this.cost,
    required this.value,
    this.spell,
    this.itemDefinition,
    this.isPurchased = false,
  });

  String get displayName => spell?.displayName ?? type.displayName;

  String get displayText {
    switch (type) {
      case ShopItemType.spellFragments:
        return '${type.icon} $value Fragments';
      case ShopItemType.spellCrystal:
        return '${type.icon} $value Crystal(s)';
      case ShopItemType.randomSpell:
        if (spell != null) {
          return '${spell!.elementIcon} ${spell!.displayName} ${spell!.rarity.icon}';
        }
        return '${type.icon} ${type.displayName}';
      case ShopItemType.heal:
        return '${type.icon} Heal $value HP';
      case ShopItemType.tempBuff:
        return '${type.icon} +$value% Damage (3 nodes)';
      case ShopItemType.consumable:
      case ShopItemType.relic:
        return '${type.icon} ${itemDefinition?.name ?? 'Unknown Item'}';
    }
  }

  String get description {
    if (itemDefinition != null) {
      return itemDefinition!.description;
    }
    return type.description;
  }

  String get costText => '💰 $cost fragments';
}

/// Manages the shop inventory for a shop node.
class ShopSystem {
  final List<ShopItem> items;
  final int depth;

  ShopSystem({required this.items, required this.depth});

  /// Available items that haven't been purchased.
  List<ShopItem> get availableItems =>
      items.where((i) => !i.isPurchased).toList();

  /// Checks if a purchase can be made.
  bool canPurchase(ShopItem item, int playerFragments) {
    return !item.isPurchased && playerFragments >= item.cost;
  }

  /// Marks an item as purchased.
  void purchaseItem(ShopItem item) {
    item.isPurchased = true;
  }

  /// Generates a shop inventory based on depth.
  static ShopSystem generateShop({
    required int depth,
    List<String>? knownSpellIds,
    int? seed,
  }) {
    final random = seed != null ? Random(seed) : Random();
    final items = <ShopItem>[];

    // Fragment bundle (always available)
    final fragmentAmount = 30 + (depth * 5);
    final fragmentCost = 20 + (depth * 3);
    items.add(
      ShopItem(
        type: ShopItemType.spellFragments,
        cost: fragmentCost,
        value: fragmentAmount,
      ),
    );

    // Spell Crystal (available after depth 4)
    if (depth >= 4 && random.nextDouble() < 0.6) {
      items.add(
        ShopItem(
          type: ShopItemType.spellCrystal,
          cost: 80 + (depth * 10),
          value: 1,
        ),
      );
    }

    // Random Spell (rarity based on depth)
    SpellRarity maxRarity;
    if (depth < 4) {
      maxRarity = SpellRarity.common;
    } else if (depth < 7) {
      maxRarity = SpellRarity.uncommon;
    } else {
      maxRarity = SpellRarity.rare;
    }

    final availableSpells = SpellDefinitions.getRandomSelection(
      count: 1,
      maxRarity: maxRarity,
      excludeIds: knownSpellIds,
    );

    if (availableSpells.isNotEmpty) {
      final spell = availableSpells.first;
      final spellCost = _getSpellCost(spell.rarity);
      items.add(
        ShopItem(
          type: ShopItemType.randomSpell,
          cost: spellCost,
          value: 0,
          spell: spell,
        ),
      );
    }

    // Health Potion (always available)
    final healAmount = 15 + (depth * 2);
    items.add(
      ShopItem(
        type: ShopItemType.heal,
        cost: 15 + (depth * 2),
        value: healAmount,
      ),
    );

    // Power Surge (temporary buff)
    if (random.nextDouble() < 0.5) {
      items.add(
        ShopItem(
          type: ShopItemType.tempBuff,
          cost: 25 + (depth * 5),
          value: 25, // 25% damage boost
        ),
      );
    }

    return ShopSystem(items: items, depth: depth);
  }

  /// Gets the cost for a spell based on rarity.
  static int _getSpellCost(SpellRarity rarity) {
    switch (rarity) {
      case SpellRarity.common:
        return 30;
      case SpellRarity.uncommon:
        return 50;
      case SpellRarity.rare:
        return 80;
      case SpellRarity.signature:
        return 150;
      case SpellRarity.legendary:
        return 200;
    }
  }

  /// Processes the purchase of an item (logic only, doesn't update UI).
  /// Returns a string message describing the result.
  static String performPurchaseEffect({
    required ShopItem item,
    required Mage mage,
    required ProgressionSystem progression,
    required Function() onSpellLearned,
    required Function(TemporaryBuff) onBuffAdded,
  }) {
    switch (item.type) {
      case ShopItemType.spellFragments:
        progression.addFragments(item.value);
        return 'Gained ${item.value} Fragments';

      case ShopItemType.spellCrystal:
        progression.addCrystals(item.value);
        return 'Gained ${item.value} Crystal';

      case ShopItemType.randomSpell:
        if (item.spell != null) {
          mage.learnSpell(item.spell!);
          SpellPoolManager.instance.markSpellDiscovered(item.spell!.id);
          onSpellLearned();
          return 'Learned ${item.spell!.name}';
        }
        return 'Learned a spell';

      case ShopItemType.heal:
        final oldHP = mage.currentHP;
        mage.heal(item.value);
        final healed = mage.currentHP - oldHP;
        return 'Healed $healed HP';

      case ShopItemType.tempBuff:
        onBuffAdded(
          TemporaryBuff(
            name: 'Power Surge',
            value: item.value,
            remainingNodes: 3,
          ),
        );
        return 'Buff applied: +${item.value}% Damage';

      case ShopItemType.consumable:
        if (item.itemDefinition != null) {
          progression.consumables.add(item.itemDefinition!.id);
          return 'Added ${item.itemDefinition!.name} to inventory';
        }
        return 'Item added to inventory';

      case ShopItemType.relic:
        if (item.itemDefinition != null) {
          if (!progression.ownedRelics.contains(item.itemDefinition!.id)) {
            progression.ownedRelics.add(item.itemDefinition!.id);
            return 'Relic obtained: ${item.itemDefinition!.name}';
          }
          return 'Already owned';
        }
        return 'Relic obtained';
    }
  }
}
