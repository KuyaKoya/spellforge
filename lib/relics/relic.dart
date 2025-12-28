import '../domain/element.dart';

/// Trigger conditions for relics.
enum RelicTrigger {
  /// At the start of combat
  onCombatStart,

  /// At the end of combat (victory)
  onCombatEnd,

  /// When a spell is cast
  onSpellCast,

  /// When the player takes damage
  onDamageTaken,

  /// When the player deals damage
  onDamageDealt,

  /// When an enemy is defeated
  onEnemyDefeated,

  /// At the start of each turn
  onTurnStart,

  /// At the end of each turn
  onTurnEnd,

  /// When entering a node
  onNodeEnter,

  /// When HP drops below threshold
  onLowHp,

  /// Always active (passive)
  passive,
}

/// Rarity tiers for relics.
enum RelicRarity {
  common,
  uncommon,
  rare,
  legendary;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }

  String get icon {
    switch (this) {
      case RelicRarity.common:
        return '⚪';
      case RelicRarity.uncommon:
        return '🟢';
      case RelicRarity.rare:
        return '🔵';
      case RelicRarity.legendary:
        return '🟡';
    }
  }
}

/// Represents a passive relic that provides effects during gameplay.
/// Relics are passive, deterministic, and stack-aware.
class Relic {
  /// Unique identifier.
  final String id;

  /// Display name.
  final String name;

  /// Description of the effect.
  final String description;

  /// Rarity tier.
  final RelicRarity rarity;

  /// Trigger condition.
  final RelicTrigger trigger;

  /// Synergy tags for Director biasing.
  final List<String> synergyTags;

  /// Elements this relic synergizes with.
  final List<Element> synergyElements;

  /// Whether this relic can stack.
  final bool stackable;

  /// Current stack count (for stackable relics).
  int stackCount;

  /// Effect parameters (specific to each relic).
  final Map<String, dynamic> effectParams;

  Relic({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.trigger,
    this.synergyTags = const [],
    this.synergyElements = const [],
    this.stackable = false,
    this.stackCount = 1,
    this.effectParams = const {},
  });

  /// Creates a copy of this relic.
  Relic copy() {
    return Relic(
      id: id,
      name: name,
      description: description,
      rarity: rarity,
      trigger: trigger,
      synergyTags: List.from(synergyTags),
      synergyElements: List.from(synergyElements),
      stackable: stackable,
      stackCount: stackCount,
      effectParams: Map.from(effectParams),
    );
  }

  /// Display text including rarity icon.
  String get displayName => '${rarity.icon} $name';

  /// Full display with stack count.
  String get fullDisplay {
    if (stackable && stackCount > 1) {
      return '$displayName (x$stackCount)';
    }
    return displayName;
  }

  /// Gets effect value with stacking applied.
  int getEffectValue(String key, {int defaultValue = 0}) {
    final baseValue = effectParams[key] as int? ?? defaultValue;
    return stackable ? baseValue * stackCount : baseValue;
  }

  /// Gets effect value as double with stacking applied.
  double getEffectValueDouble(String key, {double defaultValue = 0.0}) {
    final baseValue = effectParams[key] as double? ?? defaultValue;
    return stackable ? baseValue * stackCount : baseValue;
  }

  @override
  String toString() => 'Relic($name)';
}

/// Static definitions of all relics in the game.
class RelicDefinitions {
  RelicDefinitions._();

  /// All available relics.
  static List<Relic> get allRelics => [
    // ==================== COMBAT START RELICS ====================
    Relic(
      id: 'emberHeart',
      name: 'Ember Heart',
      description: 'Start combat with Burn on all enemies (3 damage, 2 turns).',
      rarity: RelicRarity.uncommon,
      trigger: RelicTrigger.onCombatStart,
      synergyTags: ['burn', 'aoe'],
      synergyElements: [Element.fire],
      effectParams: {'burnDamage': 3, 'burnDuration': 2},
    ),

    Relic(
      id: 'ironWard',
      name: 'Iron Ward',
      description: 'Start combat with 5 armor.',
      rarity: RelicRarity.common,
      trigger: RelicTrigger.onCombatStart,
      synergyTags: ['defense'],
      synergyElements: [Element.earth],
      stackable: true,
      effectParams: {'armor': 5},
    ),

    Relic(
      id: 'swiftWind',
      name: 'Swift Wind',
      description: 'Start combat with +1 action.',
      rarity: RelicRarity.rare,
      trigger: RelicTrigger.onCombatStart,
      synergyTags: ['speed', 'actions'],
      synergyElements: [Element.air],
      effectParams: {'actions': 1},
    ),

    // ==================== ON DAMAGE DEALT RELICS ====================
    Relic(
      id: 'vampiricFang',
      name: 'Vampiric Fang',
      description: 'Heal 1 HP for every 10 damage dealt.',
      rarity: RelicRarity.rare,
      trigger: RelicTrigger.onDamageDealt,
      synergyTags: ['sustain', 'damage'],
      stackable: true,
      effectParams: {'healPer': 10, 'healAmount': 1},
    ),

    Relic(
      id: 'frozenTouch',
      name: 'Frozen Touch',
      description: 'Damage has 20% chance to Slow target.',
      rarity: RelicRarity.uncommon,
      trigger: RelicTrigger.onDamageDealt,
      synergyTags: ['control', 'slow'],
      synergyElements: [Element.water],
      effectParams: {'chance': 0.2, 'slowDuration': 1},
    ),

    // ==================== ON SPELL CAST RELICS ====================
    Relic(
      id: 'manaCrystal',
      name: 'Mana Crystal',
      description: 'Restore 1 mana after casting a spell.',
      rarity: RelicRarity.uncommon,
      trigger: RelicTrigger.onSpellCast,
      synergyTags: ['mana', 'sustain'],
      stackable: true,
      effectParams: {'manaRestore': 1},
    ),

    Relic(
      id: 'echoingRune',
      name: 'Echoing Rune',
      description: '15% chance to not consume an action when casting.',
      rarity: RelicRarity.rare,
      trigger: RelicTrigger.onSpellCast,
      synergyTags: ['actions', 'luck'],
      effectParams: {'chance': 0.15},
    ),

    // ==================== ON ENEMY DEFEATED RELICS ====================
    Relic(
      id: 'soulHarvester',
      name: 'Soul Harvester',
      description: 'Heal 3 HP when defeating an enemy.',
      rarity: RelicRarity.common,
      trigger: RelicTrigger.onEnemyDefeated,
      synergyTags: ['sustain', 'healing'],
      stackable: true,
      effectParams: {'heal': 3},
    ),

    Relic(
      id: 'fragmentCollector',
      name: 'Fragment Collector',
      description: 'Gain +2 fragments per enemy defeated.',
      rarity: RelicRarity.uncommon,
      trigger: RelicTrigger.onEnemyDefeated,
      synergyTags: ['economy'],
      stackable: true,
      effectParams: {'fragments': 2},
    ),

    // ==================== PASSIVE RELICS ====================
    Relic(
      id: 'magesFocus',
      name: "Mage's Focus",
      description: '+15% damage with your primary element.',
      rarity: RelicRarity.common,
      trigger: RelicTrigger.passive,
      synergyTags: ['damage', 'element'],
      stackable: true,
      effectParams: {'damageBonus': 0.15},
    ),

    Relic(
      id: 'hardyConstitution',
      name: 'Hardy Constitution',
      description: '+10 maximum HP.',
      rarity: RelicRarity.common,
      trigger: RelicTrigger.passive,
      synergyTags: ['health', 'defense'],
      stackable: true,
      effectParams: {'maxHp': 10},
    ),

    Relic(
      id: 'deepReserves',
      name: 'Deep Reserves',
      description: '+5 maximum mana.',
      rarity: RelicRarity.uncommon,
      trigger: RelicTrigger.passive,
      synergyTags: ['mana'],
      stackable: true,
      effectParams: {'maxMana': 5},
    ),

    // ==================== ON LOW HP RELICS ====================
    Relic(
      id: 'desperationAura',
      name: 'Desperation Aura',
      description: '+30% damage when below 30% HP.',
      rarity: RelicRarity.rare,
      trigger: RelicTrigger.onLowHp,
      synergyTags: ['damage', 'risk'],
      effectParams: {'threshold': 0.3, 'damageBonus': 0.3},
    ),

    Relic(
      id: 'lastStand',
      name: 'Last Stand',
      description: 'Gain 10 armor when HP first drops below 25%.',
      rarity: RelicRarity.rare,
      trigger: RelicTrigger.onLowHp,
      synergyTags: ['defense', 'clutch'],
      effectParams: {'threshold': 0.25, 'armor': 10},
    ),

    // ==================== ON TURN START RELICS ====================
    Relic(
      id: 'regeneration',
      name: 'Regeneration',
      description: 'Heal 1 HP at the start of each turn.',
      rarity: RelicRarity.uncommon,
      trigger: RelicTrigger.onTurnStart,
      synergyTags: ['healing', 'sustain'],
      stackable: true,
      effectParams: {'heal': 1},
    ),

    Relic(
      id: 'manaWell',
      name: 'Mana Well',
      description: 'Restore 1 extra mana at the start of each turn.',
      rarity: RelicRarity.rare,
      trigger: RelicTrigger.onTurnStart,
      synergyTags: ['mana'],
      stackable: true,
      effectParams: {'mana': 1},
    ),

    // ==================== LEGENDARY RELICS ====================
    Relic(
      id: 'elementalMastery',
      name: 'Elemental Mastery',
      description: 'All elemental damage +25%.',
      rarity: RelicRarity.legendary,
      trigger: RelicTrigger.passive,
      synergyTags: ['damage', 'element'],
      effectParams: {'damageBonus': 0.25},
    ),

    Relic(
      id: 'timeBender',
      name: 'Time Bender',
      description: 'Start each combat with +2 actions.',
      rarity: RelicRarity.legendary,
      trigger: RelicTrigger.onCombatStart,
      synergyTags: ['actions', 'speed'],
      effectParams: {'actions': 2},
    ),
  ];

  /// Gets relics by rarity.
  static List<Relic> getByRarity(RelicRarity rarity) {
    return allRelics
        .where((r) => r.rarity == rarity)
        .map((r) => r.copy())
        .toList();
  }

  /// Gets relics by trigger.
  static List<Relic> getByTrigger(RelicTrigger trigger) {
    return allRelics
        .where((r) => r.trigger == trigger)
        .map((r) => r.copy())
        .toList();
  }

  /// Gets relics that synergize with an element.
  static List<Relic> getByElement(Element element) {
    return allRelics
        .where((r) => r.synergyElements.contains(element))
        .map((r) => r.copy())
        .toList();
  }

  /// Gets a relic by ID.
  static Relic? getById(String id) {
    try {
      return allRelics.firstWhere((r) => r.id == id).copy();
    } catch (_) {
      return null;
    }
  }
}
