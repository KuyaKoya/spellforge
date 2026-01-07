import '../domain/effect.dart';

/// Serializable snapshot of a complete run state.
///
/// This model captures all state required to resume a run exactly
/// where it was left off, with no divergence in game outcomes.
class RunSaveData {
  // ==================== PLAYER STATE ====================

  /// Mage HP at save time.
  final int playerHP;

  /// Mage max HP at save time.
  final int playerMaxHP;

  /// Current mana.
  final int playerMana;

  /// Max mana.
  final int playerMaxMana;

  /// Current armor value.
  final int playerArmor;

  /// Player level.
  final int playerLevel;

  /// Experience in current level.
  final int playerExp;

  /// Equipped spells (JSON serialized).
  final List<Map<String, dynamic>> equippedSpells;

  /// Active status effects on player.
  final List<Map<String, dynamic>> playerStatusEffects;

  /// Mana cost modifiers by element.
  final Map<String, int> manaCostModifiers;

  /// Extra actions per turn.
  final int extraActionsPerTurn;

  /// Starting element for this run.
  final String startingElement;

  // ==================== RUN STATE ====================

  /// Current node index (0-indexed).
  final int currentNodeIndex;

  /// Current level within the run.
  final int currentLevel;

  /// Experience this run.
  final int experienceThisRun;

  /// Combats won.
  final int combatsWon;

  /// Elites defeated.
  final int elitesDefeated;

  /// Spells learned.
  final int spellsLearned;

  /// Spells upgraded.
  final int spellsUpgraded;

  /// Fragments earned this run.
  final int fragmentsEarnedThisRun;

  /// Crystals earned this run.
  final int crystalsEarnedThisRun;

  /// RNG seed for deterministic randomness.
  final int rngSeed;

  /// Elites whose dialogue has been shown.
  final List<String> shownEliteDialogues;

  // ==================== DIRECTOR STATE ====================

  /// Director pressure state.
  final String directorPressureState;

  /// Turns since state change.
  final int directorTurnsSinceStateChange;

  /// Pressure score.
  final int directorPressureScore;

  // ==================== META SNAPSHOT ====================

  /// Difficulty tier at save time (for validation).
  final int difficultyTier;

  /// Timestamp of save.
  final DateTime savedAt;

  /// Save format version for migration.
  static const int currentVersion = 1;
  final int version;

  RunSaveData({
    required this.playerHP,
    required this.playerMaxHP,
    required this.playerMana,
    required this.playerMaxMana,
    required this.playerArmor,
    required this.playerLevel,
    required this.playerExp,
    required this.equippedSpells,
    required this.playerStatusEffects,
    required this.manaCostModifiers,
    required this.extraActionsPerTurn,
    required this.startingElement,
    required this.currentNodeIndex,
    required this.currentLevel,
    required this.experienceThisRun,
    required this.combatsWon,
    required this.elitesDefeated,
    required this.spellsLearned,
    required this.spellsUpgraded,
    required this.fragmentsEarnedThisRun,
    required this.crystalsEarnedThisRun,
    required this.rngSeed,
    required this.shownEliteDialogues,
    required this.directorPressureState,
    required this.directorTurnsSinceStateChange,
    required this.directorPressureScore,
    required this.difficultyTier,
    required this.savedAt,
    this.version = currentVersion,
  });

  /// Converts to JSON for storage.
  Map<String, dynamic> toJson() => {
    'version': version,
    'savedAt': savedAt.toIso8601String(),
    // Player state
    'playerHP': playerHP,
    'playerMaxHP': playerMaxHP,
    'playerMana': playerMana,
    'playerMaxMana': playerMaxMana,
    'playerArmor': playerArmor,
    'playerLevel': playerLevel,
    'playerExp': playerExp,
    'equippedSpells': equippedSpells,
    'playerStatusEffects': playerStatusEffects,
    'manaCostModifiers': manaCostModifiers,
    'extraActionsPerTurn': extraActionsPerTurn,
    'startingElement': startingElement,
    // Run state
    'currentNodeIndex': currentNodeIndex,
    'currentLevel': currentLevel,
    'experienceThisRun': experienceThisRun,
    'combatsWon': combatsWon,
    'elitesDefeated': elitesDefeated,
    'spellsLearned': spellsLearned,
    'spellsUpgraded': spellsUpgraded,
    'fragmentsEarnedThisRun': fragmentsEarnedThisRun,
    'crystalsEarnedThisRun': crystalsEarnedThisRun,
    'rngSeed': rngSeed,
    'shownEliteDialogues': shownEliteDialogues,
    // Director state
    'directorPressureState': directorPressureState,
    'directorTurnsSinceStateChange': directorTurnsSinceStateChange,
    'directorPressureScore': directorPressureScore,
    // Meta
    'difficultyTier': difficultyTier,
  };

  /// Creates from JSON.
  factory RunSaveData.fromJson(Map<String, dynamic> json) {
    return RunSaveData(
      version: json['version'] as int? ?? 1,
      savedAt: DateTime.parse(json['savedAt'] as String),
      // Player state
      playerHP: json['playerHP'] as int,
      playerMaxHP: json['playerMaxHP'] as int,
      playerMana: json['playerMana'] as int,
      playerMaxMana: json['playerMaxMana'] as int,
      playerArmor: json['playerArmor'] as int? ?? 0,
      playerLevel: json['playerLevel'] as int,
      playerExp: json['playerExp'] as int,
      equippedSpells: (json['equippedSpells'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      playerStatusEffects: (json['playerStatusEffects'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      manaCostModifiers: Map<String, int>.from(
        (json['manaCostModifiers'] as Map?) ?? {},
      ),
      extraActionsPerTurn: json['extraActionsPerTurn'] as int? ?? 0,
      startingElement: json['startingElement'] as String,
      // Run state
      currentNodeIndex: json['currentNodeIndex'] as int,
      currentLevel: json['currentLevel'] as int,
      experienceThisRun: json['experienceThisRun'] as int,
      combatsWon: json['combatsWon'] as int,
      elitesDefeated: json['elitesDefeated'] as int,
      spellsLearned: json['spellsLearned'] as int,
      spellsUpgraded: json['spellsUpgraded'] as int,
      fragmentsEarnedThisRun: json['fragmentsEarnedThisRun'] as int,
      crystalsEarnedThisRun: json['crystalsEarnedThisRun'] as int,
      rngSeed: json['rngSeed'] as int,
      shownEliteDialogues: (json['shownEliteDialogues'] as List).cast<String>(),
      // Director state
      directorPressureState: json['directorPressureState'] as String,
      directorTurnsSinceStateChange:
          json['directorTurnsSinceStateChange'] as int,
      directorPressureScore: json['directorPressureScore'] as int,
      // Meta
      difficultyTier: json['difficultyTier'] as int,
    );
  }

  /// Validates the save data for integrity.
  bool validate() {
    // Version check
    if (version > currentVersion) return false;

    // Basic sanity checks
    if (playerHP < 0 || playerHP > playerMaxHP) return false;
    if (playerMana < 0 || playerMana > playerMaxMana) return false;
    if (equippedSpells.isEmpty) return false;
    if (currentNodeIndex < 0) return false;

    return true;
  }

  @override
  String toString() =>
      'RunSaveData(node: $currentNodeIndex, HP: $playerHP/$playerMaxHP, saved: $savedAt)';
}

/// Represents a serializable active status effect.
class SerializableStatusEffect {
  final String type;
  final int value;
  final int remainingDuration;

  SerializableStatusEffect({
    required this.type,
    required this.value,
    required this.remainingDuration,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'value': value,
    'remainingDuration': remainingDuration,
  };

  factory SerializableStatusEffect.fromJson(Map<String, dynamic> json) =>
      SerializableStatusEffect(
        type: json['type'] as String,
        value: json['value'] as int,
        remainingDuration: json['remainingDuration'] as int,
      );

  /// Converts from ActiveStatusEffect.
  factory SerializableStatusEffect.fromActiveEffect(
    ActiveStatusEffect effect,
  ) => SerializableStatusEffect(
    type: effect.type.name,
    value: effect.value,
    remainingDuration: effect.remainingDuration,
  );

  /// Converts to ActiveStatusEffect.
  ActiveStatusEffect toActiveEffect() => ActiveStatusEffect(
    type: EffectType.values.firstWhere((e) => e.name == type),
    value: value,
    remainingDuration: remainingDuration,
  );
}
