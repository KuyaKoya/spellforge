import '../domain/effect.dart';
import '../domain/element.dart';
import '../domain/spell.dart';

/// Fusion spell definitions created by combining two spells.
/// All fusion spells have rarity: SpellRarity.fusion
class FusionSpellDefinitions {
  FusionSpellDefinitions._();

  // ==================== FIRE + FIRE FUSIONS ====================

  static const solarFireball = Spell(
    id: 'solarFireball',
    name: 'Solar Fireball',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A blazing orb of concentrated solar energy.',
    manaCost: 4,
    effects: [Effect(type: EffectType.damage, value: 18)],
    allowedUpgrades: [],
  );

  static const hellfireOrb = Spell(
    id: 'hellfireOrb',
    name: 'Hellfire Orb',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'An orb of hellish flames that scorches all.',
    manaCost: 5,
    effects: [
      Effect(type: EffectType.damage, value: 14),
      Effect(type: EffectType.burn, value: 4, duration: 3),
    ],
    allowedUpgrades: [],
  );

  static const flareImpact = Spell(
    id: 'flareImpact',
    name: 'Flare Impact',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A devastating strike that explodes on impact.',
    manaCost: 5,
    effects: [
      Effect(type: EffectType.damage, value: 16),
      Effect(type: EffectType.weaken, value: 15, duration: 2),
    ],
    allowedUpgrades: [],
  );

  static const worldPyre = Spell(
    id: 'worldPyre',
    name: 'World Pyre',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A cataclysmic inferno that engulfs everything.',
    manaCost: 7,
    effects: [
      Effect(type: EffectType.damage, value: 12, targetRule: TargetRule.all),
      Effect(
        type: EffectType.burn,
        value: 5,
        duration: 3,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  static const cinderExecution = Spell(
    id: 'cinderExecution',
    name: 'Cinder Execution',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A merciless strike that reduces targets to cinders.',
    manaCost: 6,
    effects: [
      Effect(type: EffectType.damage, value: 18),
      Effect(type: EffectType.burn, value: 4, duration: 2),
      Effect(type: EffectType.weaken, value: 25, duration: 2),
    ],
    allowedUpgrades: [],
  );

  static const blazingVerdict = Spell(
    id: 'blazingVerdict',
    name: 'Blazing Verdict',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A judgment of pure flame that shatters defenses.',
    manaCost: 7,
    effects: [
      Effect(type: EffectType.damage, value: 22),
      Effect(type: EffectType.weaken, value: 30, duration: 3),
    ],
    allowedUpgrades: [],
  );

  // ==================== FIRE + WATER FUSIONS ====================

  static const steamburstFireball = Spell(
    id: 'steamburstFireball',
    name: 'Steamburst Fireball',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription:
        'A volatile mix of fire and water that explodes into steam.',
    manaCost: 4,
    effects: [
      Effect(type: EffectType.damage, value: 12),
      Effect(type: EffectType.slow, value: 1, duration: 1),
    ],
    allowedUpgrades: [],
  );

  static const thermalTsunami = Spell(
    id: 'thermalTsunami',
    name: 'Thermal Tsunami',
    element: Element.water,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A scalding wave that burns and overwhelms.',
    manaCost: 6,
    effects: [
      Effect(type: EffectType.damage, value: 10, targetRule: TargetRule.all),
      Effect(
        type: EffectType.burn,
        value: 2,
        duration: 2,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  static const superheatedSteam = Spell(
    id: 'superheatedSteam',
    name: 'Superheated Steam',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'Intense steam that scalds and obscures.',
    manaCost: 5,
    effects: [
      Effect(type: EffectType.damage, value: 8),
      Effect(type: EffectType.burn, value: 3, duration: 3),
      Effect(type: EffectType.slow, value: 1, duration: 2),
    ],
    allowedUpgrades: [],
  );

  static const evaporationSurge = Spell(
    id: 'evaporationSurge',
    name: 'Evaporation Surge',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription:
        'A wave of heat that vaporizes water into a scalding mist.',
    manaCost: 6,
    effects: [
      Effect(type: EffectType.damage, value: 9, targetRule: TargetRule.all),
      Effect(
        type: EffectType.burn,
        value: 4,
        duration: 2,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  static const scaldingSlash = Spell(
    id: 'scaldingSlash',
    name: 'Scalding Slash',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A blade of boiling water that cuts and burns.',
    manaCost: 5,
    effects: [
      Effect(type: EffectType.damage, value: 14),
      Effect(type: EffectType.burn, value: 2, duration: 2),
    ],
    allowedUpgrades: [],
  );

  static const steamCleave = Spell(
    id: 'steamCleave',
    name: 'Steam Cleave',
    element: Element.water,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A pressurized steam arc that cuts through armor.',
    manaCost: 6,
    effects: [
      Effect(type: EffectType.damage, value: 10, targetRule: TargetRule.all),
      Effect(
        type: EffectType.weaken,
        value: 15,
        duration: 2,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  // ==================== FIRE + WATER (ICE) FUSIONS ====================

  static const flashMelt = Spell(
    id: 'flashMelt',
    name: 'Flash Melt',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'Rapid thermal shock that shatters frozen defenses.',
    manaCost: 5,
    effects: [
      Effect(type: EffectType.damage, value: 12),
      Effect(type: EffectType.weaken, value: 20, duration: 2),
    ],
    allowedUpgrades: [],
  );

  static const thermalShock = Spell(
    id: 'thermalShock',
    name: 'Thermal Shock',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'Extreme temperature change that fractures enemies.',
    manaCost: 5,
    effects: [
      Effect(type: EffectType.damage, value: 10),
      Effect(type: EffectType.burn, value: 3, duration: 2),
      Effect(type: EffectType.slow, value: 1, duration: 1),
    ],
    allowedUpgrades: [],
  );

  static const heatFracture = Spell(
    id: 'heatFracture',
    name: 'Heat Fracture',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A fiery strike that cracks frozen armor.',
    manaCost: 6,
    effects: [
      Effect(type: EffectType.damage, value: 16),
      Effect(type: EffectType.weaken, value: 25, duration: 2),
    ],
    allowedUpgrades: [],
  );

  static const thermalParadox = Spell(
    id: 'thermalParadox',
    name: 'Thermal Paradox',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'Fire and ice collide in impossible harmony.',
    manaCost: 7,
    effects: [
      Effect(type: EffectType.damage, value: 18),
      Effect(
        type: EffectType.armor,
        value: 8,
        duration: 2,
        targetRule: TargetRule.self,
      ),
    ],
    allowedUpgrades: [],
  );

  // ==================== FIRE + EARTH FUSIONS ====================

  static const magmaShot = Spell(
    id: 'magmaShot',
    name: 'Magma Shot',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A molten projectile that burns on impact.',
    manaCost: 4,
    effects: [
      Effect(type: EffectType.damage, value: 14),
      Effect(type: EffectType.burn, value: 2, duration: 2),
    ],
    allowedUpgrades: [],
  );

  static const volcanicRupture = Spell(
    id: 'volcanicRupture',
    name: 'Volcanic Rupture',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'The earth erupts with volcanic fury.',
    manaCost: 6,
    effects: [
      Effect(type: EffectType.damage, value: 12, targetRule: TargetRule.all),
      Effect(
        type: EffectType.burn,
        value: 3,
        duration: 2,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  static const moltenBastion = Spell(
    id: 'moltenBastion',
    name: 'Molten Bastion',
    element: Element.earth,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A wall of molten rock that protects and burns.',
    manaCost: 5,
    effects: [
      Effect(
        type: EffectType.armor,
        value: 12,
        duration: 3,
        targetRule: TargetRule.self,
      ),
      Effect(type: EffectType.damage, value: 5),
    ],
    allowedUpgrades: [],
  );

  static const lavaBarrage = Spell(
    id: 'lavaBarrage',
    name: 'Lava Barrage',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A relentless storm of molten projectiles.',
    manaCost: 6,
    effects: [
      Effect(type: EffectType.damage, value: 10),
      Effect(type: EffectType.burn, value: 4, duration: 3),
    ],
    allowedUpgrades: [],
  );

  static const magmaCataclysm = Spell(
    id: 'magmaCataclysm',
    name: 'Magma Cataclysm',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A catastrophic eruption from below.',
    manaCost: 7,
    effects: [
      Effect(type: EffectType.damage, value: 14, targetRule: TargetRule.all),
      Effect(
        type: EffectType.burn,
        value: 5,
        duration: 3,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  static const obsidianBulwark = Spell(
    id: 'obsidianBulwark',
    name: 'Obsidian Bulwark',
    element: Element.earth,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'Volcanic glass forms an impenetrable shield.',
    manaCost: 5,
    effects: [
      Effect(
        type: EffectType.armor,
        value: 18,
        duration: 3,
        targetRule: TargetRule.self,
      ),
    ],
    allowedUpgrades: [],
  );

  // ==================== FIRE + AIR FUSIONS ====================

  static const explosiveEmber = Spell(
    id: 'explosiveEmber',
    name: 'Explosive Ember',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'Wind-carried embers that detonate on contact.',
    manaCost: 4,
    effects: [
      Effect(type: EffectType.damage, value: 12),
      Effect(type: EffectType.burn, value: 2, duration: 2),
    ],
    allowedUpgrades: [],
  );

  static const scatterFlame = Spell(
    id: 'scatterFlame',
    name: 'Scatter Flame',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'Flames scattered by wind to hit all targets.',
    manaCost: 5,
    effects: [
      Effect(type: EffectType.damage, value: 6, targetRule: TargetRule.all),
      Effect(
        type: EffectType.burn,
        value: 2,
        duration: 2,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  static const firestormCore = Spell(
    id: 'firestormCore',
    name: 'Firestorm Core',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'The heart of a raging firestorm.',
    manaCost: 7,
    effects: [
      Effect(type: EffectType.damage, value: 12, targetRule: TargetRule.all),
      Effect(
        type: EffectType.burn,
        value: 4,
        duration: 3,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  static const scorcningGale = Spell(
    id: 'scorchingGale',
    name: 'Scorching Gale',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A searing wind that carries flames.',
    manaCost: 5,
    effects: [
      Effect(type: EffectType.damage, value: 8),
      Effect(type: EffectType.burn, value: 4, duration: 2),
      Effect(type: EffectType.delay, value: 1),
    ],
    allowedUpgrades: [],
  );

  static const flameUplift = Spell(
    id: 'flameUplift',
    name: 'Flame Uplift',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'Rising flames carried by warm air currents.',
    manaCost: 4,
    effects: [
      Effect(type: EffectType.damage, value: 8),
      Effect(type: EffectType.burn, value: 3, duration: 2),
    ],
    allowedUpgrades: [],
  );

  static const apocalypticFirestorm = Spell(
    id: 'apocalypticFirestorm',
    name: 'Apocalyptic Firestorm',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A world-ending storm of fire and wind.',
    manaCost: 8,
    effects: [
      Effect(type: EffectType.damage, value: 15, targetRule: TargetRule.all),
      Effect(
        type: EffectType.burn,
        value: 5,
        duration: 3,
        targetRule: TargetRule.all,
      ),
      Effect(
        type: EffectType.slow,
        value: 1,
        duration: 2,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  static const infernoCyclone = Spell(
    id: 'infernoCyclone',
    name: 'Inferno Cyclone',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A spiraling vortex of flames.',
    manaCost: 7,
    effects: [
      Effect(type: EffectType.damage, value: 14, targetRule: TargetRule.all),
      Effect(
        type: EffectType.burn,
        value: 4,
        duration: 2,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  static const hellwindSpiral = Spell(
    id: 'hellwindSpiral',
    name: 'Hellwind Spiral',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'Demonic winds carry hellfire in a deadly spiral.',
    manaCost: 8,
    effects: [
      Effect(type: EffectType.damage, value: 16, targetRule: TargetRule.all),
      Effect(
        type: EffectType.burn,
        value: 5,
        duration: 3,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  // ==================== WATER FUSIONS ====================

  static const aquaLance = Spell(
    id: 'aquaLance',
    name: 'Aqua Lance',
    element: Element.water,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A concentrated spear of pressurized water.',
    manaCost: 4,
    effects: [Effect(type: EffectType.damage, value: 16)],
    allowedUpgrades: [],
  );

  static const surgingTorrent = Spell(
    id: 'surgingTorrent',
    name: 'Surging Torrent',
    element: Element.water,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'An overwhelming rush of water.',
    manaCost: 5,
    effects: [
      Effect(type: EffectType.damage, value: 10),
      Effect(type: EffectType.slow, value: 2, duration: 2),
    ],
    allowedUpgrades: [],
  );

  static const glacialShot = Spell(
    id: 'glacialShot',
    name: 'Glacial Shot',
    element: Element.water,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A frozen bolt that chills to the bone.',
    manaCost: 4,
    effects: [
      Effect(type: EffectType.damage, value: 10),
      Effect(type: EffectType.slow, value: 2, duration: 2),
    ],
    allowedUpgrades: [],
  );

  static const oceanicJudgment = Spell(
    id: 'oceanicJudgment',
    name: 'Oceanic Judgment',
    element: Element.water,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'The ocean passes judgment upon all.',
    manaCost: 8,
    effects: [
      Effect(type: EffectType.damage, value: 12, targetRule: TargetRule.all),
      Effect(
        type: EffectType.slow,
        value: 2,
        duration: 3,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  static const frozenSurge = Spell(
    id: 'frozenSurge',
    name: 'Frozen Surge',
    element: Element.water,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A wave that freezes as it crashes.',
    manaCost: 6,
    effects: [
      Effect(type: EffectType.damage, value: 8, targetRule: TargetRule.all),
      Effect(
        type: EffectType.slow,
        value: 2,
        duration: 2,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  static const absoluteZeroAegis = Spell(
    id: 'absoluteZeroAegis',
    name: 'Absolute Zero Aegis',
    element: Element.water,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'Perfect ice armor at absolute zero.',
    manaCost: 6,
    effects: [
      Effect(
        type: EffectType.armor,
        value: 20,
        duration: 3,
        targetRule: TargetRule.self,
      ),
    ],
    allowedUpgrades: [],
  );

  static const maelstrom = Spell(
    id: 'maelstrom',
    name: 'Maelstrom',
    element: Element.water,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A devastating whirlpool of destruction.',
    manaCost: 8,
    effects: [
      Effect(type: EffectType.damage, value: 14, targetRule: TargetRule.all),
      Effect(
        type: EffectType.slow,
        value: 2,
        duration: 3,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  static const worldVortex = Spell(
    id: 'worldVortex',
    name: 'World Vortex',
    element: Element.water,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A vortex that threatens to swallow the world.',
    manaCost: 9,
    effects: [
      Effect(type: EffectType.damage, value: 16, targetRule: TargetRule.all),
      Effect(
        type: EffectType.slow,
        value: 3,
        duration: 3,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  // ==================== EARTH FUSIONS ====================

  static const meteorSlam = Spell(
    id: 'meteorSlam',
    name: 'Meteor Slam',
    element: Element.earth,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A devastating meteor impact.',
    manaCost: 5,
    effects: [Effect(type: EffectType.damage, value: 20)],
    allowedUpgrades: [],
  );

  static const avalancheBreak = Spell(
    id: 'avalancheBreak',
    name: 'Avalanche Break',
    element: Element.earth,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'An unstoppable avalanche of stone.',
    manaCost: 6,
    effects: [
      Effect(type: EffectType.damage, value: 12, targetRule: TargetRule.all),
    ],
    allowedUpgrades: [],
  );

  static const worldbreaker = Spell(
    id: 'worldbreaker',
    name: 'Worldbreaker',
    element: Element.earth,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'An earthquake that threatens to break the world.',
    manaCost: 8,
    effects: [
      Effect(type: EffectType.damage, value: 15, targetRule: TargetRule.all),
    ],
    allowedUpgrades: [],
  );

  static const adamantFortress = Spell(
    id: 'adamantFortress',
    name: 'Adamant Fortress',
    element: Element.earth,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'An impenetrable fortress of solid stone.',
    manaCost: 6,
    effects: [
      Effect(
        type: EffectType.armor,
        value: 25,
        duration: 4,
        targetRule: TargetRule.self,
      ),
    ],
    allowedUpgrades: [],
  );

  static const continentalAegis = Spell(
    id: 'continentalAegis',
    name: 'Continental Aegis',
    element: Element.earth,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'The weight of a continent shields you.',
    manaCost: 7,
    effects: [
      Effect(
        type: EffectType.armor,
        value: 22,
        duration: 4,
        targetRule: TargetRule.self,
      ),
    ],
    allowedUpgrades: [],
  );

  // ==================== AIR FUSIONS ====================

  static const skyRend = Spell(
    id: 'skyRend',
    name: 'Sky Rend',
    element: Element.air,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A blade of wind that tears the sky asunder.',
    manaCost: 4,
    effects: [Effect(type: EffectType.damage, value: 16)],
    allowedUpgrades: [],
  );

  static const crosswindCut = Spell(
    id: 'crosswindCut',
    name: 'Crosswind Cut',
    element: Element.air,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'Crossing winds that slice from all angles.',
    manaCost: 4,
    effects: [
      Effect(type: EffectType.damage, value: 10),
      Effect(type: EffectType.delay, value: 1),
    ],
    allowedUpgrades: [],
  );

  static const tempestPulse = Spell(
    id: 'tempestPulse',
    name: 'Tempest Pulse',
    element: Element.air,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A powerful pulse of tempest energy.',
    manaCost: 5,
    effects: [
      Effect(type: EffectType.damage, value: 8),
      Effect(type: EffectType.delay, value: 2),
    ],
    allowedUpgrades: [],
  );

  static const endlessTempest = Spell(
    id: 'endlessTempest',
    name: 'Endless Tempest',
    element: Element.air,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A storm that never ends.',
    manaCost: 8,
    effects: [
      Effect(type: EffectType.damage, value: 14, targetRule: TargetRule.all),
      Effect(
        type: EffectType.slow,
        value: 3,
        duration: 3,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  static const worldstorm = Spell(
    id: 'worldstorm',
    name: 'Worldstorm',
    element: Element.air,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A storm that engulfs the entire world.',
    manaCost: 9,
    effects: [
      Effect(type: EffectType.damage, value: 18, targetRule: TargetRule.all),
      Effect(
        type: EffectType.slow,
        value: 2,
        duration: 3,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  static const oceanKing = Spell(
    id: 'oceanKing',
    name: 'Ocean King',
    element: Element.water,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'Command the ocean itself.',
    manaCost: 9,
    effects: [
      Effect(type: EffectType.damage, value: 20, targetRule: TargetRule.all),
      Effect(
        type: EffectType.slow,
        value: 3,
        duration: 3,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  // ==================== LEGENDARY FUSIONS ====================

  static const eternalSun = Spell(
    id: 'eternalSun',
    name: 'Eternal Sun',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'The power of an eternal sun.',
    manaCost: 8,
    effects: [
      Effect(type: EffectType.damage, value: 22),
      Effect(type: EffectType.burn, value: 6, duration: 4),
      Effect(
        type: EffectType.actionGain,
        value: 1,
        targetRule: TargetRule.self,
      ),
    ],
    allowedUpgrades: [],
  );

  static const undyingInferno = Spell(
    id: 'undyingInferno',
    name: 'Undying Inferno',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'An inferno that cannot be extinguished.',
    manaCost: 8,
    effects: [
      Effect(type: EffectType.damage, value: 12, targetRule: TargetRule.all),
      Effect(
        type: EffectType.burn,
        value: 7,
        duration: 4,
        targetRule: TargetRule.all,
      ),
    ],
    allowedUpgrades: [],
  );

  static const eternalRebirth = Spell(
    id: 'eternalRebirth',
    name: 'Eternal Rebirth',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'The phoenix rises, eternal and undying.',
    manaCost: 10,
    effects: [
      Effect(type: EffectType.damage, value: 25),
      Effect(type: EffectType.burn, value: 8, duration: 4),
      Effect(
        type: EffectType.actionGain,
        value: 2,
        targetRule: TargetRule.self,
      ),
    ],
    allowedUpgrades: [],
  );

  static const forgedAscension = Spell(
    id: 'forgedAscension',
    name: 'Forged Ascension',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'Ascend through the flames of the forge.',
    manaCost: 9,
    effects: [
      Effect(type: EffectType.damage, value: 28),
      Effect(type: EffectType.burn, value: 10, duration: 4),
    ],
    allowedUpgrades: [],
  );

  static const worldAnvil = Spell(
    id: 'worldAnvil',
    name: 'World Anvil',
    element: Element.fire,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'The anvil upon which worlds are forged.',
    manaCost: 10,
    effects: [
      Effect(type: EffectType.damage, value: 35),
      Effect(type: EffectType.burn, value: 12, duration: 5),
      Effect(type: EffectType.weaken, value: 40, duration: 4),
    ],
    allowedUpgrades: [],
  );

  static const oceansEnd = Spell(
    id: 'oceansEnd',
    name: "Ocean's End",
    element: Element.water,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'Where the ocean ends, all hope fades.',
    manaCost: 10,
    effects: [
      Effect(type: EffectType.damage, value: 30),
      Effect(type: EffectType.weaken, value: 60, duration: 4),
      Effect(type: EffectType.slow, value: 40, duration: 3),
    ],
    allowedUpgrades: [],
  );

  static const cataclysmDivide = Spell(
    id: 'cataclysmDivide',
    name: 'Cataclysm Divide',
    element: Element.water,
    rarity: SpellRarity.fusion,
    starLevel: 1,
    baseDescription: 'A cataclysm that divides land from sea.',
    manaCost: 9,
    effects: [
      Effect(type: EffectType.damage, value: 28),
      Effect(type: EffectType.weaken, value: 50, duration: 4),
    ],
    allowedUpgrades: [],
  );

  /// All fusion spells.
  static List<Spell> get allFusionSpells => [
    // Fire + Fire
    solarFireball,
    hellfireOrb,
    flareImpact,
    worldPyre,
    cinderExecution,
    blazingVerdict,
    // Fire + Water
    steamburstFireball,
    thermalTsunami,
    superheatedSteam,
    evaporationSurge,
    scaldingSlash,
    steamCleave,
    // Fire + Ice
    flashMelt, thermalShock, heatFracture, thermalParadox,
    // Fire + Earth
    magmaShot,
    volcanicRupture,
    moltenBastion,
    lavaBarrage,
    magmaCataclysm,
    obsidianBulwark,
    // Fire + Air
    explosiveEmber, scatterFlame, firestormCore, scorcningGale, flameUplift,
    apocalypticFirestorm, infernoCyclone, hellwindSpiral,
    // Water
    aquaLance, surgingTorrent, glacialShot, oceanicJudgment, frozenSurge,
    absoluteZeroAegis, maelstrom, worldVortex,
    // Earth
    meteorSlam, avalancheBreak, worldbreaker, adamantFortress, continentalAegis,
    // Air
    skyRend, crosswindCut, tempestPulse, endlessTempest, worldstorm, oceanKing,
    // Legendary
    eternalSun,
    undyingInferno,
    eternalRebirth,
    forgedAscension,
    worldAnvil,
    oceansEnd,
    cataclysmDivide,
  ];

  /// Get a fusion spell by its ID.
  static Spell? getById(String id) {
    try {
      return allFusionSpells.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
