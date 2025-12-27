import '../domain/element.dart';
import '../domain/mage.dart';

/// Pre-defined mage templates for the game.
class MageDefinitions {
  MageDefinitions._();

  static Mage pyromancer() => Mage(
    id: 'pyromancer',
    name: 'Pyromancer',
    primaryElement: Element.fire,
    passiveDescription: 'Burns deal 1 extra damage.',
    currentHP: 50,
    maxHP: 50,
    mana: 10,
    maxMana: 10,
    actionsPerTurn: 1,
  );

  static Mage hydromancer() => Mage(
    id: 'hydromancer',
    name: 'Hydromancer',
    primaryElement: Element.water,
    passiveDescription: 'Healing effects are 25% more effective.',
    currentHP: 55,
    maxHP: 55,
    mana: 12,
    maxMana: 12,
    actionsPerTurn: 1,
  );

  static Mage geomancer() => Mage(
    id: 'geomancer',
    name: 'Geomancer',
    primaryElement: Element.earth,
    passiveDescription: 'Armor effects last 1 extra turn.',
    currentHP: 60,
    maxHP: 60,
    mana: 8,
    maxMana: 8,
    actionsPerTurn: 1,
  );

  static Mage aeromancer() => Mage(
    id: 'aeromancer',
    name: 'Aeromancer',
    primaryElement: Element.air,
    passiveDescription: 'Start each combat with +1 action.',
    currentHP: 45,
    maxHP: 45,
    mana: 11,
    maxMana: 11,
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
