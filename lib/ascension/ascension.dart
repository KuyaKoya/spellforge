/// Represents an ascension level with its modifiers.
/// Ascension levels are optional difficulty modifiers that stack cumulatively.
class Ascension {
  /// The ascension level (0 = no ascension)
  final int level;

  /// Display name for this ascension.
  final String name;

  /// Description of the effects.
  final String description;

  // ==================== COMBAT MODIFIERS ====================

  /// Enemy HP multiplier (1.0 = no change)
  final double enemyHpMultiplier;

  /// Enemy damage multiplier (1.0 = no change)
  final double enemyDamageMultiplier;

  /// Combat difficulty multiplier for Director (1.0 = no change)
  final double combatDifficultyMultiplier;

  // ==================== NODE MODIFIERS ====================

  /// Bonus to elite node appearance chance
  final double eliteChanceBonus;

  /// Penalty to rest node appearance chance
  final double restChancePenalty;

  // ==================== RESOURCE MODIFIERS ====================

  /// Penalty to reward tier (negative = worse rewards)
  final int rewardTierPenalty;

  /// Fragment earning multiplier (1.0 = no change)
  final double fragmentMultiplier;

  /// Starting HP reduction (0 = no change)
  final int startingHpPenalty;

  // ==================== DIRECTOR MODIFIERS ====================

  /// Bonus to enemy synergy factor
  final double enemySynergyBonus;

  /// Modifier to mercy threshold (positive = harder to get mercy)
  final int mercyThresholdModifier;

  /// Modifier to aggression threshold (negative = easier to trigger)
  final int aggressionThresholdModifier;

  const Ascension({
    required this.level,
    required this.name,
    required this.description,
    this.enemyHpMultiplier = 1.0,
    this.enemyDamageMultiplier = 1.0,
    this.combatDifficultyMultiplier = 1.0,
    this.eliteChanceBonus = 0.0,
    this.restChancePenalty = 0.0,
    this.rewardTierPenalty = 0,
    this.fragmentMultiplier = 1.0,
    this.startingHpPenalty = 0,
    this.enemySynergyBonus = 0.0,
    this.mercyThresholdModifier = 0,
    this.aggressionThresholdModifier = 0,
  });

  /// No ascension (default difficulty).
  static const Ascension none = Ascension(
    level: 0,
    name: 'No Ascension',
    description: 'Standard difficulty',
  );

  /// Whether this is the base difficulty.
  bool get isNone => level == 0;

  /// Gets a summary of all active modifiers.
  List<String> get modifierSummary {
    final modifiers = <String>[];

    if (enemyHpMultiplier != 1.0) {
      modifiers.add(
        'Enemy HP: ${(enemyHpMultiplier * 100).toStringAsFixed(0)}%',
      );
    }
    if (enemyDamageMultiplier != 1.0) {
      modifiers.add(
        'Enemy Damage: ${(enemyDamageMultiplier * 100).toStringAsFixed(0)}%',
      );
    }
    if (eliteChanceBonus != 0) {
      modifiers.add(
        'Elite Chance: +${(eliteChanceBonus * 100).toStringAsFixed(0)}%',
      );
    }
    if (restChancePenalty != 0) {
      modifiers.add(
        'Rest Nodes: -${(restChancePenalty * 100).toStringAsFixed(0)}%',
      );
    }
    if (rewardTierPenalty != 0) {
      modifiers.add('Reward Tier: $rewardTierPenalty');
    }
    if (startingHpPenalty != 0) {
      modifiers.add('Starting HP: -$startingHpPenalty');
    }
    if (fragmentMultiplier != 1.0) {
      modifiers.add(
        'Fragments: ${(fragmentMultiplier * 100).toStringAsFixed(0)}%',
      );
    }

    return modifiers;
  }

  @override
  String toString() => 'Ascension $level: $name';
}

/// Definitions for all ascension levels.
class AscensionDefinitions {
  AscensionDefinitions._();

  /// Maximum ascension level.
  static const int maxLevel = 10;

  /// All ascension levels.
  static final List<Ascension> allAscensions = [
    Ascension.none,
    _ascension1,
    _ascension2,
    _ascension3,
    _ascension4,
    _ascension5,
    _ascension6,
    _ascension7,
    _ascension8,
    _ascension9,
    _ascension10,
  ];

  /// Gets the ascension for a given level.
  static Ascension getAscension(int level) {
    if (level < 0 || level > maxLevel) {
      return Ascension.none;
    }
    return allAscensions[level];
  }

  /// Gets cumulative effects for an ascension level.
  /// All lower level effects stack.
  static Ascension getCumulativeAscension(int level) {
    if (level <= 0) return Ascension.none;

    double enemyHpMult = 1.0;
    double enemyDamageMult = 1.0;
    double combatDiffMult = 1.0;
    double eliteBonus = 0.0;
    double restPenalty = 0.0;
    int rewardPenalty = 0;
    double fragmentMult = 1.0;
    int hpPenalty = 0;
    double synergyBonus = 0.0;
    int mercyMod = 0;
    int aggressionMod = 0;

    for (int i = 1; i <= level && i <= maxLevel; i++) {
      final asc = allAscensions[i];
      enemyHpMult *= asc.enemyHpMultiplier;
      enemyDamageMult *= asc.enemyDamageMultiplier;
      combatDiffMult *= asc.combatDifficultyMultiplier;
      eliteBonus += asc.eliteChanceBonus;
      restPenalty += asc.restChancePenalty;
      rewardPenalty += asc.rewardTierPenalty;
      fragmentMult *= asc.fragmentMultiplier;
      hpPenalty += asc.startingHpPenalty;
      synergyBonus += asc.enemySynergyBonus;
      mercyMod += asc.mercyThresholdModifier;
      aggressionMod += asc.aggressionThresholdModifier;
    }

    return Ascension(
      level: level,
      name: 'Ascension $level',
      description: 'Cumulative difficulty for level $level',
      enemyHpMultiplier: enemyHpMult,
      enemyDamageMultiplier: enemyDamageMult,
      combatDifficultyMultiplier: combatDiffMult,
      eliteChanceBonus: eliteBonus,
      restChancePenalty: restPenalty,
      rewardTierPenalty: rewardPenalty,
      fragmentMultiplier: fragmentMult,
      startingHpPenalty: hpPenalty,
      enemySynergyBonus: synergyBonus,
      mercyThresholdModifier: mercyMod,
      aggressionThresholdModifier: aggressionMod,
    );
  }

  // ==================== ASCENSION DEFINITIONS ====================

  static const _ascension1 = Ascension(
    level: 1,
    name: 'Awakened',
    description: 'Enemies are slightly stronger.',
    enemyHpMultiplier: 1.1,
  );

  static const _ascension2 = Ascension(
    level: 2,
    name: 'Hardened',
    description: 'Enemies deal more damage.',
    enemyDamageMultiplier: 1.1,
  );

  static const _ascension3 = Ascension(
    level: 3,
    name: 'Scarce',
    description: 'Rest nodes appear less frequently.',
    restChancePenalty: 0.1,
  );

  static const _ascension4 = Ascension(
    level: 4,
    name: 'Hunted',
    description: 'Elite encounters appear more often.',
    eliteChanceBonus: 0.1,
  );

  static const _ascension5 = Ascension(
    level: 5,
    name: 'Weakened',
    description: 'Start with reduced HP.',
    startingHpPenalty: 10,
  );

  static const _ascension6 = Ascension(
    level: 6,
    name: 'Coordinated',
    description: 'Enemies work together more effectively.',
    enemySynergyBonus: 0.15,
    combatDifficultyMultiplier: 1.05,
  );

  static const _ascension7 = Ascension(
    level: 7,
    name: 'Ruthless',
    description: 'The Director is less merciful.',
    mercyThresholdModifier: 10,
    aggressionThresholdModifier: -5,
  );

  static const _ascension8 = Ascension(
    level: 8,
    name: 'Brutal',
    description: 'Significantly stronger enemies.',
    enemyHpMultiplier: 1.15,
    enemyDamageMultiplier: 1.1,
  );

  static const _ascension9 = Ascension(
    level: 9,
    name: 'Impoverished',
    description: 'Reduced rewards from all sources.',
    rewardTierPenalty: -1,
    fragmentMultiplier: 0.8,
  );

  static const _ascension10 = Ascension(
    level: 10,
    name: 'Nightmare',
    description: 'The ultimate challenge.',
    enemyHpMultiplier: 1.2,
    enemyDamageMultiplier: 1.15,
    eliteChanceBonus: 0.1,
    restChancePenalty: 0.15,
    startingHpPenalty: 15,
    combatDifficultyMultiplier: 1.1,
    mercyThresholdModifier: 15,
    aggressionThresholdModifier: -10,
  );
}

/// Manager for tracking unlocked ascension levels.
class AscensionManager {
  /// Highest ascension level unlocked.
  int _highestUnlocked = 0;

  /// Current selected ascension level.
  int _selectedLevel = 0;

  /// Gets the highest unlocked ascension level.
  int get highestUnlocked => _highestUnlocked;

  /// Gets the currently selected ascension level.
  int get selectedLevel => _selectedLevel;

  /// Gets the current ascension.
  Ascension get currentAscension =>
      AscensionDefinitions.getCumulativeAscension(_selectedLevel);

  /// Whether ascensions are available.
  bool get hasUnlockedAscensions => _highestUnlocked > 0;

  /// Selects an ascension level.
  bool selectAscension(int level) {
    if (level < 0 || level > _highestUnlocked) {
      return false;
    }
    _selectedLevel = level;
    return true;
  }

  /// Unlocks the next ascension level (after a victory).
  bool unlockNextAscension() {
    if (_highestUnlocked >= AscensionDefinitions.maxLevel) {
      return false;
    }
    _highestUnlocked++;
    return true;
  }

  /// Records a victory at the current ascension level.
  void recordVictory() {
    if (_selectedLevel == _highestUnlocked &&
        _highestUnlocked < AscensionDefinitions.maxLevel) {
      unlockNextAscension();
    }
  }

  /// Gets available ascension choices.
  List<Ascension> getAvailableAscensions() {
    return List.generate(
      _highestUnlocked + 1,
      (i) => AscensionDefinitions.getCumulativeAscension(i),
    );
  }

  /// Resets to default state (for testing).
  void reset() {
    _highestUnlocked = 0;
    _selectedLevel = 0;
  }

  /// Unlocks all ascensions (for testing/debug).
  void unlockAll() {
    _highestUnlocked = AscensionDefinitions.maxLevel;
  }
}
