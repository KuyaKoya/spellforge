import '../domain/element.dart';
import '../domain/enemy.dart';
import 'spell_definitions.dart';

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
  // Phase 7.10: Increased base stats to prevent one-shotting

  static Enemy fireImp() => Enemy(
    id: 'fireImp',
    name: 'Fire Imp',
    element: Element.fire,
    currentHP: 22,
    maxHP: 22,
    attackDamage: 6,
    attack: 8,
    defense: 3,
    speed: 5,
    armorGain: 4,
    maxMana: 8,
    spellLoadout: [SpellDefinitions.fireball],
  );

  static Enemy flameSerpent() => Enemy(
    id: 'flameSerpent',
    name: 'Flame Serpent',
    element: Element.fire,
    currentHP: 35,
    maxHP: 35,
    attackDamage: 8,
    attack: 10,
    defense: 4,
    speed: 4,
    armorGain: 5,
    maxMana: 12,
    spellLoadout: [SpellDefinitions.fireball, SpellDefinitions.inferno],
  );

  // ==================== WATER ENEMIES ====================

  static Enemy waterSpirit() => Enemy(
    id: 'waterSpirit',
    name: 'Water Spirit',
    element: Element.water,
    currentHP: 20,
    maxHP: 20,
    attackDamage: 5,
    attack: 6,
    defense: 6,
    speed: 3,
    armorGain: 6,
    maxMana: 8,
    spellLoadout: [SpellDefinitions.waterBolt],
  );

  static Enemy seaSerpent() => Enemy(
    id: 'seaSerpent',
    name: 'Sea Serpent',
    element: Element.water,
    currentHP: 32,
    maxHP: 32,
    attackDamage: 7,
    attack: 8,
    defense: 7,
    speed: 3,
    armorGain: 8,
    maxMana: 12,
    spellLoadout: [SpellDefinitions.waterBolt, SpellDefinitions.tidalWave],
  );

  // ==================== EARTH ENEMIES ====================

  static Enemy earthGolem() => Enemy(
    id: 'earthGolem',
    name: 'Earth Golem',
    element: Element.earth,
    currentHP: 45,
    maxHP: 45,
    attackDamage: 7,
    attack: 7,
    defense: 10,
    speed: 1,
    armorGain: 12,
    maxMana: 10,
    spellLoadout: [SpellDefinitions.rockThrow, SpellDefinitions.earthquake],
  );

  static Enemy mudCrawler() => Enemy(
    id: 'mudCrawler',
    name: 'Mud Crawler',
    element: Element.earth,
    currentHP: 28,
    maxHP: 28,
    attackDamage: 6,
    attack: 7,
    defense: 7,
    speed: 2,
    armorGain: 7,
    maxMana: 8,
    spellLoadout: [SpellDefinitions.rockThrow],
  );

  // ==================== AIR ENEMIES ====================

  static Enemy windWisp() => Enemy(
    id: 'windWisp',
    name: 'Wind Wisp',
    element: Element.air,
    currentHP: 16,
    maxHP: 16,
    attackDamage: 7,
    attack: 9,
    defense: 2,
    speed: 8,
    armorGain: 3,
    maxMana: 10,
    spellLoadout: [SpellDefinitions.windSlash, SpellDefinitions.gust],
  );

  static Enemy stormHawk() => Enemy(
    id: 'stormHawk',
    name: 'Storm Hawk',
    element: Element.air,
    currentHP: 28,
    maxHP: 28,
    attackDamage: 9,
    attack: 11,
    defense: 3,
    speed: 7,
    armorGain: 4,
    maxMana: 12,
    spellLoadout: [SpellDefinitions.windSlash, SpellDefinitions.hurricane],
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
          spellLoadout: enemy.spellLoadout,
          maxMana: enemy.maxMana,
        );
      }
      return enemy;
    }).toList();
  }
}
