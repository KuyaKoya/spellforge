import 'package:flutter/foundation.dart';

import '../domain/combat_event.dart';
import '../domain/enemy.dart';
import '../domain/elite_enemy.dart';
import '../domain/enemy_passive.dart';

/// Phase 7.9.3: Centralized passive resolution with fixed global order.
///
/// Resolution order is:
/// 1. Passives trigger
/// 2. Spell effects
/// 3. Status effects
/// 4. Damage resolution
/// 5. UI update
///
/// This order is global and fixed.
class PassiveResolver {
  /// Singleton instance.
  static final PassiveResolver instance = PassiveResolver._();
  PassiveResolver._();

  /// Track triggered passives this turn for single-trigger enforcement.
  final Map<String, Set<String>> _triggeredThisTurn = {};

  /// Dev-only: Log of all passive triggers.
  final List<PassiveTriggerLog> _triggerLog = [];

  /// Dev-only: Get the trigger log.
  List<PassiveTriggerLog> get triggerLog => List.unmodifiable(_triggerLog);

  /// Clears per-turn tracking. Call at turn start.
  void resetTurn() {
    _triggeredThisTurn.clear();
  }

  /// Clears all tracking. Call at combat start.
  void resetCombat() {
    _triggeredThisTurn.clear();
    _triggerLog.clear();
  }

  /// Resolves all applicable passives for an event.
  ///
  /// Returns a list of PassiveResults in resolution order.
  /// Each passive may only trigger once per valid event.
  List<PassiveResult> resolvePassives({
    required CombatEvent event,
    required List<Enemy> enemies,
  }) {
    final results = <PassiveResult>[];

    for (final enemy in enemies) {
      if (enemy is EliteEnemy) {
        for (final passive in enemy.passives) {
          final result = _tryTriggerPassive(
            passive: passive,
            enemy: enemy,
            event: event,
          );
          if (result != null) {
            results.add(result);
          }
        }
      }
    }

    return results;
  }

  /// Attempts to trigger a single passive.
  ///
  /// Returns the result if triggered, null if blocked.
  PassiveResult? _tryTriggerPassive({
    required EnemyPassive passive,
    required EliteEnemy enemy,
    required CombatEvent event,
  }) {
    // Check if passive listens to this event type
    if (!passive.shouldTrigger(event.type)) {
      return null;
    }

    // Check single-trigger enforcement
    final enemyKey = enemy.id;
    final passiveKey = passive.id;
    final triggeredSet = _triggeredThisTurn.putIfAbsent(enemyKey, () => {});

    // For unique stack rules, check if already triggered this turn
    if (passive.stackRule == StackRule.unique) {
      if (triggeredSet.contains(passiveKey)) {
        _logBlockedTrigger(
          passive,
          enemy,
          event,
          'Already triggered this turn',
        );
        return null;
      }
    }

    // Validate scope
    if (!_validateScope(passive, enemy, event)) {
      _logBlockedTrigger(passive, enemy, event, 'Invalid scope');
      assert(false, 'Passive ${passive.name} executed in invalid scope');
      return null;
    }

    // Execute the passive
    final state = enemy.passiveState;
    final result = passive.effect(event, state);

    // Mark as triggered
    triggeredSet.add(passiveKey);

    // Log the trigger
    _logSuccessfulTrigger(passive, enemy, event, result);

    return result;
  }

  /// Validates that the passive's scope matches the event.
  bool _validateScope(
    EnemyPassive passive,
    EliteEnemy enemy,
    CombatEvent event,
  ) {
    switch (passive.scope) {
      case PassiveScope.self:
        // Self-targeting passives should only affect the owning enemy.
        // For turn-based events (turnStart, turnEnd, battleStart), the source
        // is always the owning enemy, so we allow these implicitly.
        // For damage/action events, we require explicit source matching.
        final selfTargetEvents = [
          CombatEventType.turnStart,
          CombatEventType.turnEnd,
          CombatEventType.battleStart,
        ];
        if (selfTargetEvents.contains(event.type)) {
          // Turn events always target the owning enemy
          return true;
        }
        // For other events, require source match
        return event.source?.id == enemy.id;
      case PassiveScope.enemy:
        // Enemy-targeting passives need a valid target
        return true; // More validation could be added
      case PassiveScope.global:
        // Global passives always apply
        return true;
    }
  }

  /// Dev-only: Logs a successful trigger.
  void _logSuccessfulTrigger(
    EnemyPassive passive,
    EliteEnemy enemy,
    CombatEvent event,
    PassiveResult result,
  ) {
    if (!kDebugMode) return;

    _triggerLog.add(
      PassiveTriggerLog(
        timestamp: DateTime.now(),
        passiveId: passive.id,
        passiveName: passive.name,
        enemyId: enemy.id,
        enemyName: enemy.name,
        eventType: event.type,
        triggered: true,
        hasEffect: result.hasEffect,
        logMessage: result.logMessage,
      ),
    );

    print(
      '[PassiveResolver] TRIGGERED: ${passive.name} on ${enemy.name} '
      '(event: ${event.type}, effect: ${result.hasEffect})',
    );
  }

  /// Dev-only: Logs a blocked trigger.
  void _logBlockedTrigger(
    EnemyPassive passive,
    EliteEnemy enemy,
    CombatEvent event,
    String reason,
  ) {
    if (!kDebugMode) return;

    _triggerLog.add(
      PassiveTriggerLog(
        timestamp: DateTime.now(),
        passiveId: passive.id,
        passiveName: passive.name,
        enemyId: enemy.id,
        enemyName: enemy.name,
        eventType: event.type,
        triggered: false,
        reason: reason,
      ),
    );

    print(
      '[PassiveResolver] BLOCKED: ${passive.name} on ${enemy.name} '
      '(event: ${event.type}, reason: $reason)',
    );
  }

  /// Gets a debug summary of passive triggers this combat.
  String getDebugSummary() {
    final buffer = StringBuffer();
    buffer.writeln('=== PASSIVE RESOLVER LOG ===');
    buffer.writeln('Total triggers: ${_triggerLog.length}');
    buffer.writeln(
      'Successful: ${_triggerLog.where((l) => l.triggered).length}',
    );
    buffer.writeln('Blocked: ${_triggerLog.where((l) => !l.triggered).length}');
    buffer.writeln('');

    for (final log in _triggerLog.take(20)) {
      buffer.writeln(log.toString());
    }

    if (_triggerLog.length > 20) {
      buffer.writeln('... and ${_triggerLog.length - 20} more');
    }

    return buffer.toString();
  }
}

/// Log entry for a passive trigger attempt.
class PassiveTriggerLog {
  final DateTime timestamp;
  final String passiveId;
  final String passiveName;
  final String enemyId;
  final String enemyName;
  final CombatEventType eventType;
  final bool triggered;
  final bool hasEffect;
  final String? logMessage;
  final String? reason;

  PassiveTriggerLog({
    required this.timestamp,
    required this.passiveId,
    required this.passiveName,
    required this.enemyId,
    required this.enemyName,
    required this.eventType,
    required this.triggered,
    this.hasEffect = false,
    this.logMessage,
    this.reason,
  });

  @override
  String toString() {
    if (triggered) {
      return '[$passiveName] on $enemyName: ${logMessage ?? 'No message'}';
    } else {
      return '[$passiveName] on $enemyName: BLOCKED - $reason';
    }
  }
}
