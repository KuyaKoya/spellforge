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

  static Enemy waterSpirit() => Enemy(
    id: 'waterSpirit',
    name: 'Water Spirit',
    element: Element.water,
    currentHP: 12,
    maxHP: 12,
    attackDamage: 3,
    armorGain: 5,
  );

  static Enemy seaSerpent() => Enemy(
    id: 'seaSerpent',
    name: 'Sea Serpent',
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
    waterSpirit,
    seaSerpent,
    earthGolem,
    mudCrawler,
    windWisp,
    stormHawk,
  ];

  /// Get enemies by element.
  static List<Enemy Function()> getByElement(Element element) {
    return [
      if (element == Element.fire) ...[fireImp, flameSerpent],
      if (element == Element.water) ...[waterSpirit, seaSerpent],
      if (element == Element.earth) ...[earthGolem, mudCrawler],
      if (element == Element.air) ...[windWisp, stormHawk],
    ];
  }

  /// Generates a random encounter of enemies.
  /// Phase 7.6.3: Supports biased generation based on [biasElement].
  static List<Enemy> generateEncounter({
    int minEnemies = 1,
    int maxEnemies = 3,
    int difficultyLevel = 1,
    Element? biasElement,
  }) {
    final count =
        minEnemies +
        (DateTime.now().millisecondsSinceEpoch % (maxEnemies - minEnemies + 1));

    List<Enemy Function()> generators;

    if (biasElement != null) {
      // Find elements that are weak to bias (Fun) and strong against bias (Challenge)
      final weakToBias = Element.values
          .where((e) => biasElement.getMultiplierAgainst(e) > 1.0)
          .toList();
      final strongAgainstBias = Element.values
          .where((e) => e.getMultiplierAgainst(biasElement) > 1.0)
          .toList();

      final funEnemies = <Enemy Function()>[];
      final challengeEnemies = <Enemy Function()>[];
      final interactionEnemies = <Enemy Function()>[];

      for (final gen in allEnemies) {
        final dummy = gen();
        if (weakToBias.contains(dummy.element)) {
          funEnemies.add(gen);
        } else if (strongAgainstBias.contains(dummy.element)) {
          challengeEnemies.add(gen);
        } else {
          interactionEnemies.add(gen);
        }
      }

      generators = [];
      for (int i = 0; i < count; i++) {
        final roll = DateTime.now().millisecondsSinceEpoch % 100;
        if (roll < 35 && funEnemies.isNotEmpty) {
          // 35% Chance for "Fun" (Weak to player)
          generators.add(funEnemies[roll % funEnemies.length]);
        } else if (roll < 65 && challengeEnemies.isNotEmpty) {
          // 30% Chance for "Challenge" (Strong against player)
          generators.add(challengeEnemies[roll % challengeEnemies.length]);
        } else {
          // Remainder: Random selection from full pool
          generators.add(allEnemies[roll % allEnemies.length]);
        }
      }
    } else {
      generators = List<Enemy Function()>.from(allEnemies)..shuffle();
      generators = generators.take(count).toList();
    }

    return generators.map((gen) {
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
