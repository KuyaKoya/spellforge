import '../domain/enemy.dart';

/// Types of encounters in the game.
enum EncounterType {
  standard,
  elite,
  boss;

  String get displayName {
    switch (this) {
      case EncounterType.standard:
        return 'Combat';
      case EncounterType.elite:
        return 'Elite Combat';
      case EncounterType.boss:
        return 'Boss Battle';
    }
  }

  String get icon {
    switch (this) {
      case EncounterType.standard:
        return '⚔️';
      case EncounterType.elite:
        return '💀';
      case EncounterType.boss:
        return '👹';
    }
  }

  /// Whether retreat is possible before combat.
  bool get canRetreat => this == EncounterType.elite;

  /// Whether defeat ends the run immediately.
  bool get defeatEndsRun =>
      this == EncounterType.elite || this == EncounterType.boss;

  /// Whether this encounter type has guaranteed rewards.
  bool get hasGuaranteedRewards => this == EncounterType.elite;
}

/// Represents an encounter with enemies.
///
/// An encounter encapsulates all the data needed to set up a combat,
/// including the enemies to fight, the encounter type, depth, and
/// any special modifiers or rewards.
class Encounter {
  /// The type of encounter.
  final EncounterType type;

  /// The depth at which this encounter occurs.
  final int depth;

  /// The enemies in this encounter.
  final List<Enemy> enemies;

  /// Whether this encounter has been completed.
  bool isCompleted;

  /// Whether the player won (only valid if isCompleted is true).
  bool? playerWon;

  /// Optional warning message to display before combat.
  final String? warningMessage;

  /// Optional reward message to display before combat.
  final String? rewardPreview;

  Encounter({
    required this.type,
    required this.depth,
    required this.enemies,
    this.isCompleted = false,
    this.playerWon,
    this.warningMessage,
    this.rewardPreview,
  });

  /// Total HP of all enemies in the encounter.
  int get totalEnemyHP => enemies.fold(0, (sum, e) => sum + e.maxHP);

  /// Number of enemies in the encounter.
  int get enemyCount => enemies.length;

  /// Whether this is a multi-enemy encounter.
  bool get isMultiEnemy => enemies.length > 1;

  /// Get a formatted summary of the encounter.
  String get summary {
    final enemyList = enemies.map((e) => e.name).join(', ');
    return '${type.icon} ${type.displayName}: $enemyList';
  }

  /// Get the difficulty rating (1-5 based on enemy count and HP).
  int get difficultyRating {
    if (type == EncounterType.boss) return 5;
    if (type == EncounterType.elite) return 4;
    if (enemies.length >= 3) return 3;
    if (enemies.length >= 2) return 2;
    return 1;
  }

  /// Creates a copy with completed state.
  Encounter complete({required bool victory}) {
    return Encounter(
      type: type,
      depth: depth,
      enemies: enemies,
      isCompleted: true,
      playerWon: victory,
      warningMessage: warningMessage,
      rewardPreview: rewardPreview,
    );
  }

  @override
  String toString() =>
      'Encounter($type, depth: $depth, enemies: ${enemies.length})';
}
