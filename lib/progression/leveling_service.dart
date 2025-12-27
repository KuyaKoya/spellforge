/// Configuration for leveling thresholds and rewards.
class LevelConfig {
  /// XP required for each level.
  static const List<int> xpThresholds = [
    0, // Level 1 (starting)
    100, // Level 2
    250, // Level 3
    450, // Level 4
    700, // Level 5
    1000, // Level 6
    1400, // Level 7
    1900, // Level 8
    2500, // Level 9
    3200, // Level 10 (max)
  ];

  /// HP bonus per level.
  static const int hpPerLevel = 5;

  /// Mana bonus per level (every 2 levels).
  static const int manaEveryNLevels = 2;

  /// Actions bonus per level (every 3 levels).
  static const int actionsEveryNLevels = 3;

  /// Maximum level.
  static const int maxLevel = 10;
}

/// Results of leveling up.
class LevelUpResult {
  final int previousLevel;
  final int newLevel;
  final int hpGained;
  final int manaGained;
  final int actionsGained;

  const LevelUpResult({
    required this.previousLevel,
    required this.newLevel,
    required this.hpGained,
    required this.manaGained,
    required this.actionsGained,
  });

  /// Whether any level was gained.
  bool get didLevelUp => newLevel > previousLevel;

  /// Number of levels gained.
  int get levelsGained => newLevel - previousLevel;

  /// Get a formatted summary.
  String get summary {
    if (!didLevelUp) return 'No level up';

    final bonuses = <String>[];
    if (hpGained > 0) bonuses.add('+$hpGained HP');
    if (manaGained > 0) bonuses.add('+$manaGained Mana');
    if (actionsGained > 0) bonuses.add('+$actionsGained Action');

    return 'Level Up! $previousLevel → $newLevel (${bonuses.join(', ')})';
  }
}

/// Service for handling leveling logic.
///
/// Pure functions for calculating level-ups and rewards.
/// Does not manage state directly - that's the responsibility
/// of [RunState] and [MetaState].
class LevelingService {
  LevelingService._();

  /// Calculates the level for a given XP amount.
  static int getLevelForXP(int totalXP) {
    for (int i = LevelConfig.xpThresholds.length - 1; i >= 0; i--) {
      if (totalXP >= LevelConfig.xpThresholds[i]) {
        return i + 1;
      }
    }
    return 1;
  }

  /// Calculates XP needed for the next level.
  static int getXPForNextLevel(int currentLevel) {
    if (currentLevel >= LevelConfig.maxLevel) return 0;
    return LevelConfig.xpThresholds[currentLevel];
  }

  /// Calculates progress to next level (0.0 to 1.0).
  static double getProgressToNextLevel(int totalXP, int currentLevel) {
    if (currentLevel >= LevelConfig.maxLevel) return 1.0;

    final currentThreshold = LevelConfig.xpThresholds[currentLevel - 1];
    final nextThreshold = LevelConfig.xpThresholds[currentLevel];
    final xpInLevel = totalXP - currentThreshold;
    final xpNeeded = nextThreshold - currentThreshold;

    return xpInLevel / xpNeeded;
  }

  /// Calculates the result of applying XP.
  static LevelUpResult applyXP({
    required int currentLevel,
    required int currentXP,
    required int xpGained,
  }) {
    final totalXP = currentXP + xpGained;
    final newLevel = getLevelForXP(totalXP);

    if (newLevel <= currentLevel) {
      return LevelUpResult(
        previousLevel: currentLevel,
        newLevel: currentLevel,
        hpGained: 0,
        manaGained: 0,
        actionsGained: 0,
      );
    }

    // Calculate total bonuses for all levels gained
    int hpGained = 0;
    int manaGained = 0;
    int actionsGained = 0;

    for (int level = currentLevel + 1; level <= newLevel; level++) {
      hpGained += LevelConfig.hpPerLevel;

      if (level % LevelConfig.manaEveryNLevels == 0) {
        manaGained++;
      }

      if (level % LevelConfig.actionsEveryNLevels == 0) {
        actionsGained++;
      }
    }

    return LevelUpResult(
      previousLevel: currentLevel,
      newLevel: newLevel,
      hpGained: hpGained,
      manaGained: manaGained,
      actionsGained: actionsGained,
    );
  }

  /// Gets the rewards for a specific level.
  static Map<String, int> getLevelRewards(int level) {
    return {
      'hp': LevelConfig.hpPerLevel,
      'mana': (level % LevelConfig.manaEveryNLevels == 0) ? 1 : 0,
      'actions': (level % LevelConfig.actionsEveryNLevels == 0) ? 1 : 0,
    };
  }
}
