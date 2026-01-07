import '../domain/mage.dart';

/// Represents the state of a single run.
///
/// Phase 7.9.3: This state CAN now be persisted via the save system.
/// It holds all data specific to the current run that will be reset
/// when the run ends.
class RunState {
  // ==================== PLAYER STATE ====================

  /// The mage for this run.
  Mage? mage;

  /// Current depth in the run (0-indexed internally).
  int currentNodeIndex = 0;

  /// Current level within the run.
  int currentLevel = 1;

  /// Experience accumulated this run.
  int experienceThisRun = 0;

  // ==================== RUN STATISTICS ====================

  /// Combats won this run.
  int combatsWon = 0;

  /// Elites defeated this run.
  int elitesDefeated = 0;

  /// Spells learned this run.
  int spellsLearned = 0;

  /// Spells upgraded this run.
  int spellsUpgraded = 0;

  /// Fragments earned this run.
  int fragmentsEarnedThisRun = 0;

  /// Crystals earned this run.
  int crystalsEarnedThisRun = 0;

  // ==================== TEMPORARY EFFECTS ====================

  /// Temporary buffs active during this run.
  final List<TemporaryBuff> temporaryBuffs = [];

  // ==================== LIFECYCLE ====================

  /// Whether a run is currently in progress.
  bool get isRunInProgress => mage != null;

  /// Whether the player is alive.
  bool get isPlayerAlive => mage?.isAlive ?? false;

  /// Current depth (1-indexed for display).
  int get currentDepth => currentNodeIndex + 1;

  /// Starts a new run with the given mage.
  void startRun(Mage selectedMage) {
    mage = selectedMage.freshCopy();
    currentNodeIndex = 0;
    currentLevel = 1;
    experienceThisRun = 0;
    combatsWon = 0;
    elitesDefeated = 0;
    spellsLearned = 0;
    spellsUpgraded = 0;
    fragmentsEarnedThisRun = 0;
    crystalsEarnedThisRun = 0;
    temporaryBuffs.clear();
  }

  /// Advances to the next node.
  void advanceNode() {
    currentNodeIndex++;
    tickTemporaryBuffs();
  }

  /// Records a combat victory.
  void recordCombatWin({
    bool isElite = false,
    int fragments = 0,
    int experience = 0,
  }) {
    combatsWon++;
    if (isElite) elitesDefeated++;
    fragmentsEarnedThisRun += fragments;
    experienceThisRun += experience;
  }

  /// Records a spell learned.
  void recordSpellLearned() {
    spellsLearned++;
  }

  /// Records a spell upgraded.
  void recordSpellUpgraded() {
    spellsUpgraded++;
  }

  /// Adds fragments earned this run.
  void addFragments(int amount) {
    fragmentsEarnedThisRun += amount;
  }

  /// Adds crystals earned this run.
  void addCrystals(int amount) {
    crystalsEarnedThisRun += amount;
  }

  // ==================== TEMPORARY BUFFS ====================

  /// Applies temporary buff damage multiplier.
  double get temporaryBuffMultiplier {
    double multiplier = 1.0;
    for (final buff in temporaryBuffs.where((b) => b.isActive)) {
      multiplier += buff.value / 100.0;
    }
    return multiplier;
  }

  /// Ticks temporary buffs (called after each node).
  void tickTemporaryBuffs() {
    for (final buff in temporaryBuffs) {
      buff.tick();
    }
    temporaryBuffs.removeWhere((b) => !b.isActive);
  }

  /// Adds a temporary buff.
  void addTemporaryBuff(TemporaryBuff buff) {
    temporaryBuffs.add(buff);
  }

  // ==================== RUN SUMMARY ====================

  /// Gets a summary of the run statistics.
  Map<String, dynamic> getSummary() {
    return {
      'nodesCompleted': currentNodeIndex,
      'combatsWon': combatsWon,
      'elitesDefeated': elitesDefeated,
      'spellsLearned': spellsLearned,
      'spellsUpgraded': spellsUpgraded,
      'fragmentsEarned': fragmentsEarnedThisRun,
      'crystalsEarned': crystalsEarnedThisRun,
    };
  }

  /// Resets the run state.
  void reset() {
    mage = null;
    currentNodeIndex = 0;
    currentLevel = 1;
    experienceThisRun = 0;
    combatsWon = 0;
    elitesDefeated = 0;
    spellsLearned = 0;
    spellsUpgraded = 0;
    fragmentsEarnedThisRun = 0;
    crystalsEarnedThisRun = 0;
    temporaryBuffs.clear();
  }

  // ==================== SERIALIZATION ====================

  /// Converts to JSON for save/load serialization.
  Map<String, dynamic> toJson() => {
    'mage': mage?.toJson(),
    'currentNodeIndex': currentNodeIndex,
    'currentLevel': currentLevel,
    'experienceThisRun': experienceThisRun,
    'combatsWon': combatsWon,
    'elitesDefeated': elitesDefeated,
    'spellsLearned': spellsLearned,
    'spellsUpgraded': spellsUpgraded,
    'fragmentsEarnedThisRun': fragmentsEarnedThisRun,
    'crystalsEarnedThisRun': crystalsEarnedThisRun,
    'temporaryBuffs': temporaryBuffs.map((b) => b.toJson()).toList(),
  };

  /// Restores state from JSON.
  void fromJson(Map<String, dynamic> json) {
    if (json['mage'] != null) {
      mage = Mage.fromJson(json['mage'] as Map<String, dynamic>);
    }
    currentNodeIndex = json['currentNodeIndex'] as int;
    currentLevel = json['currentLevel'] as int;
    experienceThisRun = json['experienceThisRun'] as int;
    combatsWon = json['combatsWon'] as int;
    elitesDefeated = json['elitesDefeated'] as int;
    spellsLearned = json['spellsLearned'] as int;
    spellsUpgraded = json['spellsUpgraded'] as int;
    fragmentsEarnedThisRun = json['fragmentsEarnedThisRun'] as int;
    crystalsEarnedThisRun = json['crystalsEarnedThisRun'] as int;
    temporaryBuffs.clear();
    for (final buffJson in (json['temporaryBuffs'] as List?) ?? []) {
      temporaryBuffs.add(
        TemporaryBuff.fromJson(buffJson as Map<String, dynamic>),
      );
    }
  }
}

/// Represents a temporary buff active during a run.
class TemporaryBuff {
  final String name;
  final int value;
  int remainingNodes;

  TemporaryBuff({
    required this.name,
    required this.value,
    required this.remainingNodes,
  });

  bool get isActive => remainingNodes > 0;

  void tick() {
    if (remainingNodes > 0) remainingNodes--;
  }

  String get displayText => '$name (+$value%, $remainingNodes nodes left)';

  /// Converts to JSON for save/load serialization.
  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
    'remainingNodes': remainingNodes,
  };

  /// Creates from JSON for save/load serialization.
  factory TemporaryBuff.fromJson(Map<String, dynamic> json) {
    return TemporaryBuff(
      name: json['name'] as String,
      value: json['value'] as int,
      remainingNodes: json['remainingNodes'] as int,
    );
  }
}
