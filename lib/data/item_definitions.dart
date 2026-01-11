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

  const RelicItem({
    required super.id,
    required super.name,
    required super.description,
    required super.baseCost,
    required this.element,
    required this.passiveEffect,
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
    // Fire Relics
    RelicItem(
      id: 'relic_fire_ember',
      name: 'Undying Ember',
      description: '+10 Max HP.',
      baseCost: 150,
      element: Element.fire,
      passiveEffect: RelicEffect(description: 'Increases Max HP by 10'),
      rarity: 1,
    ),
    RelicItem(
      id: 'relic_fire_ruby',
      name: 'Flame Ruby',
      description: '+5% Fire Damage.',
      baseCost: 200,
      element: Element.fire,
      passiveEffect: RelicEffect(description: '+5% to Fire spells'),
      rarity: 2,
    ),

    // Water Relics
    RelicItem(
      id: 'relic_water_pearl',
      name: 'Ocean Pearl',
      description: '+10 Max Mana.',
      baseCost: 150,
      element: Element.water,
      passiveEffect: RelicEffect(description: 'Increases Max Mana by 10'),
      rarity: 1,
    ),

    // Earth Relics
    RelicItem(
      id: 'relic_earth_stone',
      name: 'Granite Shard',
      description: 'Start battles with 5 Armor.',
      baseCost: 150,
      element: Element.earth,
      passiveEffect: RelicEffect(description: 'Start battle with 5 Armor'),
      rarity: 1,
    ),

    // Air Relics
    RelicItem(
      id: 'relic_air_feather',
      name: 'Zephyr Feather',
      description: 'First spell each combat costs 2 less mana.',
      baseCost: 200,
      element: Element.air,
      passiveEffect: RelicEffect(description: '-2 Mana cost for first spell'),
      rarity: 2,
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
