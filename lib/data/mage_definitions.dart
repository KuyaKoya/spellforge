import '../domain/element.dart';
import '../domain/mage.dart';

/// Phase 7.9.4: Pre-defined mage templates with base stats.
///
/// Base Stats by Element (before level growth):
/// - Pyromancer: High attack, low survivability
/// - Hydromancer: High HP/mana, balanced
/// - Geomancer: Very high HP/defense, low speed
/// - Aeromancer: High speed, low HP/defense
class MageDefinitions {
  MageDefinitions._();

  static Mage pyromancer() => Mage(
    id: 'pyromancer',
    name: 'Pyromancer',
    primaryElement: Element.fire,
    passiveDescription: 'Burns deal 1 extra damage.',
    baseHP: 50,
    baseMana: 10,
    baseAttack: 8,
    baseDefense: 3,
    baseSpeed: 5,
    currentHP: 50,
    mana: 10,
    actionsPerTurn: 1,
  );

  static Mage hydromancer() => Mage(
    id: 'hydromancer',
    name: 'Hydromancer',
    primaryElement: Element.water,
    passiveDescription: 'Healing effects are 25% more effective.',
    baseHP: 55,
    baseMana: 12,
    baseAttack: 5,
    baseDefense: 5,
    baseSpeed: 4,
    currentHP: 55,
    mana: 12,
    actionsPerTurn: 1,
  );

  static Mage geomancer() => Mage(
    id: 'geomancer',
    name: 'Geomancer',
    primaryElement: Element.earth,
    passiveDescription: 'Armor effects last 1 extra turn.',
    baseHP: 60,
    baseMana: 8,
    baseAttack: 5,
    baseDefense: 8,
    baseSpeed: 2,
    currentHP: 60,
    mana: 8,
    actionsPerTurn: 1,
  );

  static Mage aeromancer() => Mage(
    id: 'aeromancer',
    name: 'Aeromancer',
    primaryElement: Element.air,
    passiveDescription: 'Start each combat with +1 action.',
    baseHP: 45,
    baseMana: 11,
    baseAttack: 6,
    baseDefense: 3,
    baseSpeed: 8,
    currentHP: 45,
    mana: 11,
    actionsPerTurn: 1,
  );

  /// All available mages.
  static List<Mage> get allMages => [
    pyromancer(),
    hydromancer(),
    geomancer(),
    aeromancer(),
  ];

  /// Get mage by element.
  static Mage getByElement(Element element) {
    switch (element) {
      case Element.fire:
        return pyromancer();
      case Element.water:
        return hydromancer();
      case Element.earth:
        return geomancer();
      case Element.air:
        return aeromancer();
    }
  }
}
