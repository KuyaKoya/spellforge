import 'dart:math';

/// Phase 7.9: Experience (EXP) System
///
/// Design Goals:
/// - Preserve Pokémon-style clarity with predictable stat growth
/// - Prevent long-term snowballing through meta-difficulty scaling
/// - Keep Act 1 beatable at low meta power but tense at high meta power
///
/// Target Level Curve for Act 1:
/// - Depth 1: Level 1
/// - Depth 3: Level 2
/// - Depth 5: Level 3
/// - Depth 7: Level 4
/// - Depth 9: Level 5
/// - Boss: Level 6-7
class ExpSystem {
  ExpSystem._();

  // ==================== CONSTANTS ====================

  /// Base EXP values by enemy type.
  static const int normalEnemyBaseExp = 8;
  static const int eliteEnemyBaseExp = 24;
  static const int bossEnemyBaseExp = 90;

  /// Enemy tier multipliers.
  static const double normalTierMultiplier = 1.0;
  static const double eliteTierMultiplier = 1.4;
  static const double bossTierMultiplier = 2.0;

  /// Depth multiplier coefficient (conservative to prevent depth abuse).
  static const double depthMultiplierCoefficient = 0.06;

  /// Maximum level allowed.
  static const int maxLevel = 10;

  // ==================== EXP FORMULAS ====================

  /// Calculates EXP required to reach the next level.
  ///
  /// Formula: EXP_TO_NEXT = 40 × Level^1.35
  ///
  /// This curve ensures:
  /// - Levels 1-3: Very fast progression
  /// - Levels 4-6: Moderate progression
  /// - Levels 7+: Slower progression to prevent overleveling before boss
  static int expToNextLevel(int level) {
    if (level >= maxLevel) return 0; // Max level reached
    if (level < 1) return 40; // Fallback

    return (40 * pow(level, 1.35)).round();
  }

  /// Gets the total EXP required to reach a specific level from level 1.
  static int totalExpForLevel(int targetLevel) {
    if (targetLevel <= 1) return 0;

    int total = 0;
    for (int lvl = 1; lvl < targetLevel; lvl++) {
      total += expToNextLevel(lvl);
    }
    return total;
  }

  /// Calculates the level for a given total EXP amount.
  static int levelForTotalExp(int totalExp) {
    int level = 1;
    int expAccum = 0;

    while (level < maxLevel) {
      final needed = expToNextLevel(level);
      if (expAccum + needed > totalExp) break;
      expAccum += needed;
      level++;
    }

    return level;
  }

  /// Gets progress to next level as a percentage (0.0 to 1.0).
  static double progressToNextLevel(int currentExp, int currentLevel) {
    if (currentLevel >= maxLevel) return 1.0;

    final expNeeded = expToNextLevel(currentLevel);
    if (expNeeded <= 0) return 1.0;

    return (currentExp / expNeeded).clamp(0.0, 1.0);
  }

  // ==================== EXP GAIN CALCULATION ====================

  /// Calculates the depth multiplier.
  ///
  /// Formula: DepthMultiplier = 1 + (Depth × 0.06)
  ///
  /// This is intentionally conservative to prevent depth abuse.
  static double getDepthMultiplier(int depth) {
    return 1.0 + (depth * depthMultiplierCoefficient);
  }

  /// Gets the enemy tier multiplier.
  static double getEnemyTierMultiplier(EnemyType type) {
    switch (type) {
      case EnemyType.normal:
        return normalTierMultiplier;
      case EnemyType.elite:
        return eliteTierMultiplier;
      case EnemyType.boss:
        return bossTierMultiplier;
    }
  }

  /// Gets the base EXP for an enemy type.
  static int getBaseExp(EnemyType type) {
    switch (type) {
      case EnemyType.normal:
        return normalEnemyBaseExp;
      case EnemyType.elite:
        return eliteEnemyBaseExp;
      case EnemyType.boss:
        return bossEnemyBaseExp;
    }
  }

  /// Calculates EXP gained from defeating an enemy.
  ///
  /// Formula: EXP_GAINED = BaseEXP × DepthMultiplier × EnemyTierMultiplier
  static int calculateExpGained({
    required EnemyType enemyType,
    required int depth,
  }) {
    final baseExp = getBaseExp(enemyType);
    final depthMultiplier = getDepthMultiplier(depth);
    final tierMultiplier = getEnemyTierMultiplier(enemyType);

    return (baseExp * depthMultiplier * tierMultiplier).round();
  }

  /// Calculates total EXP from a combat encounter.
  ///
  /// [enemyTypes] - List of enemy types defeated
  /// [depth] - Current run depth
  static int calculateCombatExp({
    required List<EnemyType> enemyTypes,
    required int depth,
  }) {
    int totalExp = 0;

    for (final type in enemyTypes) {
      totalExp += calculateExpGained(enemyType: type, depth: depth);
    }

    return totalExp;
  }

  // ==================== LEVEL UP STATS ====================

  /// Gets stat bonuses for leveling up.
  ///
  /// Level-up stat growth is element-driven but stacks additively
  /// with skill tree bonuses. Skill trees never multiply level stats.
  static LevelUpStats calculateLevelUpStats({
    required int fromLevel,
    required int toLevel,
  }) {
    int hpGained = 0;
    int manaGained = 0;
    int actionsGained = 0;

    for (int level = fromLevel + 1; level <= toLevel; level++) {
      // HP: +5 per level
      hpGained += 5;

      // Mana: +2 per level
      manaGained += 2;

      // Actions: +1 every 3 levels
      if (level % 3 == 0) {
        actionsGained++;
      }
    }

    return LevelUpStats(
      fromLevel: fromLevel,
      toLevel: toLevel,
      hpGained: hpGained,
      manaGained: manaGained,
      actionsGained: actionsGained,
    );
  }

  /// Gets a debug table showing the EXP curve.
  static String getExpCurveTable() {
    final buffer = StringBuffer();
    buffer.writeln('=== EXP CURVE (Phase 7.9) ===');
    buffer.writeln('Level | EXP to Next | Total EXP');
    buffer.writeln('------|-------------|----------');

    int totalExp = 0;
    for (int level = 1; level <= maxLevel; level++) {
      final expNeeded = expToNextLevel(level);
      buffer.writeln(
        '  ${level.toString().padLeft(2)}  |    ${expNeeded.toString().padLeft(4)}    |   ${totalExp.toString().padLeft(4)}',
      );
      totalExp += expNeeded;
    }

    return buffer.toString();
  }

  /// Gets expected EXP at each depth for validation.
  static String getDepthExpTable() {
    final buffer = StringBuffer();
    buffer.writeln('=== DEPTH EXP REWARDS (Phase 7.9) ===');
    buffer.writeln('Depth | Normal | Elite | Boss');
    buffer.writeln('------|--------|-------|-----');

    for (int depth = 1; depth <= 10; depth++) {
      final normalExp = calculateExpGained(
        enemyType: EnemyType.normal,
        depth: depth,
      );
      final eliteExp = calculateExpGained(
        enemyType: EnemyType.elite,
        depth: depth,
      );
      final bossExp = calculateExpGained(
        enemyType: EnemyType.boss,
        depth: depth,
      );
      buffer.writeln(
        '  ${depth.toString().padLeft(2)}  |   ${normalExp.toString().padLeft(3)}  |  ${eliteExp.toString().padLeft(3)}  | ${bossExp.toString().padLeft(4)}',
      );
    }

    return buffer.toString();
  }
}

/// Enemy type for EXP calculations.
enum EnemyType {
  normal,
  elite,
  boss;

  String get displayName {
    switch (this) {
      case EnemyType.normal:
        return 'Normal';
      case EnemyType.elite:
        return 'Elite';
      case EnemyType.boss:
        return 'Boss';
    }
  }
}

/// Result of leveling up, containing stat gains.
class LevelUpStats {
  final int fromLevel;
  final int toLevel;
  final int hpGained;
  final int manaGained;
  final int actionsGained;

  const LevelUpStats({
    required this.fromLevel,
    required this.toLevel,
    required this.hpGained,
    required this.manaGained,
    required this.actionsGained,
  });

  /// Whether any level was gained.
  bool get didLevelUp => toLevel > fromLevel;

  /// Number of levels gained.
  int get levelsGained => toLevel - fromLevel;

  /// Summary string for display.
  String get summary {
    if (!didLevelUp) return 'No level up';

    final parts = <String>[];
    if (hpGained > 0) parts.add('+$hpGained HP');
    if (manaGained > 0) parts.add('+$manaGained Mana');
    if (actionsGained > 0) parts.add('+$actionsGained Action');

    return 'Level Up! $fromLevel → $toLevel (${parts.join(', ')})';
  }

  @override
  String toString() => summary;
}
