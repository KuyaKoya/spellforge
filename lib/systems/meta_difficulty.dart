/// Phase 7.9: Anti-Snowball Difficulty Scaling (Meta Progression)
///
/// This system prevents long-term snowballing by:
/// - Tracking persistent run metrics (successful runs, skill tree depth)
/// - Calculating a MetaDifficultyTier based on accumulated power
/// - Applying scaling effects to enemies based on the tier
///
/// Design Philosophy:
/// - Persistent power must increase challenge
/// - Skill trees specialize, levels stabilize
/// - Winning runs increases challenge
/// - Losing runs do NOT punish the player
/// - EXP pacing stays stable regardless of meta power
/// - Boss remains a check, not a formality
class MetaDifficultySystem {
  MetaDifficultySystem._();

  // ==================== CONSTANTS ====================

  /// Successful runs required per difficulty tier increase.
  static const int runsPerTier = 2;

  /// Skill nodes required per difficulty tier increase.
  static const int nodesPerTier = 8;

  /// Maximum tier for Act 1 (prevents runaway difficulty).
  static const int maxTierAct1 = 5;

  // ==================== TIER EFFECTS ====================

  /// Enemy HP scaling per tier (%).
  static const double hpScalingPerTier = 0.06; // +6%

  /// Enemy Attack scaling per tier (%).
  static const double attackScalingPerTier = 0.05; // +5%

  /// Enemy Defense scaling per tier (%).
  static const double defenseScalingPerTier = 0.04; // +4%

  /// Enemy Speed scaling per tier (%).
  static const double speedScalingPerTier = 0.02; // +2%

  /// Tier at which elites gain +1 passive.
  static const int elitePassiveTierThreshold = 3;

  /// Tier at which boss AI advances a phase.
  static const int bossAIPhaseTierThreshold = 4;

  // ==================== TIER CALCULATION ====================

  /// Calculates the MetaDifficultyTier based on persistent run metrics.
  ///
  /// Formula:
  /// MetaDifficultyTier = floor(successfulRuns / 2) + floor(skillTreeDepth / 8)
  ///
  /// This means:
  /// - Every 2 successful runs increases difficulty
  /// - Every 8 skill nodes unlocked increases difficulty
  /// - Soft, predictable scaling
  static int calculateMetaDifficultyTier({
    required int successfulRuns,
    required int skillTreeDepth,
    int maxTier = maxTierAct1,
  }) {
    final runContribution = successfulRuns ~/ runsPerTier;
    final nodeContribution = skillTreeDepth ~/ nodesPerTier;

    return (runContribution + nodeContribution).clamp(0, maxTier);
  }

  // ==================== STAT SCALING ====================

  /// Gets the stat multiplier for enemies at a given tier.
  ///
  /// All multipliers are applied as: FinalStat = BaseStat × (1 + MetaDifficultyTier × ScalingRate)
  static MetaDifficultyModifiers getModifiers(int tier) {
    final clampedTier = tier.clamp(0, maxTierAct1);

    return MetaDifficultyModifiers(
      tier: clampedTier,
      hpMultiplier: 1.0 + (clampedTier * hpScalingPerTier),
      attackMultiplier: 1.0 + (clampedTier * attackScalingPerTier),
      defenseMultiplier: 1.0 + (clampedTier * defenseScalingPerTier),
      speedMultiplier: 1.0 + (clampedTier * speedScalingPerTier),
      eliteExtraPassives: clampedTier >= elitePassiveTierThreshold ? 1 : 0,
      bossExtraPhases: clampedTier >= bossAIPhaseTierThreshold ? 1 : 0,
    );
  }

  /// Applies meta difficulty tier to a base stat.
  ///
  /// Final formula for enemy generation:
  /// FinalStat = BaseStat × ElementModifier × DepthScaling × (1 + MetaDifficultyTier × 0.05)
  static int applyToStat({
    required int baseStat,
    required double metaMultiplier,
    double elementModifier = 1.0,
    double depthScaling = 1.0,
  }) {
    return (baseStat * elementModifier * depthScaling * metaMultiplier).round();
  }

  // ==================== ELITE BEHAVIOR ====================

  /// Gets enhanced elite behavior at higher tiers.
  ///
  /// Effects:
  /// - Smarter spell priority
  /// - Higher status effect uptime
  /// - Earlier passive activation
  static EliteBehaviorModifiers getEliteBehaviorModifiers(int tier) {
    return EliteBehaviorModifiers(
      spellPriorityBonus: tier >= 2 ? 0.15 : 0.0, // +15% smarter targeting
      statusEffectUptimeBonus: tier >= 2 ? 0.1 : 0.0, // +10% uptime
      passiveActivationBonus: tier >= 3 ? 1 : 0, // Passives trigger earlier
    );
  }

  // ==================== BOSS BEHAVIOR ====================

  /// Gets enhanced boss behavior at higher tiers.
  ///
  /// Effects:
  /// - Increased resistance thresholds
  /// - Faster phase transitions
  /// - Director dialogue adapts tone based on tier
  static BossBehaviorModifiers getBossBehaviorModifiers(int tier) {
    return BossBehaviorModifiers(
      resistanceBonus: tier >= 3 ? 0.1 : 0.0, // +10% resistance
      phaseTransitionSpeedup: tier >= 4 ? 1 : 0, // Faster by 1 turn
      dialogueTone: _getDialogueTone(tier),
    );
  }

  static String _getDialogueTone(int tier) {
    if (tier >= 4) return 'intense';
    if (tier >= 2) return 'challenging';
    return 'standard';
  }

  // ==================== DEBUG / DISPLAY ====================

  /// Gets a debug table showing difficulty scaling.
  static String getDifficultyTable() {
    final buffer = StringBuffer();
    buffer.writeln('=== META DIFFICULTY SCALING (Phase 7.9) ===');
    buffer.writeln('Tier | HP   | ATK  | DEF  | SPD  | Elite+ | Boss+');
    buffer.writeln('-----|------|------|------|------|--------|------');

    for (int tier = 0; tier <= maxTierAct1; tier++) {
      final mods = getModifiers(tier);
      buffer.writeln(
        '  ${tier.toString().padLeft(2)} | ${_pct(mods.hpMultiplier)} | ${_pct(mods.attackMultiplier)} | ${_pct(mods.defenseMultiplier)} | ${_pct(mods.speedMultiplier)} |   ${mods.eliteExtraPassives}    |   ${mods.bossExtraPhases}',
      );
    }

    return buffer.toString();
  }

  static String _pct(double val) {
    final pct = ((val - 1.0) * 100).round();
    return '+${pct.toString().padLeft(2)}%';
  }

  /// Gets examples of tier calculation.
  static String getTierExamples() {
    final buffer = StringBuffer();
    buffer.writeln('=== TIER CALCULATION EXAMPLES ===');

    final examples = [
      {'runs': 0, 'nodes': 0},
      {'runs': 2, 'nodes': 0},
      {'runs': 4, 'nodes': 8},
      {'runs': 6, 'nodes': 16},
      {'runs': 8, 'nodes': 24},
      {'runs': 10, 'nodes': 32},
    ];

    for (final ex in examples) {
      final tier = calculateMetaDifficultyTier(
        successfulRuns: ex['runs']!,
        skillTreeDepth: ex['nodes']!,
      );
      buffer.writeln(
        '  ${ex['runs']} wins + ${ex['nodes']} nodes = Tier $tier',
      );
    }

    return buffer.toString();
  }
}

/// Stat modifiers from meta difficulty.
class MetaDifficultyModifiers {
  final int tier;
  final double hpMultiplier;
  final double attackMultiplier;
  final double defenseMultiplier;
  final double speedMultiplier;
  final int eliteExtraPassives;
  final int bossExtraPhases;

  const MetaDifficultyModifiers({
    required this.tier,
    required this.hpMultiplier,
    required this.attackMultiplier,
    required this.defenseMultiplier,
    required this.speedMultiplier,
    required this.eliteExtraPassives,
    required this.bossExtraPhases,
  });

  /// Whether any scaling is applied.
  bool get hasScaling => tier > 0;

  /// Summary string for display.
  String get summary {
    if (!hasScaling) return 'No meta difficulty scaling';

    return 'Tier $tier: HP +${((hpMultiplier - 1) * 100).round()}%, '
        'ATK +${((attackMultiplier - 1) * 100).round()}%, '
        'DEF +${((defenseMultiplier - 1) * 100).round()}%, '
        'SPD +${((speedMultiplier - 1) * 100).round()}%';
  }

  @override
  String toString() => summary;
}

/// Elite behavior modifiers from meta difficulty.
class EliteBehaviorModifiers {
  final double spellPriorityBonus;
  final double statusEffectUptimeBonus;
  final int passiveActivationBonus;

  const EliteBehaviorModifiers({
    required this.spellPriorityBonus,
    required this.statusEffectUptimeBonus,
    required this.passiveActivationBonus,
  });
}

/// Boss behavior modifiers from meta difficulty.
class BossBehaviorModifiers {
  final double resistanceBonus;
  final int phaseTransitionSpeedup;
  final String dialogueTone;

  const BossBehaviorModifiers({
    required this.resistanceBonus,
    required this.phaseTransitionSpeedup,
    required this.dialogueTone,
  });
}
