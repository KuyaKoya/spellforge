import '../domain/mage.dart';

/// Represents the transient state of a single run.
///
/// This state is created fresh for each run and is NOT persisted.
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
}
