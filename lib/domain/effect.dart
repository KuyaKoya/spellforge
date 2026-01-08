/// Types of effects that can be applied by spells.
///
/// Pokémon-style status effects:
/// - [burn]: DOT + 10% reduced attack
/// - [poison]: DOT only (no attack reduction)
/// - [slow]: Speed reduction (percentage)
/// - [haste]: Speed increase (percentage)
/// - [sleep]: Skip turn (wakes on damage)
/// - [freeze]: Cannot act (thaws over time)
/// - [shield]: Temporary damage reduction (percentage)
enum EffectType {
  damage,
  burn,
  poison, // DOT without attack reduction
  slow,
  haste, // Speed increase
  weaken,
  armor,
  shield, // Damage reduction percentage
  sleep, // Skip turn
  freeze, // Cannot act
  actionGain,
  delay;

  String get displayName {
    switch (this) {
      case EffectType.damage:
        return 'Damage';
      case EffectType.burn:
        return 'Burn';
      case EffectType.poison:
        return 'Poison';
      case EffectType.slow:
        return 'Slow';
      case EffectType.haste:
        return 'Haste';
      case EffectType.weaken:
        return 'Weaken';
      case EffectType.armor:
        return 'Armor';
      case EffectType.shield:
        return 'Shield';
      case EffectType.sleep:
        return 'Sleep';
      case EffectType.freeze:
        return 'Freeze';
      case EffectType.actionGain:
        return 'Action Gain';
      case EffectType.delay:
        return 'Delay';
    }
  }
}

/// Target rule for effect application.
enum TargetRule {
  single, // Single target
  all, // All enemies
  self, // Self-targeting (buffs)
  random, // Random target
}

/// Represents a single effect that a spell can apply.
/// Effects are resolved in order and are deterministic.
class Effect {
  final EffectType type;
  final int value;
  final int duration; // 0 for instant effects, > 0 for status effects
  final TargetRule targetRule;

  const Effect({
    required this.type,
    required this.value,
    this.duration = 0,
    this.targetRule = TargetRule.single,
  });

  /// Creates a copy with modified values.
  Effect copyWith({
    EffectType? type,
    int? value,
    int? duration,
    TargetRule? targetRule,
  }) {
    return Effect(
      type: type ?? this.type,
      value: value ?? this.value,
      duration: duration ?? this.duration,
      targetRule: targetRule ?? this.targetRule,
    );
  }

  /// Whether this effect lasts over multiple turns.
  bool get isStatusEffect => duration > 0;

  /// Human-readable description of this effect.
  String get description {
    final durationText = duration > 0 ? ' for $duration turn(s)' : '';

    switch (type) {
      case EffectType.damage:
        return 'Deal $value damage';
      case EffectType.burn:
        return 'Apply Burn ($value damage/turn, -10% ATK)$durationText';
      case EffectType.poison:
        return 'Apply Poison ($value damage/turn)$durationText';
      case EffectType.slow:
        return 'Apply Slow (-$value% speed)$durationText';
      case EffectType.haste:
        return 'Apply Haste (+$value% speed)$durationText';
      case EffectType.weaken:
        return 'Apply Weaken (-$value% damage)$durationText';
      case EffectType.armor:
        return 'Gain $value Armor$durationText';
      case EffectType.shield:
        return 'Apply Shield (-$value% damage taken)$durationText';
      case EffectType.sleep:
        return 'Apply Sleep (skip turn, wakes on damage)$durationText';
      case EffectType.freeze:
        return 'Apply Freeze (cannot act)$durationText';
      case EffectType.actionGain:
        return 'Gain $value action(s)';
      case EffectType.delay:
        return 'Delay target for $value turn(s)';
    }
  }

  @override
  String toString() => description;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'value': value,
    'duration': duration,
    'targetRule': targetRule.name,
  };

  factory Effect.fromJson(Map<String, dynamic> json) => Effect(
    type: EffectType.values.firstWhere((e) => e.name == json['type']),
    value: json['value'] as int,
    duration: json['duration'] as int? ?? 0,
    targetRule: TargetRule.values.firstWhere(
      (e) => e.name == json['targetRule'],
      orElse: () => TargetRule.single,
    ),
  );
}

/// Represents an active status effect on an entity.
class ActiveStatusEffect {
  final EffectType type;
  int value;
  int remainingDuration;

  ActiveStatusEffect({
    required this.type,
    required this.value,
    required this.remainingDuration,
  });

  /// Tick down the duration. Returns true if effect is still active.
  bool tick() {
    remainingDuration--;
    return remainingDuration > 0;
  }

  String get displayText =>
      '${type.displayName} ($value) - $remainingDuration turn(s)';
}
