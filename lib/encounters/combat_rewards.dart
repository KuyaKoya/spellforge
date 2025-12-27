/// Result of a completed combat encounter.
///
/// This DTO decouples combat mechanics from presentation,
/// allowing the combat system to return structured data
/// that can be rendered in different ways.
class CombatResultDTO {
  /// Whether the player won the combat.
  final bool playerWon;

  /// The full combat log.
  final List<String> fullLog;

  /// Number of turns the combat lasted.
  final int turnsElapsed;

  /// Number of enemies defeated.
  final int enemiesDefeated;

  /// Total damage dealt by the player.
  final int totalDamageDealt;

  /// Total damage taken by the player.
  final int totalDamageTaken;

  /// Spells cast during combat.
  final int spellsCast;

  /// Whether this was an elite combat.
  final bool isElite;

  /// Whether this was a boss combat.
  final bool isBoss;

  CombatResultDTO({
    required this.playerWon,
    required this.fullLog,
    required this.turnsElapsed,
    required this.enemiesDefeated,
    this.totalDamageDealt = 0,
    this.totalDamageTaken = 0,
    this.spellsCast = 0,
    this.isElite = false,
    this.isBoss = false,
  });

  /// Whether the combat ended quickly (3 turns or less).
  bool get wasQuickVictory => playerWon && turnsElapsed <= 3;

  /// Whether the combat was a close call (player HP low).
  bool get wasClose => playerWon && turnsElapsed > 5;

  /// Get a summary of the combat.
  String get summary {
    if (playerWon) {
      return 'Victory in $turnsElapsed turns! Defeated $enemiesDefeated enemies.';
    } else {
      return 'Defeat after $turnsElapsed turns.';
    }
  }

  @override
  String toString() {
    return 'CombatResultDTO(won: $playerWon, turns: $turnsElapsed, '
        'enemies: $enemiesDefeated, elite: $isElite, boss: $isBoss)';
  }
}

/// Rewards earned from a combat encounter.
class CombatRewards {
  /// Spell fragments earned.
  final int fragments;

  /// Experience points earned.
  final int experience;

  /// Spell crystals earned (rare).
  final int crystals;

  /// Bonus fragment multiplier applied.
  final double bonusMultiplier;

  CombatRewards({
    required this.fragments,
    required this.experience,
    this.crystals = 0,
    this.bonusMultiplier = 1.0,
  });

  /// Total fragments after bonus.
  int get totalFragments => (fragments * bonusMultiplier).round();

  /// Whether any crystals were earned.
  bool get hasCrystals => crystals > 0;

  /// Get a formatted reward summary.
  String get summary {
    final lines = <String>[];
    lines.add('💎 $totalFragments fragments');
    if (hasCrystals) {
      lines.add('✨ $crystals crystals');
    }
    lines.add('⭐ $experience XP');
    return lines.join('\n');
  }

  @override
  String toString() {
    return 'CombatRewards(fragments: $totalFragments, xp: $experience, crystals: $crystals)';
  }
}
