import 'combat_event.dart';
import 'elite_enemy.dart';
import 'enemy.dart';
import 'enemy_passive.dart';

/// Represents a boss enemy with 3 passives and enhanced mechanics.
/// Bosses are pattern-defining encounters, not just stat checks.
class BossEnemy extends EliteEnemy {
  /// Boss title for display (e.g., "Gatekeeper of Pyre").
  final String title;

  /// Whether this boss's passives are always visible to the player.
  final bool passivesAlwaysVisible;

  /// Pattern turn counter for predictable attack patterns.
  int patternTurn = 0;

  BossEnemy({
    required super.id,
    required super.name,
    required super.element,
    required super.currentHP,
    required super.maxHP,
    required super.attackDamage,
    super.armorGain = 5,
    super.intent = EnemyIntent.attack,
    super.spellLoadout = const [],
    super.maxMana = 0,
    required super.modifiers,
    super.resistantElement,
    super.passives,
    super.passiveState,
    this.title = '',
    this.passivesAlwaysVisible = true,
  });

  /// Whether this is a gatekeeper boss.
  bool get isGatekeeper => id.startsWith('gatekeeper_');

  /// Gets a formatted passive display for the boss.
  String get passiveSummary {
    if (passives.isEmpty) return 'No passives';

    return passives
        .map((p) {
          final category = p.category == PassiveCategory.systemic ? '★' : '•';
          return '$category ${p.icon} ${p.name}';
        })
        .join('\n');
  }

  /// Gets the boss's current pattern action description.
  String get patternDescription {
    // Override in subclasses for specific patterns
    return 'Unknown pattern';
  }

  @override
  int getEffectiveDamage() {
    int damage = super.getEffectiveDamage();

    // Add permanent damage bonus from Forge of Endurance
    damage += passiveState.permanentDamageBonus;

    // Add War Temper stacks if applicable
    damage += passiveState.warTemperStacks;

    return damage;
  }

  /// Triggers turn start passives and returns log messages.
  List<String> processTurnStart(int turnNumber) {
    patternTurn++;
    final logs = <String>[];

    // Store armor at turn start for Bastion Protocol
    final armorEffects = statusEffects
        .where((e) => e.type.name == 'armor')
        .fold(0, (sum, e) => sum + e.value);
    passiveState.armorAtTurnStart = armorEffects;

    // Trigger turn start passives
    final event = CombatEvent.turnStart(source: this, turnNumber: turnNumber);

    for (final passive in passives) {
      if (passive.shouldTrigger(CombatEventType.turnStart)) {
        final result = passive.effect(event, passiveState);
        if (result.logMessage != null) {
          logs.add(result.logMessage!);
        }
      }
    }

    return logs;
  }

  /// Triggers turn end passives and returns results.
  List<PassiveResult> processTurnEnd(
    int turnNumber, {
    bool aboveHalfHP = true,
  }) {
    final event = CombatEvent(
      type: CombatEventType.turnEnd,
      source: this,
      turnNumber: turnNumber,
      context: {'aboveHalfHP': aboveHalfHP},
    );

    return triggerPassives(event);
  }

  @override
  BossEnemy copy() {
    return BossEnemy(
      id: id,
      name: name,
      element: element,
      currentHP: currentHP,
      maxHP: maxHP,
      attackDamage: attackDamage,
      armorGain: armorGain,
      intent: intent,
      modifiers: List.from(modifiers),
      resistantElement: resistantElement,
      passives: passives.toList(),
      passiveState: passiveState.copy(),
      title: title,
      passivesAlwaysVisible: passivesAlwaysVisible,
    );
  }

  @override
  String get statusDisplay {
    final base = super.statusDisplay;
    return '[$title] $base';
  }
}
