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

  /// Current spell fragments available to spend.
  int currentFragments = 0;

  /// Current crystals available to spend.
  int currentCrystals = 0;

  /// Inventory: Consumable Item IDs.
  final List<String> consumables = [];

  /// Inventory: Owned Relic IDs.
  final List<String> ownedRelics = [];

  /// Inventory: Equipped Relic IDs (Max 4).
  final List<String> equippedRelics = [];

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
    fragmentsEarnedThisRun = 0;
    crystalsEarnedThisRun = 0;
    currentFragments = 0;
    currentCrystals = 0;
    consumables.clear();
    ownedRelics.clear();
    equippedRelics.clear();
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
    if (isElite) elitesDefeated++;
    fragmentsEarnedThisRun += fragments;
    currentFragments += fragments;
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
    currentFragments += amount;
  }

  /// Adds crystals earned this run.
  void addCrystals(int amount) {
    crystalsEarnedThisRun += amount;
    currentCrystals += amount;
  }

  /// Spends fragments if available.
  bool spendFragments(int amount) {
    if (currentFragments >= amount) {
      currentFragments -= amount;
      return true;
    }
    return false;
  }

  /// Spends crystals if available.
  bool spendCrystals(int amount) {
    if (currentCrystals >= amount) {
      currentCrystals -= amount;
      return true;
    }
    return false;
  }

  // ==================== INVENTORY ====================

  /// Adds a consumable to inventory.
  void addConsumable(String itemId) {
    consumables.add(itemId);
  }

  /// Removes a consumable from inventory.
  bool removeConsumable(String itemId) {
    return consumables.remove(itemId);
  }

  /// Adds a relic to owned collection.
  void addRelic(String relicId) {
    if (!ownedRelics.contains(relicId)) {
      ownedRelics.add(relicId);
    }
  }

  /// Equips a relic in the specified slot (0-3).
  bool equipRelic(int slotIndex, String relicId) {
    if (slotIndex < 0 || slotIndex >= 4) return false;
    if (!ownedRelics.contains(relicId)) return false;

    // Ensure list has enough slots filled with empty strings if needed
    while (equippedRelics.length <= slotIndex) {
      equippedRelics.add('');
    }

    // Check if already equipped elsewhere
    if (equippedRelics.contains(relicId)) {
      final existingIndex = equippedRelics.indexOf(relicId);
      equippedRelics[existingIndex] = ''; // Unequip from old slot
    }

    equippedRelics[slotIndex] = relicId;
    return true;
  }

  /// Unequips a relic from the specified slot.
  void unequipRelic(int slotIndex) {
    if (slotIndex >= 0 && slotIndex < equippedRelics.length) {
      equippedRelics[slotIndex] = '';
    }
  }

  /// Checks if a relic is owned.
  bool hasRelic(String relicId) => ownedRelics.contains(relicId);

  /// Checks if a relic is equipped.
  bool isRelicEquipped(String relicId) => equippedRelics.contains(relicId);

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
    fragmentsEarnedThisRun = 0;
    crystalsEarnedThisRun = 0;
    currentFragments = 0;
    currentCrystals = 0;
    consumables.clear();
    ownedRelics.clear();
    equippedRelics.clear();
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
    'currentFragments': currentFragments,
    'currentCrystals': currentCrystals,
    'consumables': consumables,
    'ownedRelics': ownedRelics,
    'equippedRelics': equippedRelics,
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
    currentFragments = json['currentFragments'] as int? ?? 0;
    currentCrystals = json['currentCrystals'] as int? ?? 0;
    consumables.clear();
    consumables.addAll((json['consumables'] as List?)?.cast<String>() ?? []);
    ownedRelics.clear();
    ownedRelics.addAll((json['ownedRelics'] as List?)?.cast<String>() ?? []);
    equippedRelics.clear();
    equippedRelics.addAll(
      (json['equippedRelics'] as List?)?.cast<String>() ?? [],
    );
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
