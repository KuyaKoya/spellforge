import 'meta_difficulty.dart';
import 'exp_system.dart';

/// Manages difficulty scaling throughout the run.
///
/// Phase 7.9: Now integrates meta difficulty scaling.
/// Difficulty increases via:
/// - Enemy HP (depth + meta tier)
/// - Enemy stats (meta tier)
/// - Number of enemies (depth)
/// - Status effect frequency (depth)
/// - Elite modifier density (depth + meta tier)
///
/// Final formula for enemy stat generation:
/// FinalStat = BaseStat × ElementModifier × DepthScaling × (1 + MetaDifficultyTier × 0.05)
class DifficultyScaler {
  DifficultyScaler._();

  // ==================== DEPTH-BASED SCALING ====================

  /// Gets the enemy HP multiplier for a given depth.
  static double getHPMultiplier(int depth) {
    // Gradual HP scaling: +10% per depth after 1
    return 1.0 + ((depth - 1) * 0.1);
  }

  /// Gets the max number of enemies for a given depth.
  static int getMaxEnemies(int depth) {
    if (depth <= 2) return 2;
    if (depth <= 5) return 3;
    return 4;
  }

  /// Gets the min number of enemies for a given depth.
  static int getMinEnemies(int depth) {
    if (depth <= 2) return 1;
    if (depth <= 5) return 2;
    return 2;
  }

  /// Gets the enemy damage bonus for a given depth.
  /// Damage scaling is conservative to avoid spike deaths.
  static int getDamageBonus(int depth) {
    // +1 damage per 2 depths
    return (depth - 1) ~/ 2;
  }

  /// Gets the difficulty tier for a depth.
  static DifficultyTier getTier(int depth) {
    if (depth <= 2) return DifficultyTier.early;
    if (depth <= 5) return DifficultyTier.mid;
    if (depth <= 8) return DifficultyTier.late;
    return DifficultyTier.final_;
  }

  /// Gets the status effect chance multiplier for a depth.
  static double getStatusEffectChance(int depth) {
    // Starts at 1.0, increases by 20% per 2 depths
    return 1.0 + ((depth - 1) ~/ 2) * 0.2;
  }

  /// Gets the elite modifier count based on depth.
  static int getEliteModifierCount(int depth) {
    if (depth <= 4) return 1;
    if (depth <= 7) return 2;
    return 2; // Max 2 modifiers as per spec
  }

  /// Gets the expected player state description for a depth.
  static String getExpectedPlayerState(int depth) {
    if (depth <= 2) return 'Building initial loadout';
    if (depth == 3) return '1 upgraded spell expected';
    if (depth <= 5) return 'Core spell defined';
    if (depth <= 7) return 'Synergy online';
    return 'Build under pressure';
  }

  // ==================== PHASE 7.9: META DIFFICULTY INTEGRATION ====================

  /// Calculates the final enemy HP with depth and meta scaling.
  ///
  /// Formula: BaseHP × DepthMultiplier × MetaHPMultiplier
  static int calculateFinalHP({
    required int baseHP,
    required int depth,
    required MetaDifficultyModifiers metaMods,
    double elementModifier = 1.0,
  }) {
    final depthMultiplier = getHPMultiplier(depth);
    return (baseHP * elementModifier * depthMultiplier * metaMods.hpMultiplier)
        .round();
  }

  /// Calculates the final enemy attack with depth and meta scaling.
  static int calculateFinalAttack({
    required int baseAttack,
    required int depth,
    required MetaDifficultyModifiers metaMods,
    double elementModifier = 1.0,
  }) {
    final depthBonus = getDamageBonus(depth);
    final scaledBase =
        (baseAttack * elementModifier * metaMods.attackMultiplier).round();
    return scaledBase + depthBonus;
  }

  /// Calculates the final enemy defense with meta scaling.
  static int calculateFinalDefense({
    required int baseDefense,
    required MetaDifficultyModifiers metaMods,
    double elementModifier = 1.0,
  }) {
    return (baseDefense * elementModifier * metaMods.defenseMultiplier).round();
  }

  /// Calculates the final enemy speed with meta scaling.
  static int calculateFinalSpeed({
    required int baseSpeed,
    required MetaDifficultyModifiers metaMods,
    double elementModifier = 1.0,
  }) {
    return (baseSpeed * elementModifier * metaMods.speedMultiplier).round();
  }

  /// Gets elite passive count based on depth and meta tier.
  static int getElitePassiveCount(int depth, MetaDifficultyModifiers metaMods) {
    int baseCount = 1;
    if (depth >= 5) baseCount = 2;
    return baseCount + metaMods.eliteExtraPassives;
  }

  // ==================== REWARDS ====================

  /// Calculates fragment reward with depth scaling.
  static int calculateFragmentReward({
    required int depth,
    required int enemiesDefeated,
    bool isElite = false,
  }) {
    final baseReward = 10;
    final depthBonus = depth * 2;
    final enemyBonus = enemiesDefeated * 5;
    final eliteBonus = isElite ? 30 : 0;

    return baseReward + depthBonus + enemyBonus + eliteBonus;
  }

  /// Calculates experience reward using Phase 7.9 EXP system.
  ///
  /// Phase 7.9: Uses new enemy-type-based EXP values (8/24/90).
  static int calculateExpReward({
    required int depth,
    required int enemiesDefeated,
    bool isElite = false,
    bool isBoss = false,
  }) {
    // Determine enemy type for EXP calculation
    EnemyType type;
    if (isBoss) {
      type = EnemyType.boss;
    } else if (isElite) {
      type = EnemyType.elite;
    } else {
      type = EnemyType.normal;
    }

    // Calculate EXP for each enemy defeated
    int totalExp = 0;
    for (int i = 0; i < enemiesDefeated; i++) {
      totalExp += ExpSystem.calculateExpGained(enemyType: type, depth: depth);
    }

    return totalExp;
  }

  /// Checks if difficulty should be reduced based on player performance.
  /// Returns true if players are dying too early (adaptive difficulty hint).
  static bool shouldReduceDifficulty({
    required int averageDeathDepth,
    required int totalRuns,
  }) {
    // If players consistently die before depth 5 after 3+ runs, reduce elite frequency
    return totalRuns >= 3 && averageDeathDepth < 5;
  }

  // ==================== DEBUG ====================

  /// Gets a debug table showing difficulty scaling by depth and meta tier.
  static String getScalingTable(MetaDifficultyModifiers metaMods) {
    final buffer = StringBuffer();
    buffer.writeln('=== DIFFICULTY SCALING (Meta Tier ${metaMods.tier}) ===');
    buffer.writeln('Depth | HP Mult | DMG Bonus | Enemies | Status Chance');
    buffer.writeln('------|---------|-----------|---------|-------------');

    for (int depth = 1; depth <= 10; depth++) {
      final hpMult = getHPMultiplier(depth) * metaMods.hpMultiplier;
      final dmgBonus = getDamageBonus(depth);
      final enemies = '${getMinEnemies(depth)}-${getMaxEnemies(depth)}';
      final statusChance = getStatusEffectChance(depth);
      buffer.writeln(
        '  ${depth.toString().padLeft(2)}  |  ${hpMult.toStringAsFixed(2)}  |    ${dmgBonus.toString().padLeft(2)}     |   ${enemies.padLeft(3)}   |    ${statusChance.toStringAsFixed(1)}',
      );
    }

    return buffer.toString();
  }
}

/// Difficulty tiers for the run.
enum DifficultyTier {
  early, // Depth 1-2
  mid, // Depth 3-5
  late, // Depth 6-8
  final_; // Depth 9+

  String get displayName {
    switch (this) {
      case DifficultyTier.early:
        return 'Early Game';
      case DifficultyTier.mid:
        return 'Mid Game';
      case DifficultyTier.late:
        return 'Late Game';
      case DifficultyTier.final_:
        return 'Final Stretch';
    }
  }

  String get description {
    switch (this) {
      case DifficultyTier.early:
        return 'Build your foundation';
      case DifficultyTier.mid:
        return 'Define your strategy';
      case DifficultyTier.late:
        return 'Execute your build';
      case DifficultyTier.final_:
        return 'Survive the gauntlet';
    }
  }
}
