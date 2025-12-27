/// Manages difficulty scaling throughout the run.
/// Difficulty increases via:
/// - Enemy HP
/// - Number of enemies
/// - Status effect frequency
/// - Elite modifier density
/// Never scales via raw damage spikes alone.
class DifficultyScaler {
  DifficultyScaler._();

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

  /// Calculates experience reward with depth scaling.
  static int calculateExpReward({
    required int depth,
    required int enemiesDefeated,
    bool isElite = false,
  }) {
    final baseExp = enemiesDefeated * 5;
    final depthBonus = depth * 2;
    final eliteBonus = isElite ? 15 : 0;

    return baseExp + depthBonus + eliteBonus;
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
