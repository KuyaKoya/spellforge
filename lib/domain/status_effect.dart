/// Phase 7.2 — STATUS EFFECT SYSTEM
///
/// Implements a deterministic, extensible status effect system with:
/// - Common interface with lifecycle hooks
/// - Turn phase integration (Start, Action, End, Cleanup)
/// - Core effects: Burn, Slow, Shield, Weaken

/// The category of a status effect.
enum StatusEffectCategory {
  buff,
  debuff;

  String get displayName => name[0].toUpperCase() + name.substring(1);
}

/// The phase during which a status effect triggers.
enum StatusPhase {
  turnStart, // Before action selection
  actionPhase, // During actions (damage reduction, etc.)
  turnEnd, // After all actions complete
  onDamage, // When damage is taken (shields)
}

/// Source of the status effect.
enum StatusSource { spell, enemy, relic, environment }

/// Core status effect types.
enum StatusEffectType {
  burn,
  slow,
  shield,
  weaken,
  regen,
  vulnerable,
  delay,
  armor,
  haste;

  String get displayName {
    switch (this) {
      case StatusEffectType.burn:
        return 'Burn';
      case StatusEffectType.slow:
        return 'Slow';
      case StatusEffectType.shield:
        return 'Shield';
      case StatusEffectType.weaken:
        return 'Weaken';
      case StatusEffectType.regen:
        return 'Regen';
      case StatusEffectType.vulnerable:
        return 'Vulnerable';
      case StatusEffectType.delay:
        return 'Delay';
      case StatusEffectType.armor:
        return 'Armor';
      case StatusEffectType.haste:
        return 'Haste';
    }
  }

  String get icon {
    switch (this) {
      case StatusEffectType.burn:
        return '🔥';
      case StatusEffectType.slow:
        return '🐌';
      case StatusEffectType.shield:
        return '🛡️';
      case StatusEffectType.weaken:
        return '💔';
      case StatusEffectType.regen:
        return '💚';
      case StatusEffectType.vulnerable:
        return '💥';
      case StatusEffectType.delay:
        return '⏸️';
      case StatusEffectType.armor:
        return '🛡️';
      case StatusEffectType.haste:
        return '⚡';
    }
  }

  StatusEffectCategory get category {
    switch (this) {
      case StatusEffectType.burn:
      case StatusEffectType.slow:
      case StatusEffectType.weaken:
      case StatusEffectType.vulnerable:
      case StatusEffectType.delay:
        return StatusEffectCategory.debuff;
      case StatusEffectType.shield:
      case StatusEffectType.regen:
      case StatusEffectType.armor:
      case StatusEffectType.haste:
        return StatusEffectCategory.buff;
    }
  }

  StatusPhase get triggerPhase {
    switch (this) {
      case StatusEffectType.burn:
      case StatusEffectType.regen:
        return StatusPhase.turnStart;
      case StatusEffectType.slow:
      case StatusEffectType.haste:
      case StatusEffectType.delay:
        return StatusPhase.turnStart;
      case StatusEffectType.weaken:
      case StatusEffectType.vulnerable:
        return StatusPhase.actionPhase;
      case StatusEffectType.shield:
      case StatusEffectType.armor:
        return StatusPhase.onDamage;
    }
  }

  /// Whether this effect type can stack.
  bool get canStack {
    switch (this) {
      case StatusEffectType.burn:
        return true; // Stacks up to 3
      case StatusEffectType.slow:
        return false; // Binary
      case StatusEffectType.shield:
        return true; // Additive
      case StatusEffectType.weaken:
        return false; // Duration refresh
      case StatusEffectType.regen:
        return true;
      case StatusEffectType.vulnerable:
        return false;
      case StatusEffectType.delay:
        return false;
      case StatusEffectType.armor:
        return true;
      case StatusEffectType.haste:
        return false;
    }
  }

  /// Maximum stacks for this effect type.
  int get maxStacks {
    switch (this) {
      case StatusEffectType.burn:
        return 3;
      case StatusEffectType.shield:
        return 999; // Effectively unlimited
      case StatusEffectType.regen:
        return 3;
      case StatusEffectType.armor:
        return 999;
      default:
        return 1;
    }
  }
}

/// An active status effect on a combatant.
///
/// Phase 7.2 compliant:
/// - Lifecycle hooks: onApply, onTurnStart, onTurnEnd, onExpire
/// - No direct UI mutation
/// - All effects mutate combat state only
class StatusEffect {
  final String id;
  final StatusEffectType type;
  final StatusSource source;
  final String? sourceId; // Spell ID, enemy ID, etc.

  int duration;
  int stacks;
  int value; // Damage per stack for burn, shield amount, etc.

  bool _hasExpired = false;

  StatusEffect({
    required this.id,
    required this.type,
    required this.value,
    this.duration = 1,
    this.stacks = 1,
    this.source = StatusSource.spell,
    this.sourceId,
  });

  /// Factory for creating a Burn effect.
  /// C1 Spec: 2-3 damage per stack, max 3 stacks.
  factory StatusEffect.burn({
    required int duration,
    int stacks = 1,
    int damagePerStack = 2,
    String? sourceId,
  }) {
    return StatusEffect(
      id: 'burn_${DateTime.now().millisecondsSinceEpoch}',
      type: StatusEffectType.burn,
      value: damagePerStack,
      duration: duration,
      stacks: stacks.clamp(1, 3),
      source: StatusSource.spell,
      sourceId: sourceId,
    );
  }

  /// Factory for creating a Slow effect.
  /// C2 Spec: Binary effect, no stacking.
  factory StatusEffect.slow({required int duration, String? sourceId}) {
    return StatusEffect(
      id: 'slow_${DateTime.now().millisecondsSinceEpoch}',
      type: StatusEffectType.slow,
      value: 1, // Priority modifier
      duration: duration,
      stacks: 1,
      source: StatusSource.spell,
      sourceId: sourceId,
    );
  }

  /// Factory for creating a Shield effect.
  /// C3 Spec: Absorbs damage, no duration, expires when depleted.
  factory StatusEffect.shield({required int shieldValue, String? sourceId}) {
    return StatusEffect(
      id: 'shield_${DateTime.now().millisecondsSinceEpoch}',
      type: StatusEffectType.shield,
      value: shieldValue,
      duration: 999, // Doesn't expire by time
      stacks: 1,
      source: StatusSource.spell,
      sourceId: sourceId,
    );
  }

  /// Factory for creating a Weaken effect.
  /// D Spec: Reduces outgoing damage by %.
  factory StatusEffect.weaken({
    required int duration,
    int percentage = 15,
    String? sourceId,
  }) {
    return StatusEffect(
      id: 'weaken_${DateTime.now().millisecondsSinceEpoch}',
      type: StatusEffectType.weaken,
      value: percentage,
      duration: duration,
      stacks: 1,
      source: StatusSource.spell,
      sourceId: sourceId,
    );
  }

  /// Factory for creating a Regen effect.
  factory StatusEffect.regen({
    required int duration,
    int healPerTurn = 3,
    String? sourceId,
  }) {
    return StatusEffect(
      id: 'regen_${DateTime.now().millisecondsSinceEpoch}',
      type: StatusEffectType.regen,
      value: healPerTurn,
      duration: duration,
      stacks: 1,
      source: StatusSource.spell,
      sourceId: sourceId,
    );
  }

  /// Whether this effect has expired.
  bool get hasExpired => _hasExpired || duration <= 0;

  /// Whether this effect is still active.
  bool get isActive => !hasExpired;

  /// The category (buff/debuff).
  StatusEffectCategory get category => type.category;

  /// The trigger phase.
  StatusPhase get triggerPhase => type.triggerPhase;

  /// Display name for UI.
  String get displayName => type.displayName;

  /// Icon for UI.
  String get icon => type.icon;

  /// Total value considering stacks.
  int get totalValue => value * stacks;

  // ==================== LIFECYCLE HOOKS ====================

  /// Called when effect is first applied.
  /// Returns a log message or null.
  String? onApply(String targetName) {
    switch (type) {
      case StatusEffectType.burn:
        return '$targetName is burning! ($stacks stacks)';
      case StatusEffectType.slow:
        return '$targetName is slowed!';
      case StatusEffectType.shield:
        return '$targetName gained $value shield!';
      case StatusEffectType.weaken:
        return '$targetName is weakened! (-$value% damage)';
      case StatusEffectType.regen:
        return '$targetName has regeneration!';
      case StatusEffectType.vulnerable:
        return '$targetName is vulnerable!';
      default:
        return null;
    }
  }

  /// Called at turn start. Returns (damage, log message) or null.
  TurnEffectResult? onTurnStart(String targetName) {
    if (triggerPhase != StatusPhase.turnStart) return null;

    switch (type) {
      case StatusEffectType.burn:
        final damage = value * stacks;
        return TurnEffectResult(
          damage: damage,
          message: '$targetName burns for $damage damage! (${stacks}x)',
        );
      case StatusEffectType.regen:
        final heal = value * stacks;
        return TurnEffectResult(
          healing: heal,
          message: '$targetName regenerates $heal HP!',
        );
      default:
        return null;
    }
  }

  /// Called at turn end. Decrements duration.
  /// Returns true if effect should continue, false if expired.
  bool onTurnEnd() {
    // Shield doesn't expire by time
    if (type == StatusEffectType.shield) return true;

    duration--;
    if (duration <= 0) {
      _hasExpired = true;
      return false;
    }
    return true;
  }

  /// Called when effect expires.
  String? onExpire(String targetName) {
    return '${type.displayName} wore off from $targetName';
  }

  /// Absorbs damage (for shield effects).
  /// Returns (absorbed, remaining).
  DamageAbsorption absorbDamage(int incomingDamage) {
    if (type != StatusEffectType.shield && type != StatusEffectType.armor) {
      return DamageAbsorption(absorbed: 0, remaining: incomingDamage);
    }

    final absorbed = incomingDamage.clamp(0, value);
    value -= absorbed;

    if (value <= 0) {
      _hasExpired = true;
    }

    return DamageAbsorption(
      absorbed: absorbed,
      remaining: incomingDamage - absorbed,
    );
  }

  /// Modifies outgoing damage (for weaken effects).
  int modifyOutgoingDamage(int baseDamage) {
    if (type == StatusEffectType.weaken) {
      final reduction = (baseDamage * value / 100).round();
      return (baseDamage - reduction).clamp(0, baseDamage);
    }
    return baseDamage;
  }

  /// Modifies incoming damage (for vulnerable effects).
  int modifyIncomingDamage(int baseDamage) {
    if (type == StatusEffectType.vulnerable) {
      final increase = (baseDamage * value / 100).round();
      return baseDamage + increase;
    }
    return baseDamage;
  }

  /// Adds stacks (for stackable effects).
  void addStacks(int amount) {
    if (!type.canStack) return;
    stacks = (stacks + amount).clamp(1, type.maxStacks);
  }

  /// Refreshes duration.
  void refreshDuration(int newDuration) {
    if (newDuration > duration) {
      duration = newDuration;
    }
  }

  /// Display text for UI.
  String get displayText {
    if (type == StatusEffectType.shield) {
      return '$displayName: $value';
    }
    if (stacks > 1) {
      return '$displayName x$stacks ($duration turns)';
    }
    return '$displayName ($duration turns)';
  }

  @override
  String toString() => displayText;
}

/// Result of a turn-based status effect.
class TurnEffectResult {
  final int damage;
  final int healing;
  final String message;

  TurnEffectResult({this.damage = 0, this.healing = 0, required this.message});
}

/// Result of damage absorption.
class DamageAbsorption {
  final int absorbed;
  final int remaining;

  DamageAbsorption({required this.absorbed, required this.remaining});
}
