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
  /// Phase 7.10: Now scales ALL stats for proper difficulty progression.
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

    // Phase 7.10: Apply depth scaling to ALL stats
    return enemies.map((enemy) {
      final scaledHP = (enemy.maxHP * hpMultiplier).round();
      final scaledDamage = enemy.attackDamage + damageBonus;

      // Scale defense with depth (15% per depth after 2)
      double defenseMultiplier = 1.0;
      if (depth >= 3) {
        defenseMultiplier = 1.0 + ((depth - 2) * 0.15);
      }
      final scaledDefense = (enemy.defense * defenseMultiplier).round().clamp(
        1,
        50,
      );

      // Scale attack stat with depth (10% per depth after 4)
      double attackMultiplier = 1.0;
      if (depth >= 5) {
        attackMultiplier = 1.0 + ((depth - 4) * 0.1);
      }
      final scaledAttack =
          (enemy.attack * attackMultiplier).round() + damageBonus;

      // Scale armor gain with depth
      final scaledArmorGain = enemy.armorGain + (depth ~/ 2);

      return Enemy(
        id: enemy.id,
        name: enemy.name,
        element: enemy.element,
        currentHP: scaledHP,
        maxHP: scaledHP,
        attackDamage: scaledDamage,
        attack: scaledAttack,
        defense: scaledDefense,
        speed: enemy.speed,
        armorGain: scaledArmorGain,
        spellLoadout: enemy.spellLoadout,
        maxMana: enemy.maxMana,
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
  /// Phase 7.10: Significantly buffed boss generation.
  static List<Enemy> _generateBossEnemies(int depth) {
    final baseEnemies = EnemyDefinitions.generateEncounter(
      minEnemies: 1,
      maxEnemies: 2,
      difficultyLevel: 3,
    );

    final hpMultiplier = DifficultyScaler.getHPMultiplier(depth);

    return baseEnemies.map((enemy) {
      // Boss HP: Base × 2.5 × depth multiplier (was just × 2.0)
      final scaledHP = (enemy.maxHP * 2.5 * hpMultiplier).round();
      final scaledDamage = enemy.attackDamage + depth; // +1 damage per depth
      final scaledDefense = (enemy.defense * 1.5).round() + (depth ~/ 2);
      final scaledAttack = (enemy.attack * 1.3).round() + depth;

      return Enemy(
        id: '${enemy.id}_boss',
        name: '${enemy.name} Guardian',
        element: enemy.element,
        currentHP: scaledHP,
        maxHP: scaledHP,
        attackDamage: scaledDamage,
        attack: scaledAttack,
        defense: scaledDefense,
        speed: enemy.speed,
        armorGain: enemy.armorGain + 8,
        spellLoadout: enemy.spellLoadout,
        maxMana: enemy.maxMana + 5,
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
