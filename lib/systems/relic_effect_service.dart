import '../data/item_definitions.dart';
import '../domain/element.dart';

/// Aggregated stat modifiers from equipped relics.
class RelicStats {
  final double maxHpPercent;
  final int maxHpFlat;
  final double damagePercent;
  final int defenseFlat;
  final double speedPercent;
  final double manaPercent;
  final int manaFlat;
  final double manaCostReduction;
  final double burnPotency;
  final double slowPotency;
  final double weakenPotency;

  // Special passive flags
  final int burnBonusDamage;
  final int healOnWaterCast;
  final int startingArmor;
  final bool firstSpellFree;

  const RelicStats({
    this.maxHpPercent = 0,
    this.maxHpFlat = 0,
    this.damagePercent = 0,
    this.defenseFlat = 0,
    this.speedPercent = 0,
    this.manaPercent = 0,
    this.manaFlat = 0,
    this.manaCostReduction = 0,
    this.burnPotency = 0,
    this.slowPotency = 0,
    this.weakenPotency = 0,
    this.burnBonusDamage = 0,
    this.healOnWaterCast = 0,
    this.startingArmor = 0,
    this.firstSpellFree = false,
  });

  /// Creates stats with all modifiers set to zero.
  static const RelicStats empty = RelicStats();

  /// Combines two RelicStats by adding their values.
  RelicStats operator +(RelicStats other) {
    return RelicStats(
      maxHpPercent: maxHpPercent + other.maxHpPercent,
      maxHpFlat: maxHpFlat + other.maxHpFlat,
      damagePercent: damagePercent + other.damagePercent,
      defenseFlat: defenseFlat + other.defenseFlat,
      speedPercent: speedPercent + other.speedPercent,
      manaPercent: manaPercent + other.manaPercent,
      manaFlat: manaFlat + other.manaFlat,
      manaCostReduction: manaCostReduction + other.manaCostReduction,
      burnPotency: burnPotency + other.burnPotency,
      slowPotency: slowPotency + other.slowPotency,
      weakenPotency: weakenPotency + other.weakenPotency,
      burnBonusDamage: burnBonusDamage + other.burnBonusDamage,
      healOnWaterCast: healOnWaterCast + other.healOnWaterCast,
      startingArmor: startingArmor + other.startingArmor,
      firstSpellFree: firstSpellFree || other.firstSpellFree,
    );
  }
}

/// 4-piece set bonus definitions.
class SetBonus {
  final Element element;
  final String name;
  final String description;

  const SetBonus({
    required this.element,
    required this.name,
    required this.description,
  });
}

/// Service for calculating relic effects on player stats.
class RelicEffectService {
  /// All 4-piece set bonuses.
  static const List<SetBonus> setBonuses = [
    SetBonus(
      element: Element.fire,
      name: 'Ignition',
      description:
          'Burn damage +50%. After applying Burn, next attack deals +20% bonus damage.',
    ),
    SetBonus(
      element: Element.water,
      name: 'Tidal Grace',
      description: 'Applying Slow heals 5% Max HP. Slow duration +1 turn.',
    ),
    SetBonus(
      element: Element.earth,
      name: 'Fortress',
      description:
          '+10 Armor at combat start. While armored, take -15% damage.',
    ),
    SetBonus(
      element: Element.air,
      name: 'Windrunner',
      description: '+10% Speed. Every 3rd turn, gain +1 bonus action.',
    ),
  ];

  /// Calculate total stat modifiers from equipped relics.
  static RelicStats calculateEquippedStats(List<String> equippedRelicIds) {
    var total = RelicStats.empty;

    for (final id in equippedRelicIds) {
      if (id.isEmpty) continue;
      final item = ItemRegistry.getItem(id);
      if (item is RelicItem) {
        total = total + _statsFromRelic(item);
      }
    }

    return total;
  }

  /// Convert a RelicItem's stats map to RelicStats.
  static RelicStats _statsFromRelic(RelicItem relic) {
    final s = relic.stats;
    return RelicStats(
      maxHpPercent: s['maxHpPercent']?.toDouble() ?? 0,
      maxHpFlat: s['maxHpFlat']?.toInt() ?? 0,
      damagePercent: s['damagePercent']?.toDouble() ?? 0,
      defenseFlat: s['defenseFlat']?.toInt() ?? 0,
      speedPercent: s['speedPercent']?.toDouble() ?? 0,
      manaPercent: s['manaPercent']?.toDouble() ?? 0,
      manaFlat: s['manaFlat']?.toInt() ?? 0,
      manaCostReduction: s['manaCostReduction']?.toDouble() ?? 0,
      burnPotency: s['burnPotency']?.toDouble() ?? 0,
      slowPotency: s['slowPotency']?.toDouble() ?? 0,
      weakenPotency: s['weakenPotency']?.toDouble() ?? 0,
      burnBonusDamage: s['burnBonusDamage']?.toInt() ?? 0,
      healOnWaterCast: s['healOnWaterCast']?.toInt() ?? 0,
      startingArmor: s['startingArmor']?.toInt() ?? 0,
      firstSpellFree: s['firstSpellFree'] == 1 || s['firstSpellFree'] == true,
    );
  }

  /// Check which set bonuses are active (4/4 of same element).
  static Set<Element> getActiveSetBonuses(List<String> equippedRelicIds) {
    final progress = getSetProgress(equippedRelicIds);
    final active = <Element>{};

    for (final element in Element.values) {
      if ((progress[element] ?? 0) >= 4) {
        active.add(element);
      }
    }

    return active;
  }

  /// Get set progress (e.g., {fire: 2, water: 2}).
  static Map<Element, int> getSetProgress(List<String> equippedRelicIds) {
    final counts = <Element, int>{};

    for (final id in equippedRelicIds) {
      if (id.isEmpty) continue;
      final item = ItemRegistry.getItem(id);
      if (item is RelicItem) {
        counts[item.element] = (counts[item.element] ?? 0) + 1;
      }
    }

    return counts;
  }

  /// Get the set bonus for an element.
  static SetBonus? getSetBonus(Element element) {
    try {
      return setBonuses.firstWhere((b) => b.element == element);
    } catch (_) {
      return null;
    }
  }

  /// Get relics by element.
  static List<RelicItem> getRelicsByElement(Element element) {
    return ItemRegistry.relics.where((r) => r.element == element).toList();
  }

  /// Get all relics of a specific rarity.
  static List<RelicItem> getRelicsByRarity(int rarity) {
    return ItemRegistry.relics.where((r) => r.rarity == rarity).toList();
  }

  /// Get a random selection of relics, optionally excluding already owned.
  static List<RelicItem> getRandomRelics({
    required int count,
    List<String> excludeIds = const [],
    int? seed,
  }) {
    final available = ItemRegistry.relics
        .where((r) => !excludeIds.contains(r.id))
        .toList();

    if (available.length <= count) return available;

    // Shuffle and take
    final shuffled = List<RelicItem>.from(available)..shuffle();
    return shuffled.take(count).toList();
  }
}
