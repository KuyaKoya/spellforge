import '../domain/effect.dart';
import '../domain/element.dart';
import '../domain/enemy.dart';
import '../domain/mage.dart';
import '../domain/spell.dart';
import '../domain/status_effect.dart';

/// Result of a spell cast, containing all log messages.
class SpellCastResult {
  final List<String> logs;
  final bool success;
  final int totalDamage;
  final List<String> statusesApplied;
  final int enemiesDefeated;

  SpellCastResult({
    required this.logs,
    required this.success,
    this.totalDamage = 0,
    this.statusesApplied = const [],
    this.enemiesDefeated = 0,
  });
}

/// Handles all spell-related logic including casting and effect resolution.
class SpellSystem {
  SpellSystem._();

  /// Casts a spell from the mage at the specified target(s).
  /// [targetIndex] is the index within the LIVING enemies list, not the full list.
  /// Returns a detailed result with all logs.
  static SpellCastResult castSpell({
    required Mage caster,
    required Spell spell,
    required List<Enemy> enemies,
    int? targetIndex,
  }) {
    final logs = <String>[];
    int totalDamage = 0;
    final statusesApplied = <String>[];

    // Validate cast
    if (!caster.canCast(spell)) {
      return SpellCastResult(
        logs: [
          'Cannot cast ${spell.displayName} - insufficient mana or actions',
        ],
        success: false,
      );
    }

    // Get living enemies for targeting
    final livingEnemies = enemies.where((e) => e.isAlive).toList();

    // Consume resources
    caster.consumeForCast(spell);
    logs.add(
      '${caster.name} casts ${spell.displayName} (${spell.manaCost} mana)',
    );

    // Process each effect
    for (final effect in spell.effects) {
      final effectLogs = _resolveEffect(
        effect: effect,
        caster: caster,
        spell: spell,
        livingEnemies: livingEnemies,
        targetIndex: targetIndex,
      );

      for (final log in effectLogs) {
        logs.add(log);
        if (log.contains('Damage:')) {
          // Parse damage from log
          final match = RegExp(r'Damage: (\d+)').firstMatch(log);
          if (match != null) {
            totalDamage += int.parse(match.group(1)!);
          }
        }
        if (log.contains('applied')) {
          statusesApplied.add(log);
        }
      }
    }

    // Check for defeated enemies
    int enemiesDefeated = 0;
    for (final enemy in livingEnemies) {
      if (!enemy.isAlive) {
        logs.add('${enemy.name} is defeated!');
        enemiesDefeated++;
      }
    }

    return SpellCastResult(
      logs: logs,
      success: true,
      totalDamage: totalDamage,
      statusesApplied: statusesApplied,
      enemiesDefeated: enemiesDefeated,
    );
  }

  /// Resolves a single effect.
  /// [livingEnemies] is the list of currently alive enemies.
  /// [targetIndex] is the index within livingEnemies.
  static List<String> _resolveEffect({
    required Effect effect,
    required Mage caster,
    required Spell spell,
    required List<Enemy> livingEnemies,
    int? targetIndex,
  }) {
    final logs = <String>[];

    // Determine targets from living enemies
    List<Enemy> targets;
    switch (effect.targetRule) {
      case TargetRule.single:
        if (targetIndex != null && targetIndex < livingEnemies.length) {
          targets = [livingEnemies[targetIndex]];
        } else if (livingEnemies.isNotEmpty) {
          targets = [livingEnemies.first];
        } else {
          targets = [];
        }
        break;
      case TargetRule.all:
        targets = livingEnemies.where((e) => e.isAlive).toList();
        break;
      case TargetRule.self:
        targets = []; // Self-targeting handled separately
        break;
      case TargetRule.random:
        final alive = livingEnemies.where((e) => e.isAlive).toList();
        if (alive.isNotEmpty) {
          alive.shuffle();
          targets = [alive.first];
        } else {
          targets = [];
        }
        break;
    }

    // Handle self-targeting effects
    if (effect.targetRule == TargetRule.self) {
      switch (effect.type) {
        case EffectType.armor:
          // Compatible with old: also apply to legacy list in mage.dart's applyStatusEffect
          caster.applyStatusEffect(effect);

          // Phase 7.2: Apply new Shield status
          final newShield = StatusEffect.shield(
            shieldValue: effect.value,
            sourceId: spell.id,
          );
          caster.applyNewStatusEffect(newShield);

          logs.add('${caster.name} gains ${effect.value} Shield');
          break;
        case EffectType.actionGain:
          caster.actionsRemaining += effect.value;
          logs.add('${caster.name} gains ${effect.value} action(s)');
          break;
        default:
          break;
      }
      return logs;
    }

    // Handle enemy-targeting effects
    for (final target in targets) {
      if (!target.isAlive) continue;

      switch (effect.type) {
        case EffectType.damage:
          final multiplier = spell.element.getMultiplierAgainst(target.element);
          final effectivenessText = spell.element.getEffectivenessText(
            target.element,
          );
          final baseDamage = effect.value;
          final finalDamage = (baseDamage * multiplier).round();
          final actualDamage = target.takeDamage(finalDamage);

          logs.add('${spell.displayName} hits ${target.name}');
          if (multiplier != 1.0) {
            logs.add(effectivenessText);
          }
          logs.add('Damage: $actualDamage');
          break;

        case EffectType.burn:
          target.applyStatusEffect(effect);

          // Phase 7.2: Apply new Burn status
          final newBurn = StatusEffect.burn(
            duration: effect.duration,
            damagePerStack: effect.value,
            sourceId: spell.id,
          );
          final burnMsg = target.applyNewStatusEffect(newBurn);

          logs.add(
            'Burn applied to ${target.name} (${effect.value}/turn for ${effect.duration} turns)',
          );
          if (burnMsg != null) logs.add(burnMsg);
          break;

        case EffectType.slow:
          target.applyStatusEffect(effect);

          // Phase 7.2: Apply new Slow status
          final newSlow = StatusEffect.slow(
            duration: effect.duration,
            sourceId: spell.id,
          );
          final slowMsg = target.applyNewStatusEffect(newSlow);

          logs.add('Slow applied to ${target.name} (${effect.duration} turns)');
          if (slowMsg != null) logs.add(slowMsg);
          break;

        case EffectType.weaken:
          target.applyStatusEffect(effect);

          // Phase 7.2: Apply new Weaken status
          final newWeaken = StatusEffect.weaken(
            duration: effect.duration,
            percentage: effect.value,
            sourceId: spell.id,
          );
          target.applyNewStatusEffect(newWeaken);

          logs.add(
            'Weaken applied to ${target.name} (-${effect.value}% output for ${effect.duration} turns)',
          );
          break;

        case EffectType.delay:
          target.isDelayed = true; // Legacy

          // Phase 7.2: New Delay status (optional but good for consistency)
          final newDelay = StatusEffect(
            id: 'delay_${DateTime.now().millisecondsSinceEpoch}',
            type: StatusEffectType.delay,
            value: 1,
            duration: effect
                .value, // Effect value is duration for delay? Or standard?
            source: StatusSource.spell,
            sourceId: spell.id,
          );
          target.applyNewStatusEffect(newDelay);

          logs.add('${target.name} is delayed!');
          break;

        default:
          break;
      }
    }

    return logs;
  }

  /// Calculates the effective damage of a spell against a target (for preview).
  static int calculateDamage(Spell spell, Element targetElement) {
    final multiplier = spell.element.getMultiplierAgainst(targetElement);
    final damageEffect = spell.effects
        .where((e) => e.type == EffectType.damage)
        .fold(0, (sum, e) => sum + e.value);
    return (damageEffect * multiplier).round();
  }
}
