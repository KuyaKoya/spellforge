import '../data/item_definitions.dart';
import '../systems/progression_system.dart';
import '../domain/element.dart';

/// Manages inventory logic, item usage, and relic set bonuses.
class InventorySystem {
  final ProgressionSystem progression;

  InventorySystem(this.progression);

  /// Uses a consumable item.
  /// Returns the effect to be applied by the caller (Game/Battle state).
  ConsumableEffect? useConsumable(String itemId) {
    if (!progression.consumables.contains(itemId)) return null;

    final item = ItemRegistry.getItem(itemId);
    if (item is! ConsumableItem) return null;

    progression.consumables.remove(itemId);
    return item.effect;
  }

  /// Equips a relic to a specific slot.
  /// Returns true if successful.
  bool equipRelic(int slot, String relicId) {
    if (slot < 0 || slot >= 4) return false;
    if (!progression.ownedRelics.contains(relicId)) return false;

    // Check if equipped elsewhere
    final existingSlot = progression.equippedRelics.indexOf(relicId);
    if (existingSlot != -1) {
      // Allow swapping or just moving? For now, remove from old slot
      progression.equippedRelics[existingSlot] = '';
    }

    // Ensure size
    while (progression.equippedRelics.length <= slot) {
      progression.equippedRelics.add('');
    }

    progression.equippedRelics[slot] = relicId;
    return true;
  }

  /// Unequips a relic from a slot.
  void unequipRelic(int slot) {
    if (slot >= 0 && slot < progression.equippedRelics.length) {
      progression.equippedRelics[slot] = '';
    }
  }

  /// Calculates active set bonuses based on equipped relics.
  /// Returns a Map of Element -> count (or bool if full set).
  /// Required: 4 relics of same element.
  Set<Element> getActiveSetBonuses() {
    final counts = <Element, int>{};

    for (final id in progression.equippedRelics) {
      if (id.isEmpty) continue;
      final item = ItemRegistry.getItem(id);
      if (item is RelicItem) {
        counts[item.element] = (counts[item.element] ?? 0) + 1;
      }
    }

    final activeSets = <Element>{};
    counts.forEach((element, count) {
      if (count >= 4) {
        activeSets.add(element);
      }
    });

    return activeSets;
  }

  /// Gets the description of a set bonus for an element.
  static String getSetBonusDescription(Element element) {
    switch (element) {
      case Element.fire:
        return 'Immunity to Burn. +10% Fire Damage.';
      case Element.water:
        return 'Restore 5% Max Mana per turn.';
      case Element.earth:
        return '+15 Max HP. +5 Armor at start of battle.';
      case Element.air:
        return '+1 Action Point every 3 turns.';
    }
  }
}
