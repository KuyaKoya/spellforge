import 'combat_event.dart';
import 'effect.dart';
import 'element.dart';
import 'enemy.dart';
import 'enemy_passive.dart';
import '../data/passive_definitions.dart';
import '../systems/passive_resolver.dart';

/// Modifiers that elite enemies can have.
enum EliteModifier {
  empowered, // Increased damage
  resistant, // Reduced damage from one element
  relentless, // Acts twice every X turns
  adaptive, // Gains resistance to repeated elements
  burnImmune, // Immune to Burn status
  slowImmune; // Immune to Slow status

  String get displayName {
    switch (this) {
      case EliteModifier.empowered:
        return 'Empowered';
      case EliteModifier.resistant:
        return 'Resistant';
      case EliteModifier.relentless:
        return 'Relentless';
      case EliteModifier.adaptive:
        return 'Adaptive';
      case EliteModifier.burnImmune:
        return 'Burn Immune';
      case EliteModifier.slowImmune:
        return 'Slow Immune';
    }
  }

  String get description {
    switch (this) {
      case EliteModifier.empowered:
        return 'Deals 50% more damage';
      case EliteModifier.resistant:
        return 'Takes 50% reduced damage from one element';
      case EliteModifier.relentless:
        return 'Acts twice every 3 turns';
      case EliteModifier.adaptive:
        return 'Gains resistance to repeated element attacks';
      case EliteModifier.burnImmune:
        return 'Cannot be burned';
      case EliteModifier.slowImmune:
        return 'Cannot be slowed';
    }
  }

  String get icon {
    switch (this) {
      case EliteModifier.empowered:
        return '💪';
      case EliteModifier.resistant:
        return '🛡️';
      case EliteModifier.relentless:
        return '⚡';
      case EliteModifier.adaptive:
        return '🔄';
      case EliteModifier.burnImmune:
        return '🔥';
      case EliteModifier.slowImmune:
        return '❄️';
    }
  }
}

/// Represents an elite enemy with special modifiers, passives, and enhanced stats.
class EliteEnemy extends Enemy {
  final List<EliteModifier> modifiers;
  final Element? resistantElement;

  /// Phase 7.5: Passive abilities for this elite.
  final List<EnemyPassive> passives;

  /// Phase 7.5: State tracked by passives during combat.
  final PassiveState passiveState;

  int _turnsSinceRelentless = 0;
  final Map<Element, int> _elementHitCount = {};

  /// Damage taken this turn (for Immutable Form passive).
  int _damageTakenThisTurn = 0;

  /// Max damage per turn (20% of maxHP for Immutable Form).
  int get _maxDamagePerTurn => (maxHP * 0.2).round();

  EliteEnemy({
    required super.id,
    required super.name,
    required super.element,
    required super.currentHP,
    required super.maxHP,
    required super.attackDamage,
    super.armorGain = 5,
    super.intent = EnemyIntent.attack,
    required this.modifiers,
    this.resistantElement,
    List<EnemyPassive>? passives,
    PassiveState? passiveState,
  }) : passives = passives ?? PassiveDefinitions.getPassivesForEnemy(id),
       passiveState = passiveState ?? PassiveState();

  /// Whether this elite has a specific modifier.
  bool hasModifier(EliteModifier modifier) => modifiers.contains(modifier);

  /// Gets the damage output with elite modifiers.
  @override
  int getEffectiveDamage() {
    int damage = super.getEffectiveDamage();

    // Empowered: +50% damage
    if (hasModifier(EliteModifier.empowered)) {
      damage = (damage * 1.5).round();
    }

    // Apply permanent damage bonus from Frenzy, Forge of Endurance, etc.
    damage += passiveState.permanentDamageBonus;

    // Apply War Temper stacks (burn-fueled rage)
    damage += passiveState.warTemperStacks;

    return damage;
  }

  /// Calculates damage taken with elite modifiers.
  int calculateDamageTaken(int baseDamage, Element attackElement) {
    int damage = baseDamage;

    // Resistant: 50% reduction from specific element
    if (hasModifier(EliteModifier.resistant) &&
        resistantElement == attackElement) {
      damage = (damage * 0.5).round();
    }

    // Adaptive: Gain resistance based on hit count
    if (hasModifier(EliteModifier.adaptive)) {
      final hitCount = _elementHitCount[attackElement] ?? 0;
      if (hitCount > 0) {
        // 10% reduction per previous hit, max 50%
        final reduction = (hitCount * 0.1).clamp(0.0, 0.5);
        damage = (damage * (1.0 - reduction)).round();
      }
      _elementHitCount[attackElement] = hitCount + 1;
    }

    return damage.clamp(0, 999);
  }

  /// Takes damage with elite modifier considerations and triggers passives.
  int takeDamageWithElement(
    int damage,
    Element attackElement, {
    int turnNumber = 0,
  }) {
    passiveState.spellsThisTurn++;

    // Trigger passives for damage taken
    final event = CombatEvent.damageTaken(
      source: this,
      damage: damage,
      element: attackElement,
      turnNumber: turnNumber,
    );

    int modifiedDamage = damage;
    for (final passive in passives) {
      if (passive.shouldTrigger(CombatEventType.damageTaken)) {
        final result = passive.effect(event, passiveState);
        if (result.damageModifier != null) {
          modifiedDamage += result.damageModifier!;
        }
      }
    }

    // Apply Immutable Form check if enemy has that passive
    if (hasPassive('immutableForm')) {
      final remainingCap = _maxDamagePerTurn - _damageTakenThisTurn;
      if (remainingCap <= 0) {
        modifiedDamage = 0;
      } else {
        modifiedDamage = modifiedDamage.clamp(0, remainingCap);
      }
    }

    // Check for armor before damage
    final hadArmor = statusEffects.any(
      (e) => e.type == EffectType.armor && e.value > 0,
    );

    final adjustedDamage = calculateDamageTaken(
      modifiedDamage.clamp(0, 999),
      attackElement,
    );
    _damageTakenThisTurn += adjustedDamage;
    final actualDamage = takeDamage(adjustedDamage);

    // Check for armor break
    final hasArmorCallback = statusEffects.any(
      (e) => e.type == EffectType.armor && e.value > 0,
    );
    if (hadArmor && !hasArmorCallback) {
      triggerPassives(
        CombatEvent.armorBroken(source: this, turnNumber: turnNumber),
      );
    }

    return actualDamage;
  }

  @override
  void applyStatusEffect(Effect effect) {
    super.applyStatusEffect(effect);

    // Trigger armorGained if applicable
    if (effect.type == EffectType.armor && effect.value > 0) {
      triggerPassives(
        CombatEvent.armorGained(source: this, amount: effect.value),
      );
    }
  }

  /// Whether the elite can act twice this turn (Relentless).
  bool canActTwice() {
    if (!hasModifier(EliteModifier.relentless)) return false;

    _turnsSinceRelentless++;
    if (_turnsSinceRelentless >= 3) {
      _turnsSinceRelentless = 0;
      return true;
    }
    return false;
  }

  /// Whether this elite has a specific passive by ID.
  bool hasPassive(String passiveId) => passives.any((p) => p.id == passiveId);

  /// Triggers all passives for a given event type.
  List<PassiveResult> triggerPassives(CombatEvent event) {
    return PassiveResolver.instance.resolvePassives(
      event: event,
      enemies: [this],
    );
  }

  /// Resets per-turn state for passives.
  void resetTurnState() {
    _damageTakenThisTurn = 0;

    // Capture armor at turn start for Bastion Protocol passive
    final armorEffects = statusEffects
        .where((e) => e.type == EffectType.armor)
        .fold(0, (sum, e) => sum + e.value);
    passiveState.armorAtTurnStart = armorEffects;

    passiveState.resetTurn();
  }

  /// Gets passive descriptions for UI display.
  List<Map<String, String>> get passiveDescriptions {
    return passives
        .map(
          (p) => {
            'icon': p.icon,
            'name': p.name,
            'description': p.description,
            'trigger': p.triggerHint,
            'category': p.category.name,
          },
        )
        .toList();
  }

  /// Gets all modifier display strings.
  List<String> get modifierDescriptions {
    final descriptions = <String>[];

    for (final modifier in modifiers) {
      String desc = '${modifier.icon} ${modifier.displayName}';
      if (modifier == EliteModifier.resistant && resistantElement != null) {
        desc += ' (${resistantElement!.displayName})';
      }
      descriptions.add(desc);
    }

    return descriptions;
  }

  @override
  String get statusDisplay {
    final base = super.statusDisplay;
    final parts = <String>[base];

    if (modifiers.isNotEmpty) {
      final modifierText = modifierDescriptions.join(', ');
      parts.add('Modifiers: $modifierText');
    }

    if (passives.isNotEmpty) {
      final passiveText = passives.map((p) => p.toString()).join(', ');
      parts.add('Passives: $passiveText');
    }

    return parts.join(' | ');
  }

  /// Creates a copy of this elite enemy.
  @override
  EliteEnemy copy() {
    return EliteEnemy(
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
    );
  }
}
