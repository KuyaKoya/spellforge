import 'effect.dart';
import 'element.dart';
import 'enemy.dart';

/// Types of combat events that passives can listen to.
enum CombatEventType {
  /// Fired when an enemy takes damage.
  damageTaken,

  /// Fired when an enemy deals damage.
  damageDealt,

  /// Fired when a status effect is applied to an enemy.
  statusApplied,

  /// Fired when a status effect is applied to the player.
  statusAppliedToPlayer,

  /// Fired at the start of an enemy's turn.
  turnStart,

  /// Fired at the end of an enemy's turn.
  turnEnd,

  /// Fired when armor is broken (reduced to 0).
  armorBroken,

  /// Fired when a spell is cast against this enemy.
  spellCastAgainst,

  /// Fired when a burn tick occurs.
  burnTick,

  /// Fired when an enemy gains armor.
  armorGained,

  /// Fired when a consecutive action is taken.
  consecutiveAction,

  /// Fired when the player casts any spell.
  playerSpellCast,

  /// Fired at the start of battle.
  battleStart,
}

/// Represents a combat event that can trigger passives.
class CombatEvent {
  final CombatEventType type;
  // ... (rest of class)

  /// The enemy that owns the passive being triggered.
  final Enemy? source;

  /// The target of the event (if applicable).
  final dynamic target;

  /// The element of the attack/spell (if applicable).
  final Element? element;

  /// The damage amount (if applicable).
  final int? damage;

  /// The effect type (if applicable).
  final EffectType? effectType;

  /// The current turn number.
  final int turnNumber;

  /// Additional context data.
  final Map<String, dynamic> context;

  CombatEvent({
    required this.type,
    this.source,
    this.target,
    this.element,
    this.damage,
    this.effectType,
    this.turnNumber = 0,
    this.context = const {},
  });

  /// Factory for damage taken events.
  factory CombatEvent.damageTaken({
    required Enemy source,
    required int damage,
    required Element element,
    int turnNumber = 0,
  }) {
    return CombatEvent(
      type: CombatEventType.damageTaken,
      source: source,
      damage: damage,
      element: element,
      turnNumber: turnNumber,
    );
  }

  /// Factory for status applied events.
  factory CombatEvent.statusApplied({
    required Enemy source,
    required EffectType effectType,
    int turnNumber = 0,
  }) {
    return CombatEvent(
      type: CombatEventType.statusApplied,
      source: source,
      effectType: effectType,
      turnNumber: turnNumber,
    );
  }

  /// Factory for turn start events.
  factory CombatEvent.turnStart({
    required Enemy source,
    required int turnNumber,
  }) {
    return CombatEvent(
      type: CombatEventType.turnStart,
      source: source,
      turnNumber: turnNumber,
    );
  }

  /// Factory for armor broken events.
  factory CombatEvent.armorBroken({required Enemy source, int turnNumber = 0}) {
    return CombatEvent(
      type: CombatEventType.armorBroken,
      source: source,
      turnNumber: turnNumber,
    );
  }

  /// Factory for burn tick events.
  factory CombatEvent.burnTick({
    required Enemy source,
    required int damage,
    int turnNumber = 0,
  }) {
    return CombatEvent(
      type: CombatEventType.burnTick,
      source: source,
      damage: damage,
      turnNumber: turnNumber,
    );
  }

  /// Factory for armor gained events.
  factory CombatEvent.armorGained({
    required Enemy source,
    required int amount,
    int turnNumber = 0,
  }) {
    return CombatEvent(
      type: CombatEventType.armorGained,
      source: source,
      damage: amount,
      turnNumber: turnNumber,
    );
  }

  /// Factory for spell cast against events.
  factory CombatEvent.spellCastAgainst({
    required Enemy source,
    required Element element,
    required int damage,
    int turnNumber = 0,
    bool isFirstSpellThisTurn = false,
  }) {
    return CombatEvent(
      type: CombatEventType.spellCastAgainst,
      source: source,
      element: element,
      damage: damage,
      turnNumber: turnNumber,
      context: {'isFirstSpellThisTurn': isFirstSpellThisTurn},
    );
  }

  /// Factory for battle start events.
  factory CombatEvent.battleStart(Enemy source) {
    return CombatEvent(type: CombatEventType.battleStart, source: source);
  }

  /// Factory for turn end events.
  factory CombatEvent.turnEnd({
    required Enemy source,
    required int turnNumber,
  }) {
    return CombatEvent(
      type: CombatEventType.turnEnd,
      source: source,
      turnNumber: turnNumber,
    );
  }

  /// Factory for damage dealt events (enemy attacking player).
  /// Used for passives like Permafrost Edge and Cold Precision.
  factory CombatEvent.damageDealt({
    required Enemy source,
    required int damage,
    int turnNumber = 0,
    bool targetSlowed = false,
    bool targetBelowHalf = false,
  }) {
    return CombatEvent(
      type: CombatEventType.damageDealt,
      source: source,
      damage: damage,
      turnNumber: turnNumber,
      context: {
        'targetSlowed': targetSlowed,
        'targetBelowHalf': targetBelowHalf,
      },
    );
  }

  @override
  String toString() =>
      'CombatEvent($type, source: ${source?.name}, element: $element, damage: $damage)';
}

/// Result of a passive trigger.
class PassiveResult {
  final String? logMessage;
  final int? damageModifier;
  final int? armorGain;
  final bool? preventAction;
  final EffectType? statusToApply;
  final int? statusValue;
  final int? statusDuration;
  final bool actAgain;
  final int priorityBonus;

  PassiveResult({
    this.logMessage,
    this.damageModifier,
    this.armorGain,
    this.preventAction,
    this.statusToApply,
    this.statusValue,
    this.statusDuration,
    this.actAgain = false,
    this.priorityBonus = 0,
  });

  /// Empty result (no effect).
  static PassiveResult none() => PassiveResult();

  /// Whether this result has any effect.
  bool get hasEffect =>
      logMessage != null ||
      damageModifier != null ||
      armorGain != null ||
      preventAction != null ||
      statusToApply != null ||
      actAgain ||
      priorityBonus != 0;
}
