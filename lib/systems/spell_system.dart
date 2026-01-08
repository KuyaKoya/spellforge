import '../domain/combat_event.dart';
import '../domain/effect.dart';
import '../domain/element.dart';
import '../domain/enemy.dart';
import '../domain/elite_enemy.dart';
import '../domain/mage.dart';
import '../domain/spell.dart';
import '../progression/node_modifier.dart';
import 'modifier_service.dart';

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
  /// [damageMultiplier] is applied to all damage dealt (e.g. from temporary buffs).
  /// [elementalModifiers] are Phase 7.8 bonuses from character progression.
  /// Returns a detailed result with all logs.
  static SpellCastResult castSpell({
    required Mage caster,
    required Spell spell,
    required List<Enemy> enemies,
    int? targetIndex,
    double damageMultiplier = 1.0,
    List<NodeModifier> elementalModifiers = const [],
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
        damageMultiplier: damageMultiplier,
        elementalModifiers: elementalModifiers,
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
    double damageMultiplier = 1.0,
    List<NodeModifier> elementalModifiers = const [],
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
          // Phase 7.8: Apply shield multiplier from elemental modifiers
          final shieldMultiplier = ModifierService.getShieldMultiplier(
            elementalModifiers,
          );
          final modifiedValue = (effect.value * shieldMultiplier).round();
          final modifiedEffect = Effect(
            type: EffectType.armor,
            value: modifiedValue,
            duration: effect.duration,
            targetRule: effect.targetRule,
          );
          caster.applyStatusEffect(modifiedEffect);
          logs.add(
            '${caster.name} gains $modifiedValue Armor for ${effect.duration} turn(s)',
          );
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
          final basePower = effect.value;

          // Pokémon-style: Get attacker's effective attack stat
          // Burn reduces attack by 10%
          double attackerAttack = caster.attack.toDouble();
          for (final status in caster.statusEffects) {
            if (status.type == EffectType.burn) {
              attackerAttack *= 0.9; // Burn reduces attack by 10%
            }
            if (status.type == EffectType.weaken) {
              attackerAttack *= (100 - status.value) / 100.0;
            }
          }

          // Pokémon-style: Get defender's effective defense stat
          final defenderDefense = target.defense.clamp(1, 9999);

          // Phase 7.8: Calculate critical hit
          final critChance = ModifierService.getCritChanceModifier(
            elementalModifiers,
            element: spell.element,
          );
          final isCrit =
              critChance > 0 &&
              (DateTime.now().millisecondsSinceEpoch % 100) < critChance;
          final critMultiplier = isCrit ? 1.5 : 1.0;

          // Pokémon-style damage formula:
          // Damage = BasePower × (Attack / Defense) × ElementMultiplier × Modifiers
          // Minimum damage: 1
          final rawDamage =
              basePower *
              (attackerAttack / defenderDefense) *
              multiplier *
              damageMultiplier *
              critMultiplier;
          final finalDamage = rawDamage.round().clamp(1, 9999);

          final initialArmor = target.statusEffects
              .where((e) => e.type == EffectType.armor)
              .fold(0, (sum, e) => sum + e.value);

          // Phase 7.6.8: Use elite-specific damage method for passive triggering
          // Phase 7.6.8: Use elite-specific damage method for passive triggering
          int actualDamage;

          // Phase 7.9.3.1: Trigger spellCastAgainst passives
          int damageToApply = finalDamage;
          if (target is EliteEnemy) {
            // Check if it's the first spell this turn
            // Note: passiveState.spellsThisTurn is incremented inside takeDamageWithElement,
            // so at this point it hasn't been incremented yet for this spell.
            final isFirst = target.passiveState.spellsThisTurn == 0;

            final results = target.triggerPassives(
              CombatEvent.spellCastAgainst(
                source: target,
                element: spell.element,
                damage: finalDamage,
                isFirstSpellThisTurn: isFirst,
              ),
            );

            _applyPassiveResults(results, target, caster, logs);

            for (final result in results) {
              if (result.damageModifier != null) {
                damageToApply += result.damageModifier!;
              }
              if (result.logMessage != null) {
                logs.add('  ⚠️ ${result.logMessage}');
              }
            }
            if (damageToApply < 0) damageToApply = 0;

            actualDamage = target.takeDamageWithElement(
              damageToApply,
              spell.element,
            );
          } else {
            actualDamage = target.takeDamage(damageToApply);
          }

          logs.add('${spell.displayName} hits ${target.name}');

          // Phase 7.8: Log critical hit
          if (isCrit) {
            logs.add('💥 CRITICAL HIT!');
          }

          // Only show effectiveness if damage reached the enemy's HP (wasn't fully absorbed)
          if (actualDamage > 0 && multiplier != 1.0) {
            logs.add(effectivenessText);
          }

          if (actualDamage > 0) {
            logs.add('Damage: $actualDamage');
          } else if (initialArmor > 0 && finalDamage > 0) {
            logs.add('Damage fully absorbed by Armor!');
          } else {
            logs.add('Damage: 0');
          }
          break;

        case EffectType.burn:
          // Phase 7.8: Apply burn duration modifier
          final burnDurationBonus = ModifierService.getBurnDurationModifier(
            elementalModifiers,
          );
          // Phase 7.8: Apply burn damage modifier
          final burnDamageMultiplier = ModifierService.getBurnDamageMultiplier(
            elementalModifiers,
          );
          final modifiedValue = (effect.value * burnDamageMultiplier).round();

          final modifiedBurnEffect = Effect(
            type: EffectType.burn,
            value: modifiedValue,
            duration: effect.duration + burnDurationBonus,
            targetRule: effect.targetRule,
          );
          target.applyStatusEffect(modifiedBurnEffect);
          logs.add(
            'Burn applied to ${target.name} ($modifiedValue/turn for ${modifiedBurnEffect.duration} turns)',
          );
          break;

        case EffectType.slow:
          target.applyStatusEffect(effect);
          logs.add(
            'Slow applied to ${target.name} (${effect.value} actions for ${effect.duration} turns)',
          );
          break;

        case EffectType.weaken:
          target.applyStatusEffect(effect);
          logs.add(
            'Weaken applied to ${target.name} (-${effect.value}% damage for ${effect.duration} turns)',
          );
          break;

        case EffectType.delay:
          target.isDelayed = true;
          logs.add('${target.name} is delayed!');
          break;

        default:
          break;
      }
    }

    return logs;
  }

  /// Calculates the effective damage of a spell against a target (for preview).
  static int calculateDamage(
    Spell spell,
    Element targetElement, [
    Mage? caster,
  ]) {
    final multiplier = spell.element.getMultiplierAgainst(targetElement);
    final damageEffect = spell.effects
        .where((e) => e.type == EffectType.damage)
        .fold(0, (sum, e) => sum + e.value);

    double weakenMultiplier = 1.0;
    if (caster != null) {
      for (final status in caster.statusEffects) {
        if (status.type == EffectType.weaken) {
          weakenMultiplier *= (100 - status.value) / 100.0;
        }
      }
    }

    return (damageEffect * multiplier * weakenMultiplier).round();
  }

  /// Phase 7.9.3.1: Applies the effects from PassiveResults to game state.
  static void _applyPassiveResults(
    List<PassiveResult> results,
    EliteEnemy source,
    Mage caster,
    List<String> logs,
  ) {
    for (final result in results) {
      // Apply armor gain to the source enemy
      if (result.armorGain != null && result.armorGain! > 0) {
        source.applyStatusEffect(
          Effect(
            type: EffectType.armor,
            value: result.armorGain!,
            duration: 99,
          ),
        );
        logs.add('  🛡️ ${source.name} gains ${result.armorGain} armor!');
      }

      // Apply healing (negative damage modifier used for self-healing in some contexts,
      // but here meaningful healing is separate or handled via negative damage in actual hits.
      // However, if the passive purely heals (like Vampiric on attack), we handle it here.
      // Wait, Vampiric triggers on damageDealt, which is handled in CombatSystem usually?
      // No, enemies don't cast spells via SpellSystem usually (Mage does).
      // So this is mostly for defensive passives like "Heal when hit by Water".

      // Apply status effect to player (for retaliatory passives like Volatile)
      if (result.statusToApply != null) {
        final effect = Effect(
          type: result.statusToApply!,
          value: result.statusValue ?? 1,
          duration: result.statusDuration ?? 2,
        );
        caster.applyStatusEffect(effect);
        logs.add(
          '  ⚠️ ${result.statusToApply!.name} applied to ${caster.name}!',
        );
      }
    }
  }
}
