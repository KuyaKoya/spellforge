import '../domain/element.dart';
import '../domain/enemy.dart';

/// Phase 7.9.4: Pre-defined enemy templates with Attack/Defense/Speed stats.
///
/// Stats follow elemental identity:
/// - Fire: High attack, low defense, medium speed
/// - Water: Balanced attack/defense, low speed
/// - Earth: High HP/defense, very low speed
/// - Air: High speed, low HP/defense
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
    attack: 6,
    defense: 2,
    speed: 5,
    armorGain: 3,
  );

  static Enemy flameSerpent() => Enemy(
    id: 'flameSerpent',
    name: 'Flame Serpent',
    element: Element.fire,
    currentHP: 25,
    maxHP: 25,
    attackDamage: 6,
    attack: 8,
    defense: 3,
    speed: 4,
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
    attack: 4,
    defense: 4,
    speed: 3,
    armorGain: 5,
  );

  static Enemy seaSerpent() => Enemy(
    id: 'seaSerpent',
    name: 'Sea Serpent',
    element: Element.water,
    currentHP: 22,
    maxHP: 22,
    attackDamage: 5,
    attack: 6,
    defense: 5,
    speed: 3,
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
    attack: 5,
    defense: 7,
    speed: 1,
    armorGain: 8,
  );

  static Enemy mudCrawler() => Enemy(
    id: 'mudCrawler',
    name: 'Mud Crawler',
    element: Element.earth,
    currentHP: 18,
    maxHP: 18,
    attackDamage: 4,
    attack: 5,
    defense: 5,
    speed: 2,
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
    attack: 7,
    defense: 1,
    speed: 8,
    armorGain: 2,
  );

  static Enemy stormHawk() => Enemy(
    id: 'stormHawk',
    name: 'Storm Hawk',
    element: Element.air,
    currentHP: 20,
    maxHP: 20,
    attackDamage: 7,
    attack: 9,
    defense: 2,
    speed: 7,
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
      final weakToBias = Element.values
          .where((e) => biasElement.getMultiplierAgainst(e) > 1.0)
          .toList();
      final strongAgainstBias = Element.values
          .where((e) => e.getMultiplierAgainst(biasElement) > 1.0)
          .toList();

      final funEnemies = <Enemy Function()>[];
      final challengeEnemies = <Enemy Function()>[];

      for (final gen in allEnemies) {
        final dummy = gen();
        if (weakToBias.contains(dummy.element)) {
          funEnemies.add(gen);
        } else if (strongAgainstBias.contains(dummy.element)) {
          challengeEnemies.add(gen);
        }
      }

      generators = [];
      for (int i = 0; i < count; i++) {
        final roll = DateTime.now().millisecondsSinceEpoch % 100;
        if (roll < 35 && funEnemies.isNotEmpty) {
          generators.add(funEnemies[roll % funEnemies.length]);
        } else if (roll < 65 && challengeEnemies.isNotEmpty) {
          generators.add(challengeEnemies[roll % challengeEnemies.length]);
        } else {
          generators.add(allEnemies[roll % allEnemies.length]);
        }
      }
    } else {
      generators = List<Enemy Function()>.from(allEnemies)..shuffle();
      generators = generators.take(count).toList();
    }

    return generators.map((gen) {
      final enemy = gen();
      if (difficultyLevel > 1) {
        final hpBonus = (enemy.maxHP * 0.1 * (difficultyLevel - 1)).round();
        return Enemy(
          id: enemy.id,
          name: enemy.name,
          element: enemy.element,
          currentHP: enemy.maxHP + hpBonus,
          maxHP: enemy.maxHP + hpBonus,
          attackDamage: enemy.attackDamage + (difficultyLevel - 1),
          attack: enemy.attack,
          defense: enemy.defense,
          speed: enemy.speed,
          armorGain: enemy.armorGain,
        );
      }
      return enemy;
    }).toList();
  }
}
