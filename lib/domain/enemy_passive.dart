import 'combat_event.dart';
import 'element.dart';

/// Passive category for organization and display.
enum PassiveCategory {
  /// Elemental identity passives - define the enemy's elemental nature.
  elemental,

  /// Behavioral/mechanical passives - define combat patterns.
  behavioral,

  /// Systemic passives - boss-only, define fight patterns.
  systemic,
}

/// Represents a passive ability that an elite or boss enemy can have.
/// Passives are always active and listen to combat events.
class EnemyPassive {
  final String id;
  final String name;
  final String description;
  final String icon;
  final PassiveCategory category;

  /// Short trigger condition shown in UI.
  final String triggerHint;

  /// The combat event types this passive listens to.
  final List<CombatEventType> triggers;

  /// The effect function - takes event and returns result.
  final PassiveResult Function(CombatEvent event, PassiveState state) effect;

  const EnemyPassive({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.triggerHint,
    required this.triggers,
    required this.effect,
  });

  /// Whether this passive should trigger for the given event type.
  bool shouldTrigger(CombatEventType type) => triggers.contains(type);

  @override
  String toString() => '$icon $name';
}

/// State tracked by passives during combat.
class PassiveState {
  /// Counts of elements that have hit this enemy.
  final Map<Element, int> elementHitCounts = {};

  /// Whether burn immunity is active.
  bool burnImmune = false;

  /// Turn counter for burn immunity.
  int burnImmunityTurns = 0;

  /// Consecutive action counter for Cyclone Momentum.
  int consecutiveActions = 0;

  /// Whether this enemy has acted this turn.
  bool hasActedThisTurn = false;

  /// Whether the twin has acted this turn.
  bool twinActedThisTurn = false;

  /// Permanent damage bonus from Forge of Endurance.
  int permanentDamageBonus = 0;

  /// Number of spells cast against this enemy this turn.
  int spellsThisTurn = 0;

  /// War Temper stacks.
  int warTemperStacks = 0;

  /// Bastion Protocol: armor at turn start.
  int armorAtTurnStart = 0;

  /// Extra turns counter for Tempest Flow.
  int extraTurnCounter = 0;

  /// Resets per-turn state.
  void resetTurn() {
    hasActedThisTurn = false;
    twinActedThisTurn = false;
    spellsThisTurn = 0;

    if (burnImmunityTurns > 0) {
      burnImmunityTurns--;
      if (burnImmunityTurns <= 0) {
        burnImmune = false;
      }
    }
  }

  /// Records a hit by an element.
  void recordElementHit(Element element) {
    elementHitCounts[element] = (elementHitCounts[element] ?? 0) + 1;
  }

  /// Gets the hit count for an element.
  int getElementHitCount(Element element) => elementHitCounts[element] ?? 0;

  /// Deep copy for serialization.
  PassiveState copy() {
    final copy = PassiveState()
      ..burnImmune = burnImmune
      ..burnImmunityTurns = burnImmunityTurns
      ..consecutiveActions = consecutiveActions
      ..hasActedThisTurn = hasActedThisTurn
      ..twinActedThisTurn = twinActedThisTurn
      ..permanentDamageBonus = permanentDamageBonus
      ..spellsThisTurn = spellsThisTurn
      ..warTemperStacks = warTemperStacks
      ..armorAtTurnStart = armorAtTurnStart
      ..extraTurnCounter = extraTurnCounter;

    copy.elementHitCounts.addAll(elementHitCounts);
    return copy;
  }
}
