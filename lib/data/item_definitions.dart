import '../domain/element.dart';

enum ItemType { consumable, relic }

abstract class ItemDefinition {
  final String id;
  final String name;
  final String description;
  final ItemType type;
  final int baseCost;
  final int rarity; // 1-3

  const ItemDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.baseCost,
    this.rarity = 1,
  });
}

class ConsumableItem extends ItemDefinition {
  final ConsumableEffect effect;

  const ConsumableItem({
    required super.id,
    required super.name,
    required super.description,
    required super.baseCost,
    required this.effect,
    super.rarity,
  }) : super(type: ItemType.consumable);
}

class RelicItem extends ItemDefinition {
  final Element element;
  final RelicEffect passiveEffect;

  /// Stat modifiers: keys like 'maxHpPercent', 'damagePercent', 'manaFlat', etc.
  final Map<String, num> stats;

  const RelicItem({
    required super.id,
    required super.name,
    required super.description,
    required super.baseCost,
    required this.element,
    required this.passiveEffect,
    this.stats = const {},
    super.rarity,
  }) : super(type: ItemType.relic);
}

enum ConsumableEffectType { heal, restoreMana, buffDamage, buffDefense }

class ConsumableEffect {
  final ConsumableEffectType type;
  final int value;
  final int durationNodes; // 0 for instant

  const ConsumableEffect({
    required this.type,
    required this.value,
    this.durationNodes = 0,
  });
}

class RelicEffect {
  final String description;
  final Map<String, dynamic> params;

  const RelicEffect({required this.description, this.params = const {}});
}

class ItemRegistry {
  static final List<ConsumableItem> consumables = [
    ConsumableItem(
      id: 'potion_heal_small',
      name: 'Minor Health Potion',
      description: 'Restores 25 HP.',
      baseCost: 30,
      effect: ConsumableEffect(type: ConsumableEffectType.heal, value: 25),
      rarity: 1,
    ),
    ConsumableItem(
      id: 'potion_mana_small',
      name: 'Minor Mana Potion',
      description: 'Restores 20 Mana.',
      baseCost: 25,
      effect: ConsumableEffect(
        type: ConsumableEffectType.restoreMana,
        value: 20,
      ),
      rarity: 1,
    ),
    ConsumableItem(
      id: 'potion_strength',
      name: 'Strength Potion',
      description: '+15% Damage for 3 rooms.',
      baseCost: 50,
      effect: ConsumableEffect(
        type: ConsumableEffectType.buffDamage,
        value: 15,
        durationNodes: 3,
      ),
      rarity: 2,
    ),
  ];

  static final List<RelicItem> relics = [
    // ==================== FIRE RELICS ====================
    RelicItem(
      id: 'relic_fire_crown',
      name: 'Ember Crown',
      description: '+8% Damage.',
      baseCost: 60,
      element: Element.fire,
      passiveEffect: RelicEffect(
        description: '+8% Damage',
        params: {'damagePercent': 8},
      ),
      stats: {'damagePercent': 8},
      rarity: 1,
    ),
    RelicItem(
      id: 'relic_fire_ruby',
      name: 'Flame Ruby',
      description: '+5% Burn Potency.',
      baseCost: 90,
      element: Element.fire,
      passiveEffect: RelicEffect(
        description: '+5% Burn Potency',
        params: {'burnPotency': 5},
      ),
      stats: {'burnPotency': 5},
      rarity: 2,
    ),
    RelicItem(
      id: 'relic_fire_core',
      name: 'Inferno Core',
      description: '+6% Max HP.',
      baseCost: 90,
      element: Element.fire,
      passiveEffect: RelicEffect(
        description: '+6% Max HP',
        params: {'maxHpPercent': 6},
      ),
      stats: {'maxHpPercent': 6},
      rarity: 2,
    ),
    RelicItem(
      id: 'relic_fire_sigil',
      name: 'Blaze Sigil',
      description: 'Burn deals +3 damage per tick.',
      baseCost: 150,
      element: Element.fire,
      passiveEffect: RelicEffect(
        description: 'Burn deals +3 damage per tick',
        params: {'burnBonusDamage': 3},
      ),
      stats: {'burnBonusDamage': 3},
      rarity: 3,
    ),

    // ==================== WATER RELICS ====================
    RelicItem(
      id: 'relic_water_circlet',
      name: 'Tidal Circlet',
      description: '+10 Max Mana.',
      baseCost: 60,
      element: Element.water,
      passiveEffect: RelicEffect(
        description: '+10 Max Mana',
        params: {'manaFlat': 10},
      ),
      stats: {'manaFlat': 10},
      rarity: 1,
    ),
    RelicItem(
      id: 'relic_water_pearl',
      name: 'Ocean Pearl',
      description: '+5% Slow Potency.',
      baseCost: 90,
      element: Element.water,
      passiveEffect: RelicEffect(
        description: '+5% Slow Potency',
        params: {'slowPotency': 5},
      ),
      stats: {'slowPotency': 5},
      rarity: 2,
    ),
    RelicItem(
      id: 'relic_water_core',
      name: 'Frost Core',
      description: '+5% Max HP.',
      baseCost: 90,
      element: Element.water,
      passiveEffect: RelicEffect(
        description: '+5% Max HP',
        params: {'maxHpPercent': 5},
      ),
      stats: {'maxHpPercent': 5},
      rarity: 2,
    ),
    RelicItem(
      id: 'relic_water_sigil',
      name: 'Wave Sigil',
      description: 'Heal 2 HP when casting Water spells.',
      baseCost: 150,
      element: Element.water,
      passiveEffect: RelicEffect(
        description: 'Heal 2 HP when casting Water spells',
        params: {'healOnWaterCast': 2},
      ),
      stats: {'healOnWaterCast': 2},
      rarity: 3,
    ),

    // ==================== EARTH RELICS ====================
    RelicItem(
      id: 'relic_earth_helm',
      name: 'Stone Helm',
      description: '+10% Armor.',
      baseCost: 60,
      element: Element.earth,
      passiveEffect: RelicEffect(
        description: '+10% Armor',
        params: {'armorPercent': 10},
      ),
      stats: {'armorPercent': 10},
      rarity: 1,
    ),
    RelicItem(
      id: 'relic_earth_shard',
      name: 'Granite Shard',
      description: '+8 Max HP.',
      baseCost: 90,
      element: Element.earth,
      passiveEffect: RelicEffect(
        description: '+8 Max HP',
        params: {'maxHpFlat': 8},
      ),
      stats: {'maxHpFlat': 8},
      rarity: 2,
    ),
    RelicItem(
      id: 'relic_earth_core',
      name: 'Bedrock Core',
      description: '+5 Defense.',
      baseCost: 90,
      element: Element.earth,
      passiveEffect: RelicEffect(
        description: '+5 Defense',
        params: {'defenseFlat': 5},
      ),
      stats: {'defenseFlat': 5},
      rarity: 2,
    ),
    RelicItem(
      id: 'relic_earth_sigil',
      name: 'Terra Sigil',
      description: 'Start combat with 8 Armor.',
      baseCost: 150,
      element: Element.earth,
      passiveEffect: RelicEffect(
        description: 'Start combat with 8 Armor',
        params: {'startingArmor': 8},
      ),
      stats: {'startingArmor': 8},
      rarity: 3,
    ),

    // ==================== AIR RELICS ====================
    RelicItem(
      id: 'relic_air_crown',
      name: 'Zephyr Crown',
      description: '+5% Speed.',
      baseCost: 60,
      element: Element.air,
      passiveEffect: RelicEffect(
        description: '+5% Speed',
        params: {'speedPercent': 5},
      ),
      stats: {'speedPercent': 5},
      rarity: 1,
    ),
    RelicItem(
      id: 'relic_air_feather',
      name: 'Gale Feather',
      description: '-3% Mana Cost.',
      baseCost: 90,
      element: Element.air,
      passiveEffect: RelicEffect(
        description: '-3% Mana Cost',
        params: {'manaCostReduction': 3},
      ),
      stats: {'manaCostReduction': 3},
      rarity: 2,
    ),
    RelicItem(
      id: 'relic_air_core',
      name: 'Storm Core',
      description: '+6% Damage.',
      baseCost: 90,
      element: Element.air,
      passiveEffect: RelicEffect(
        description: '+6% Damage',
        params: {'damagePercent': 6},
      ),
      stats: {'damagePercent': 6},
      rarity: 2,
    ),
    RelicItem(
      id: 'relic_air_sigil',
      name: 'Wind Sigil',
      description: 'First spell each combat costs 0 mana.',
      baseCost: 150,
      element: Element.air,
      passiveEffect: RelicEffect(
        description: 'First spell each combat costs 0 mana',
        params: {'firstSpellFree': true},
      ),
      stats: {},
      rarity: 3,
    ),
  ];

  static ItemDefinition? getItem(String id) {
    try {
      return [...consumables, ...relics].firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
