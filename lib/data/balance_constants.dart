// Balance Framework Constants.
//
// Phase 7 - B1-B6: Balance Framework
//
// This file contains all balance-critical values for Spellforge.
// Centralizing these values ensures:
// - Easy tuning during development
// - Consistent scaling across systems
// - Clear documentation of balance philosophy
//
// BALANCE PRINCIPLES (B1):
// 1. No Perfect Spell - every spell has trade-offs
// 2. Mana Is Strategic - tight early, flexible mid-fight
// 3. Predictable Damage - variance from effects/behavior, not RNG

/// Player stat scaling per level.
class PlayerBalance {
  /// HP gain per level (B2: 8-12 range, using 10 midpoint).
  static const int hpPerLevel = 10;

  /// MP gain per level (B2: 2-3 range, using 2).
  static const int mpPerLevel = 2;

  /// Starting HP at level 1.
  static const int baseHP = 50;

  /// Starting MP at level 1.
  static const int baseMP = 10;

  /// Maximum spell loadout size.
  static const int maxSpellLoadout = 4;

  /// Actions per turn at level 1.
  static const int baseActionsPerTurn = 1;

  /// Levels required to gain an extra action.
  static const int levelsPerExtraAction = 3;
}

/// Enemy scaling relative to player.
class EnemyBalance {
  /// Enemy HP as multiplier of player HP (B2: 0.8-1.2 range).
  static const double hpRatioMin = 0.8;
  static const double hpRatioMax = 1.2;

  /// Enemy damage as percentage of player HP per turn (B2: 15-25%).
  static const double damagePerTurnMin = 0.15;
  static const double damagePerTurnMax = 0.25;
  static const double damagePerTurnMid = 0.20;

  /// Elite enemy multipliers.
  static const double eliteHPMultiplier = 1.5;
  static const double eliteDamageMultiplier = 1.3;

  /// Boss multipliers.
  static const double bossHPMultiplier = 2.0;
  static const double bossDamageMultiplier = 1.5;
}

/// Spell cost and effect tiers (B3).
enum SpellTier {
  /// Basic: Low cost, low reward, setup spells.
  basic(manaCostMin: 1, manaCostMax: 2, damageBase: 8, hasEffect: false),

  /// Core: Medium cost, reliable damage with single status.
  core(manaCostMin: 3, manaCostMax: 4, damageBase: 18, hasEffect: true),

  /// Heavy: High cost, high damage, conditional effects.
  heavy(manaCostMin: 5, manaCostMax: 6, damageBase: 30, hasEffect: true),

  /// Utility: Control spells, no direct damage.
  utility(manaCostMin: 2, manaCostMax: 4, damageBase: 0, hasEffect: true);

  final int manaCostMin;
  final int manaCostMax;
  final int damageBase;
  final bool hasEffect;

  const SpellTier({
    required this.manaCostMin,
    required this.manaCostMax,
    required this.damageBase,
    required this.hasEffect,
  });

  /// Returns typical mana cost for this tier.
  int get typicalCost => (manaCostMin + manaCostMax) ~/ 2;
}

/// Status effect balance values (B4).
class StatusBalance {
  // ==================== BURN ====================
  /// Burn damage per turn (B4: 2-3 base).
  static const int burnDamagePerTurn = 2;

  /// Burn stacks slowly - max stacks.
  static const int burnMaxStacks = 3;

  /// Burn is best against high HP enemies.
  static const String burnStrategy = 'Best against high HP enemies';

  // ==================== SLOW ====================
  /// Slow action reduction (B4).
  static const int slowActionReduction = 1;

  /// Slow does no direct damage.
  static const int slowDamage = 0;

  /// Slow enables control playstyles.
  static const String slowStrategy = 'Enables control playstyles';

  // ==================== WEAKEN ====================
  /// Weaken damage reduction percentage (B4).
  static const int weakenDamageReductionPercent = 25;

  /// Weaken is strong early, weaker late.
  static const String weakenStrategy = 'Strong early, weaker late';

  // ==================== ARMOR/SHIELD ====================
  /// Base armor value per application.
  static const int armorBaseValue = 5;
}

/// Spell tier validation rules.
class SpellRules {
  /// Heavy spells must never be spammable.
  /// Enforce: cost >= 5, cooldown or condition required.
  static bool isHeavySpellValid(int manaCost, bool hasCondition) {
    return manaCost >= SpellTier.heavy.manaCostMin && hasCondition;
  }

  /// Utility spells must always be situationally strong.
  /// Enforce: must have at least one status effect.
  static bool isUtilitySpellValid(bool hasEffect) {
    return hasEffect;
  }

  /// Every spell must have a strength, weakness, and a reason not to cast.
  static String getSpellTradeoffs(SpellTier tier) {
    switch (tier) {
      case SpellTier.basic:
        return 'Strength: Cheap. Weakness: Low impact. Skip: Better options exist.';
      case SpellTier.core:
        return 'Strength: Reliable. Weakness: Not spectacular. Skip: Need burst/utility.';
      case SpellTier.heavy:
        return 'Strength: Big damage. Weakness: Expensive. Skip: Low mana / overkill.';
      case SpellTier.utility:
        return 'Strength: Control. Weakness: No damage. Skip: Need to kill fast.';
    }
  }
}

/// Enemy design rules (B5).
class EnemyDesignRules {
  /// Every enemy must teach one mechanic.
  static const String ruleTeach = 'Each enemy teaches one mechanic';

  /// Every enemy must punish one mistake.
  static const String rulePunish = 'Each enemy punishes one mistake';

  /// Every enemy must be weak to one strategy.
  static const String ruleWeakness = 'Each enemy is weak to one strategy';

  /// Gatekeeper boss rules.
  static const String bossRule1 = 'Test composition, not damage';
  static const String bossRule2 = 'Require adaptation, not grinding';
}

/// Run failure philosophy (B6).
class FailurePhilosophy {
  /// Valid reasons for run ending.
  static const List<String> validDeathReasons = [
    'Player misunderstood risk',
    'Player overcommitted resources',
    'Player ignored signals',
  ];

  /// Invalid reasons for run ending (should not happen).
  static const List<String> invalidDeathReasons = [
    'Random unavoidable spike',
    'Hidden mechanic',
    'UI ambiguity',
  ];

  /// Determines if a death was "fair" based on cause.
  static bool isDeathFair(String cause) {
    final unfairCauses = [
      'random_spike',
      'hidden_mechanic',
      'ui_confusion',
      'impossible_odds',
    ];
    return !unfairCauses.contains(cause.toLowerCase());
  }
}

/// Experience and progression scaling.
class ProgressionBalance {
  /// Experience required for each level.
  static int expForLevel(int level) {
    if (level <= 0) return 0;
    if (level == 1) return 10;
    if (level == 2) return 15;
    if (level == 3) return 22;
    if (level == 4) return 30;
    if (level == 5) return 40;
    if (level == 6) return 52;
    if (level == 7) return 66;
    if (level == 8) return 82;
    if (level == 9) return 100;
    return 100 + (level - 9) * 25;
  }

  /// Experience reward for defeating an enemy.
  static int expForEnemy(int enemyLevel, bool isElite) {
    final baseExp = 5 + (enemyLevel * 2);
    return isElite ? baseExp * 2 : baseExp;
  }
}

/// Combat pacing guidelines.
class CombatPacing {
  /// Target combat duration in turns.
  static const int targetTurnsMin = 4;
  static const int targetTurnsMax = 8;

  /// Target player HP loss percentage per combat.
  static const double targetHPLossMin = 0.15; // 15%
  static const double targetHPLossMax = 0.40; // 40%

  /// If combat exceeds this many turns, it may be too long.
  static const int combatTooLongThreshold = 12;

  /// If player loses more than this HP %, combat may be too punishing.
  static const double combatTooPunishingThreshold = 0.60; // 60%
}
