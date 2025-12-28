import '../domain/element.dart';
import '../relics/relic.dart';

/// Act 1 specific relics - exactly 8 relics in 4 elemental sets.
/// Each relic has lore fragment, elemental identity, and set-completion lore.
class Act1Relics {
  Act1Relics._();

  // ==================== FIRE SET ====================

  static Relic flameRobe() => Relic(
    id: 'act1_flame_robe',
    name: 'Flame Robe',
    description: 'Start combat with Burn immunity for 2 turns.',
    rarity: RelicRarity.uncommon,
    trigger: RelicTrigger.onCombatStart,
    synergyTags: ['burn', 'defense', 'fire_set'],
    synergyElements: [Element.fire],
    effectParams: {
      'burnImmunityDuration': 2,
      'lore':
          'Worn thin by heat. The wearer did not freeze. That is all that can be said.',
      'setId': 'fire',
      'setPair': 'act1_charcoal_wand',
    },
  );

  static Relic charcoalWand() => Relic(
    id: 'act1_charcoal_wand',
    name: 'Charcoal Wand',
    description: 'Fire spells deal +15% damage.',
    rarity: RelicRarity.uncommon,
    trigger: RelicTrigger.passive,
    synergyTags: ['damage', 'fire', 'fire_set'],
    synergyElements: [Element.fire],
    effectParams: {
      'fireDamageBonus': 0.15,
      'lore': 'It crumbles. Slowly. The magic holds it together. For now.',
      'setId': 'fire',
      'setPair': 'act1_flame_robe',
    },
  );

  // ==================== WATER SET ====================

  static Relic waterShield() => Relic(
    id: 'act1_water_shield',
    name: 'Water Shield',
    description: 'Gain 3 armor when hit by Fire damage.',
    rarity: RelicRarity.uncommon,
    trigger: RelicTrigger.onDamageTaken,
    synergyTags: ['defense', 'armor', 'water_set'],
    synergyElements: [Element.water],
    effectParams: {
      'armorOnFireDamage': 3,
      'lore': 'The surface ripples but does not break. Not easily.',
      'setId': 'water',
      'setPair': 'act1_frost_sword',
    },
  );

  static Relic frostSword() => Relic(
    id: 'act1_frost_sword',
    name: 'Frost Sword',
    description: 'Water spells have +20% chance to apply Slow.',
    rarity: RelicRarity.uncommon,
    trigger: RelicTrigger.onSpellCast,
    synergyTags: ['control', 'slow', 'water_set'],
    synergyElements: [Element.water],
    effectParams: {
      'slowChanceBonus': 0.2,
      'lore':
          'Cold to the touch. Colder still to the struck. The blade remembers winter.',
      'setId': 'water',
      'setPair': 'act1_water_shield',
    },
  );

  // ==================== EARTH SET ====================

  static Relic hardenedScales() => Relic(
    id: 'act1_hardened_scales',
    name: 'Hardened Scales',
    description: 'Start combat with 5 armor.',
    rarity: RelicRarity.uncommon,
    trigger: RelicTrigger.onCombatStart,
    synergyTags: ['defense', 'armor', 'earth_set'],
    synergyElements: [Element.earth],
    effectParams: {
      'startingArmor': 5,
      'lore': 'Something shed these. Something large. Something patient.',
      'setId': 'earth',
      'setPair': 'act1_undying_helmet',
    },
  );

  static Relic undyingHelmet() => Relic(
    id: 'act1_undying_helmet',
    name: 'Undying Helmet',
    description: 'Once per combat, survive a lethal hit with 1 HP.',
    rarity: RelicRarity.rare,
    trigger: RelicTrigger.onLowHp,
    synergyTags: ['survival', 'clutch', 'earth_set'],
    synergyElements: [Element.earth],
    effectParams: {
      'surviveLethalOnce': true,
      'lore':
          'The previous owner died. The helmet did not. Consider what that means.',
      'setId': 'earth',
      'setPair': 'act1_hardened_scales',
    },
  );

  // ==================== AIR SET ====================

  static Relic zephyrBoots() => Relic(
    id: 'act1_zephyr_boots',
    name: 'Zephyr Boots',
    description: 'Start combat with +1 action.',
    rarity: RelicRarity.rare,
    trigger: RelicTrigger.onCombatStart,
    synergyTags: ['speed', 'actions', 'air_set'],
    synergyElements: [Element.air],
    effectParams: {
      'startingActions': 1,
      'lore': 'Light. Almost weightless. The runner is gone. The boots remain.',
      'setId': 'air',
      'setPair': 'act1_wings_of_storm',
    },
  );

  static Relic wingsOfStorm() => Relic(
    id: 'act1_wings_of_storm',
    name: 'Wings of the Storm',
    description: 'Air spells have 15% chance to not consume an action.',
    rarity: RelicRarity.rare,
    trigger: RelicTrigger.onSpellCast,
    synergyTags: ['speed', 'actions', 'air_set'],
    synergyElements: [Element.air],
    effectParams: {
      'freeActionChance': 0.15,
      'lore':
          'They do not grant flight. They grant speed. The distinction matters.',
      'setId': 'air',
      'setPair': 'act1_zephyr_boots',
    },
  );

  // ==================== SET COMPLETION LORE ====================

  static const Map<String, String> setCompletionLore = {
    'fire':
        'The flame consumes. But controlled, it illuminates. You have learned this. Again.',
    'water':
        'Water flows around obstacles. It does not fight them. It outlasts them.',
    'earth': 'Stone endures. That is both its strength and its prison.',
    'air': 'The wind does not ask permission. Neither should you.',
  };

  // ==================== GETTERS ====================

  /// All Act 1 relics.
  static List<Relic> get allRelics => [
    flameRobe(),
    charcoalWand(),
    waterShield(),
    frostSword(),
    hardenedScales(),
    undyingHelmet(),
    zephyrBoots(),
    wingsOfStorm(),
  ];

  /// Gets relics by element.
  static List<Relic> getByElement(Element element) {
    return allRelics.where((r) => r.synergyElements.contains(element)).toList();
  }

  /// Gets the paired relic for a given relic (for set completion check).
  static Relic? getPairedRelic(Relic relic) {
    final pairId = relic.effectParams['setPair'] as String?;
    if (pairId == null) return null;

    try {
      return allRelics.firstWhere((r) => r.id == pairId);
    } catch (_) {
      return null;
    }
  }

  /// Checks if a set is complete.
  static bool isSetComplete(List<Relic> ownedRelics, String setId) {
    final setRelics = allRelics
        .where((r) => r.effectParams['setId'] == setId)
        .toList();

    return setRelics.every((sr) => ownedRelics.any((or) => or.id == sr.id));
  }

  /// Gets the lore for completing a set.
  static String? getSetCompletionLore(String setId) {
    return setCompletionLore[setId];
  }

  /// Gets the lore text for a relic.
  static String getRelicLore(Relic relic) {
    return relic.effectParams['lore'] as String? ??
        'An artifact of unknown origin.';
  }

  /// Gets random Act 1 relics for a run (max 2 per run per spec).
  static List<Relic> getRunRelics(int seed, {int maxCount = 2}) {
    final shuffled = List<Relic>.from(allRelics);
    shuffled.shuffle();
    return shuffled.take(maxCount).toList();
  }
}
