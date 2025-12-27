import 'dart:math';
import '../data/enemy_definitions.dart';
import '../data/elite_definitions.dart';
import '../domain/enemy.dart';
import '../systems/difficulty_scaler.dart';
import 'encounter.dart';

/// Generates encounters for different node types and depths.
///
/// This class centralizes all encounter generation logic, making it
/// easy to balance and modify enemy compositions without changing
/// the combat system itself.
class EncounterGenerator {
  EncounterGenerator._();

  static final _random = Random();

  // ==================== STANDARD COMBAT ====================

  /// Generates a standard combat encounter for the given depth.
  static Encounter generateStandardEncounter(int depth) {
    final enemies = _generateScaledEnemies(depth);

    return Encounter(
      type: EncounterType.standard,
      depth: depth,
      enemies: enemies,
    );
  }

  /// Generates scaled enemies for a given depth.
  static List<Enemy> _generateScaledEnemies(int depth) {
    final minEnemies = DifficultyScaler.getMinEnemies(depth);
    final maxEnemies = DifficultyScaler.getMaxEnemies(depth);
    final hpMultiplier = DifficultyScaler.getHPMultiplier(depth);
    final damageBonus = DifficultyScaler.getDamageBonus(depth);

    final enemies = EnemyDefinitions.generateEncounter(
      minEnemies: minEnemies,
      maxEnemies: maxEnemies,
      difficultyLevel: 1,
    );

    // Apply depth scaling
    return enemies.map((enemy) {
      final scaledHP = (enemy.maxHP * hpMultiplier).round();
      final scaledDamage = enemy.attackDamage + damageBonus;

      return Enemy(
        id: enemy.id,
        name: enemy.name,
        element: enemy.element,
        currentHP: scaledHP,
        maxHP: scaledHP,
        attackDamage: scaledDamage,
        armorGain: enemy.armorGain,
      );
    }).toList();
  }

  // ==================== ELITE COMBAT ====================

  /// Generates an elite encounter for the given depth.
  static Encounter generateEliteEncounter(int depth) {
    final elites = EliteDefinitions.getScaledEliteEncounter(depth: depth);
    final enemies = elites.cast<Enemy>();

    return Encounter(
      type: EncounterType.elite,
      depth: depth,
      enemies: enemies,
      warningMessage: '⚠️ WARNING: Defeat means the run ends!',
      rewardPreview: '🏆 REWARD: Guaranteed rare reward on victory',
    );
  }

  // ==================== BOSS COMBAT ====================

  /// Generates a boss encounter for the final depth.
  static Encounter generateBossEncounter(int depth) {
    final enemies = _generateBossEnemies(depth);

    return Encounter(
      type: EncounterType.boss,
      depth: depth,
      enemies: enemies,
      warningMessage: '👹 FINAL CHALLENGE: Defeat the elemental guardian!',
      rewardPreview: '🎉 Victory completes the run!',
    );
  }

  /// Generates boss-level enemies.
  static List<Enemy> _generateBossEnemies(int depth) {
    final baseEnemies = EnemyDefinitions.generateEncounter(
      minEnemies: 1,
      maxEnemies: 2,
      difficultyLevel: 3,
    );

    return baseEnemies.map((enemy) {
      return Enemy(
        id: '${enemy.id}_boss',
        name: '${enemy.name} Guardian',
        element: enemy.element,
        currentHP: (enemy.maxHP * 2.0).round(),
        maxHP: (enemy.maxHP * 2.0).round(),
        attackDamage: enemy.attackDamage + 3,
        armorGain: enemy.armorGain + 5,
      );
    }).toList();
  }

  // ==================== UTILITY METHODS ====================

  /// Generates an encounter based on the given type.
  static Encounter generate({required EncounterType type, required int depth}) {
    switch (type) {
      case EncounterType.standard:
        return generateStandardEncounter(depth);
      case EncounterType.elite:
        return generateEliteEncounter(depth);
      case EncounterType.boss:
        return generateBossEncounter(depth);
    }
  }

  /// Checks if a spell crystal drop should occur.
  static bool shouldDropSpellCrystal(int depth) {
    if (depth < 4) return false;

    final chance = 0.05 + ((depth - 4) * 0.02); // 5% base + 2% per depth
    return _random.nextDouble() < chance;
  }
}
