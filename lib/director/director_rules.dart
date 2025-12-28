import 'director_state.dart';
import 'director_logger.dart';
import 'pressure_metrics.dart';
import '../ascension/ascension.dart';

/// Probability adjustments made by the Director.
class DirectorAdjustments {
  /// Elite node appearance modifier (-0.5 to 0.5)
  final double eliteChanceModifier;

  /// Rest/Shrine node appearance modifier (-0.5 to 0.5)
  final double restChanceModifier;

  /// Combat difficulty modifier (0.5 to 1.5)
  final double combatDifficultyModifier;

  /// Reward tier modifier (-1 to 1)
  final int rewardTierModifier;

  /// Enemy synergy modifier (0.0 to 1.0)
  final double enemySynergyModifier;

  const DirectorAdjustments({
    this.eliteChanceModifier = 0.0,
    this.restChanceModifier = 0.0,
    this.combatDifficultyModifier = 1.0,
    this.rewardTierModifier = 0,
    this.enemySynergyModifier = 0.5,
  });

  /// No adjustments (neutral state).
  static const neutral = DirectorAdjustments();

  /// Aggressive adjustments (player dominating).
  static const aggressive = DirectorAdjustments(
    eliteChanceModifier: 0.15,
    restChanceModifier: -0.1,
    combatDifficultyModifier: 1.15,
    rewardTierModifier: 0,
    enemySynergyModifier: 0.7,
  );

  /// Merciful adjustments (player struggling).
  static const merciful = DirectorAdjustments(
    eliteChanceModifier: -0.15,
    restChanceModifier: 0.2,
    combatDifficultyModifier: 0.85,
    rewardTierModifier: 1,
    enemySynergyModifier: 0.3,
  );

  /// Creates adjustments for a given pressure state.
  factory DirectorAdjustments.forState(DirectorPressureState state) {
    switch (state) {
      case DirectorPressureState.neutral:
        return neutral;
      case DirectorPressureState.aggressive:
        return aggressive;
      case DirectorPressureState.merciful:
        return merciful;
    }
  }

  /// Applies ascension modifiers to adjustments.
  DirectorAdjustments withAscension(Ascension ascension) {
    return DirectorAdjustments(
      eliteChanceModifier: eliteChanceModifier + ascension.eliteChanceBonus,
      restChanceModifier: restChanceModifier - ascension.restChancePenalty,
      combatDifficultyModifier:
          combatDifficultyModifier * ascension.combatDifficultyMultiplier,
      rewardTierModifier: rewardTierModifier + ascension.rewardTierPenalty,
      enemySynergyModifier: (enemySynergyModifier + ascension.enemySynergyBonus)
          .clamp(0.0, 1.0),
    );
  }

  @override
  String toString() {
    return '''DirectorAdjustments(
  Elite: ${eliteChanceModifier >= 0 ? '+' : ''}${(eliteChanceModifier * 100).toStringAsFixed(0)}%
  Rest: ${restChanceModifier >= 0 ? '+' : ''}${(restChanceModifier * 100).toStringAsFixed(0)}%
  Combat: ${(combatDifficultyModifier * 100).toStringAsFixed(0)}%
  Reward Tier: ${rewardTierModifier >= 0 ? '+' : ''}$rewardTierModifier
  Enemy Synergy: ${(enemySynergyModifier * 100).toStringAsFixed(0)}%
)''';
  }
}

/// Rule set that governs Director behavior.
class DirectorRuleSet {
  /// Evaluates metrics and returns the appropriate pressure state.
  static DirectorPressureState evaluateState({
    required PressureMetrics metrics,
    required DirectorState currentState,
    required int ascensionLevel,
  }) {
    // Calculate pressure score
    final score = metrics.calculatePressureScore();

    // Apply ascension modifiers to thresholds
    // Higher ascension = harder to trigger mercy, easier to trigger aggression
    final ascensionModifier = ascensionLevel * 5;
    final aggressiveThreshold =
        DirectorState.aggressiveThreshold - ascensionModifier;
    final mercifulThreshold =
        DirectorState.mercifulThreshold + ascensionModifier;

    // Check if state should change
    if (!currentState.canChangeState) {
      return currentState.pressureState;
    }

    // Evaluate transitions
    if (score >= aggressiveThreshold &&
        currentState.pressureState != DirectorPressureState.aggressive) {
      return DirectorPressureState.aggressive;
    }

    if (score <= mercifulThreshold &&
        currentState.pressureState != DirectorPressureState.merciful) {
      return DirectorPressureState.merciful;
    }

    // Return to neutral if in extreme state but score normalized
    if (currentState.pressureState == DirectorPressureState.aggressive &&
        score < aggressiveThreshold - 15) {
      return DirectorPressureState.neutral;
    }

    if (currentState.pressureState == DirectorPressureState.merciful &&
        score > mercifulThreshold + 15) {
      return DirectorPressureState.neutral;
    }

    return currentState.pressureState;
  }

  /// Gets reason codes for a state transition.
  static List<DirectorReasonCode> getReasonCodes(PressureMetrics metrics) {
    final reasons = <DirectorReasonCode>[];

    // HP reasons
    if (metrics.hpPercentage > 0.9) {
      reasons.add(DirectorReasonCode.highHp);
    } else if (metrics.hpPercentage < 0.4) {
      reasons.add(DirectorReasonCode.lowHp);
    }

    // Combat efficiency reasons
    if (metrics.avgTurnsToClear < 2.5) {
      reasons.add(DirectorReasonCode.fastClears);
    } else if (metrics.avgTurnsToClear > 5.0) {
      reasons.add(DirectorReasonCode.slowClears);
    }

    // Damage reasons
    if (metrics.avgDamagePerCombat < 5) {
      reasons.add(DirectorReasonCode.lightDamage);
    } else if (metrics.avgDamagePerCombat > 20) {
      reasons.add(DirectorReasonCode.heavyDamage);
    }

    // Build reasons
    if (metrics.avgSpellStarLevel >= 2.5 || metrics.relicCount >= 3) {
      reasons.add(DirectorReasonCode.strongBuild);
    } else if (metrics.avgSpellStarLevel < 1.5 && metrics.relicCount == 0) {
      reasons.add(DirectorReasonCode.weakBuild);
    }

    if (reasons.isEmpty) {
      reasons.add(DirectorReasonCode.standardAdjustment);
    }

    return reasons;
  }

  /// Validates that adjustments don't break game rules.
  static DirectorAdjustments validateAdjustments(
    DirectorAdjustments adjustments,
    PressureMetrics metrics,
  ) {
    // Ensure elite chance doesn't go negative or too high
    var eliteMod = adjustments.eliteChanceModifier.clamp(-0.3, 0.3);

    // Ensure rest chance doesn't go negative
    var restMod = adjustments.restChanceModifier.clamp(-0.2, 0.4);

    // Ensure combat difficulty stays reasonable
    var combatMod = adjustments.combatDifficultyModifier.clamp(0.7, 1.4);

    // Don't make rewards too bad
    var rewardMod = adjustments.rewardTierModifier.clamp(-1, 2);

    return DirectorAdjustments(
      eliteChanceModifier: eliteMod,
      restChanceModifier: restMod,
      combatDifficultyModifier: combatMod,
      rewardTierModifier: rewardMod,
      enemySynergyModifier: adjustments.enemySynergyModifier,
    );
  }
}
