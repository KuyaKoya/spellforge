import '../domain/element.dart';
import '../domain/enemy.dart';

/// Pre-defined enemy templates for the game.
class EnemyDefinitions {
  EnemyDefinitions._();

  // ==================== FIRE ENEMIES ====================

  static Enemy fireImp() => Enemy(
    id: 'fireImp',
    name: 'Fire Imp',
    element: Element.fire,
    currentHP: 15,
    maxHP: 15,
    attackDamage: 4,
    armorGain: 3,
  );

  static Enemy flameSerpent() => Enemy(
    id: 'flameSerpent',
    name: 'Flame Serpent',
    element: Element.fire,
    currentHP: 25,
    maxHP: 25,
    attackDamage: 6,
    armorGain: 4,
  );

  // ==================== WATER ENEMIES ====================

  static Enemy waterSprite() => Enemy(
    id: 'waterSprite',
    name: 'Water Sprite',
    element: Element.water,
    currentHP: 12,
    maxHP: 12,
    attackDamage: 3,
    armorGain: 5,
  );

  static Enemy seaStalker() => Enemy(
    id: 'seaStalker',
    name: 'Sea Stalker',
    element: Element.water,
    currentHP: 22,
    maxHP: 22,
    attackDamage: 5,
    armorGain: 6,
  );

  // ==================== EARTH ENEMIES ====================

  static Enemy earthGolem() => Enemy(
    id: 'earthGolem',
    name: 'Earth Golem',
    element: Element.earth,
    currentHP: 30,
    maxHP: 30,
    attackDamage: 5,
    armorGain: 8,
  );

  static Enemy mudCrawler() => Enemy(
    id: 'mudCrawler',
    name: 'Mud Crawler',
    element: Element.earth,
    currentHP: 18,
    maxHP: 18,
    attackDamage: 4,
    armorGain: 5,
  );

  // ==================== AIR ENEMIES ====================

  static Enemy windWisp() => Enemy(
    id: 'windWisp',
    name: 'Wind Wisp',
    element: Element.air,
    currentHP: 10,
    maxHP: 10,
    attackDamage: 5,
    armorGain: 2,
  );

  static Enemy stormHawk() => Enemy(
    id: 'stormHawk',
    name: 'Storm Hawk',
    element: Element.air,
    currentHP: 20,
    maxHP: 20,
    attackDamage: 7,
    armorGain: 3,
  );

  /// All enemy generators.
  static List<Enemy Function()> get allEnemies => [
    fireImp,
    flameSerpent,
    waterSprite,
    seaStalker,
    earthGolem,
    mudCrawler,
    windWisp,
    stormHawk,
  ];

  /// Get enemies by element.
  static List<Enemy Function()> getByElement(Element element) {
    return [
      if (element == Element.fire) ...[fireImp, flameSerpent],
      if (element == Element.water) ...[waterSprite, seaStalker],
      if (element == Element.earth) ...[earthGolem, mudCrawler],
      if (element == Element.air) ...[windWisp, stormHawk],
    ];
  }

  /// Generates a random encounter of enemies.
  static List<Enemy> generateEncounter({
    int minEnemies = 1,
    int maxEnemies = 3,
    int difficultyLevel = 1,
  }) {
    final count =
        minEnemies +
        (DateTime.now().millisecondsSinceEpoch % (maxEnemies - minEnemies + 1));

    final generators = List<Enemy Function()>.from(allEnemies)..shuffle();

    return generators.take(count).map((gen) {
      final enemy = gen();
      // Scale by difficulty
      if (difficultyLevel > 1) {
        final hpBonus = (enemy.maxHP * 0.1 * (difficultyLevel - 1)).round();
        return Enemy(
          id: enemy.id,
          name: enemy.name,
          element: enemy.element,
          currentHP: enemy.maxHP + hpBonus,
          maxHP: enemy.maxHP + hpBonus,
          attackDamage: enemy.attackDamage + (difficultyLevel - 1),
          armorGain: enemy.armorGain,
        );
      }
      return enemy;
    }).toList();
  }
}
