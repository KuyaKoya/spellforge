import '../domain/effect.dart';
import '../domain/element.dart';
import '../domain/spell.dart';

/// Pre-defined spell templates for the game.
/// All spells start at ★1 and can be upgraded to ★★★.
class SpellDefinitions {
  SpellDefinitions._();

  // ==================== FIRE SPELLS ====================

  static const fireball = Spell(
    id: 'fireball',
    name: 'Fireball',
    element: Element.fire,
    rarity: SpellRarity.common,
    starLevel: 1,
    baseDescription: 'A classic ball of fire that sears enemies.',
    manaCost: 2,
    effects: [Effect(type: EffectType.damage, value: 8)],
    allowedUpgrades: [UpgradePath.addStatus, UpgradePath.improveTargeting],
  );

  static const inferno = Spell(
    id: 'inferno',
    name: 'Inferno',
    element: Element.fire,
    rarity: SpellRarity.uncommon,
    starLevel: 1,
    baseDescription: 'Engulfs the target in flames, causing burning.',
    manaCost: 3,
    effects: [
      Effect(type: EffectType.damage, value: 5),
      Effect(type: EffectType.burn, value: 3, duration: 2),
    ],
    allowedUpgrades: [UpgradePath.addRepeated, UpgradePath.tradeoff],
  );

  static const blazeStrike = Spell(
    id: 'blazeStrike',
    name: 'Blaze Strike',
    element: Element.fire,
    rarity: SpellRarity.rare,
    starLevel: 1,
    baseDescription: 'A devastating fire attack that weakens defenses.',
    manaCost: 4,
    effects: [
      Effect(type: EffectType.damage, value: 12),
      Effect(type: EffectType.weaken, value: 20, duration: 2),
    ],
    allowedUpgrades: [UpgradePath.addDelayed],
  );

  // ==================== WATER SPELLS ====================

  static const waterBolt = Spell(
    id: 'waterBolt',
    name: 'Water Bolt',
    element: Element.water,
    rarity: SpellRarity.common,
    starLevel: 1,
    baseDescription: 'A pressurized bolt of water.',
    manaCost: 2,
    effects: [Effect(type: EffectType.damage, value: 7)],
    allowedUpgrades: [UpgradePath.addStatus, UpgradePath.improveTargeting],
  );

  static const tidalWave = Spell(
    id: 'tidalWave',
    name: 'Tidal Wave',
    element: Element.water,
    rarity: SpellRarity.uncommon,
    starLevel: 1,
    baseDescription: 'A sweeping wave that slows all enemies.',
    manaCost: 4,
    effects: [
      Effect(type: EffectType.damage, value: 4, targetRule: TargetRule.all),
      Effect(
        type: EffectType.slow,
        value: 1,
        duration: 1,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [UpgradePath.addRepeated],
  );

  static const frostArmor = Spell(
    id: 'frostArmor',
    name: 'Frost Armor',
    element: Element.water,
    rarity: SpellRarity.rare,
    starLevel: 1,
    baseDescription: 'Encases yourself in protective ice.',
    manaCost: 3,
    effects: [
      Effect(
        type: EffectType.armor,
        value: 10,
        duration: 2,
        targetRule: TargetRule.self,
      ),
    ],
    allowedUpgrades: [UpgradePath.tradeoff],
  );

  // ==================== EARTH SPELLS ====================

  static const rockThrow = Spell(
    id: 'rockThrow',
    name: 'Rock Throw',
    element: Element.earth,
    rarity: SpellRarity.common,
    starLevel: 1,
    baseDescription: 'Hurls a large rock at the enemy.',
    manaCost: 2,
    effects: [Effect(type: EffectType.damage, value: 9)],
    allowedUpgrades: [UpgradePath.addStatus, UpgradePath.improveTargeting],
  );

  static const earthquake = Spell(
    id: 'earthquake',
    name: 'Earthquake',
    element: Element.earth,
    rarity: SpellRarity.uncommon,
    starLevel: 1,
    baseDescription: 'Shakes the ground beneath all enemies.',
    manaCost: 4,
    effects: [
      Effect(type: EffectType.damage, value: 6, targetRule: TargetRule.all),
    ],
    allowedUpgrades: [UpgradePath.addDelayed, UpgradePath.addRepeated],
  );

  static const stoneWall = Spell(
    id: 'stoneWall',
    name: 'Stone Wall',
    element: Element.earth,
    rarity: SpellRarity.rare,
    starLevel: 1,
    baseDescription: 'Raises a protective wall of stone.',
    manaCost: 3,
    effects: [
      Effect(
        type: EffectType.armor,
        value: 15,
        duration: 3,
        targetRule: TargetRule.self,
      ),
    ],
    allowedUpgrades: [UpgradePath.tradeoff],
  );

  // ==================== AIR SPELLS ====================

  static const windSlash = Spell(
    id: 'windSlash',
    name: 'Wind Slash',
    element: Element.air,
    rarity: SpellRarity.common,
    starLevel: 1,
    baseDescription: 'A razor-sharp blade of wind.',
    manaCost: 2,
    effects: [Effect(type: EffectType.damage, value: 7)],
    allowedUpgrades: [UpgradePath.addStatus, UpgradePath.improveTargeting],
  );

  static const gust = Spell(
    id: 'gust',
    name: 'Gust',
    element: Element.air,
    rarity: SpellRarity.uncommon,
    starLevel: 1,
    baseDescription: 'A powerful gust that delays enemy actions.',
    manaCost: 3,
    effects: [
      Effect(type: EffectType.damage, value: 3),
      Effect(type: EffectType.delay, value: 1),
    ],
    allowedUpgrades: [UpgradePath.improveTargeting],
  );

  static const hurricane = Spell(
    id: 'hurricane',
    name: 'Hurricane',
    element: Element.air,
    rarity: SpellRarity.rare,
    starLevel: 1,
    baseDescription: 'Summons a devastating hurricane.',
    manaCost: 5,
    effects: [
      Effect(type: EffectType.damage, value: 8, targetRule: TargetRule.all),
      Effect(
        type: EffectType.slow,
        value: 1,
        duration: 2,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [UpgradePath.addRepeated],
  );

  // ==================== SIGNATURE SPELLS ====================

  static const phoenixFlame = Spell(
    id: 'phoenixFlame',
    name: 'Phoenix Flame',
    element: Element.fire,
    rarity: SpellRarity.signature,
    starLevel: 1,
    baseDescription: 'Legendary fire that burns with renewed vigor.',
    manaCost: 5,
    effects: [
      Effect(type: EffectType.damage, value: 15),
      Effect(type: EffectType.burn, value: 5, duration: 3),
      Effect(
        type: EffectType.actionGain,
        value: 1,
        targetRule: TargetRule.self,
      ),
    ],
    allowedUpgrades: [],
  );

  static const tsunami = Spell(
    id: 'typhoon',
    name: 'Typhoon',
    element: Element.water,
    rarity: SpellRarity.signature,
    starLevel: 1,
    baseDescription: 'An overwhelming storm that devastates all.',
    manaCost: 6,
    effects: [
      Effect(type: EffectType.damage, value: 12, targetRule: TargetRule.all),
      Effect(
        type: EffectType.slow,
        value: 2,
        duration: 2,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  /// All common spells.
  static List<Spell> get commonSpells => [
    fireball,
    waterBolt,
    rockThrow,
    windSlash,
  ];

  /// All uncommon spells.
  static List<Spell> get uncommonSpells => [
    inferno,
    tidalWave,
    earthquake,
    gust,
  ];

  /// All rare spells.
  static List<Spell> get rareSpells => [
    blazeStrike,
    frostArmor,
    stoneWall,
    hurricane,
  ];

  /// All signature spells.
  static List<Spell> get signatureSpells => [phoenixFlame, tsunami];

  // ==================== LEGENDARY SPELLS ====================
  // Unlocked by defeating bosses for the first time

  /// Forge Collapse - Legendary Fire spell from Gatekeeper of Pyre
  static const forgeCollapse = Spell(
    id: 'forgeCollapse',
    name: 'Forge Collapse',
    element: Element.fire,
    rarity: SpellRarity.legendary,
    starLevel: 1,
    baseDescription: 'The forge erupts. All is consumed by eternal flame.',
    manaCost: 6,
    effects: [
      Effect(type: EffectType.damage, value: 20),
      Effect(type: EffectType.burn, value: 8, duration: 4),
      Effect(type: EffectType.weaken, value: 30, duration: 3),
    ],
    allowedUpgrades: [UpgradePath.addRepeated],
  );

  /// Tidal Severance - Legendary Water spell from Gatekeeper of Tide
  static const tidalSeverance = Spell(
    id: 'tidalSeverance',
    name: 'Tidal Severance',
    element: Element.water,
    rarity: SpellRarity.legendary,
    starLevel: 1,
    baseDescription: 'The tide cuts through all defense. Barriers shatter.',
    manaCost: 5,
    effects: [
      Effect(type: EffectType.damage, value: 15),
      Effect(type: EffectType.weaken, value: 50, duration: 3), // Major debuff
      Effect(type: EffectType.slow, value: 30, duration: 2),
    ],
    allowedUpgrades: [UpgradePath.addDelayed],
  );

  /// All legendary spells.
  static List<Spell> get legendarySpells => [forgeCollapse, tidalSeverance];

  /// All spells in the game.
  static List<Spell> get allSpells => [
    ...commonSpells,
    ...uncommonSpells,
    ...rareSpells,
    ...signatureSpells,
    ...legendarySpells,
  ];

  /// Get spells by element.
  static List<Spell> getByElement(Element element) {
    return allSpells.where((s) => s.element == element).toList();
  }

  /// Get spells by rarity.
  static List<Spell> getByRarity(SpellRarity rarity) {
    return allSpells.where((s) => s.rarity == rarity).toList();
  }

  /// Get a random selection of spells for learning.
  static List<Spell> getRandomSelection({
    int count = 3,
    SpellRarity? maxRarity,
    List<String>? excludeIds,
  }) {
    var pool = List<Spell>.from(allSpells);

    if (maxRarity != null) {
      final rarityIndex = SpellRarity.values.indexOf(maxRarity);
      pool = pool
          .where((s) => SpellRarity.values.indexOf(s.rarity) <= rarityIndex)
          .toList();
    }

    if (excludeIds != null) {
      pool = pool.where((s) => !excludeIds.contains(s.id)).toList();
    }

    pool.shuffle();
    return pool.take(count).toList();
  }
}
