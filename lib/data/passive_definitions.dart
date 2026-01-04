import '../domain/combat_event.dart';
import '../domain/effect.dart';
import '../domain/element.dart';
import '../domain/enemy_passive.dart';

/// Pre-defined passive abilities for elite and boss enemies.
class PassiveDefinitions {
  PassiveDefinitions._();

  // ================== BURNWARD COLOSSUS (Earth) ==================

  /// Molten Carapace - Gains +3 Armor when damaged by Fire.
  static EnemyPassive moltenCarapace() => EnemyPassive(
    id: 'moltenCarapace',
    name: 'Molten Carapace',
    description:
        'Gains +3 Armor whenever damaged by Fire. Encourages avoiding Fire attacks.',
    icon: '🔱',
    category: PassiveCategory.elemental,
    triggerHint: 'Fire damage grants Armor',
    triggers: [CombatEventType.damageTaken],
    effect: (event, state) {
      if (event.element == Element.fire && (event.damage ?? 0) > 0) {
        return PassiveResult(
          logMessage: '⚠ Molten Carapace: Fire damage absorbed, +3 Armor!',
          armorGain: 3,
        );
      }
      return PassiveResult.none();
    },
  );

  /// Earthen Retaliation - When Armor breaks, gain Burn immunity and retaliate.
  static EnemyPassive earthenRetaliation() => EnemyPassive(
    id: 'earthenRetaliation',
    name: 'Earthen Retaliation',
    description:
        'When Armor is broken, gains Burn immunity for 1 turn and retaliates with a shockwave.',
    icon: '💥',
    category: PassiveCategory.behavioral,
    triggerHint: 'Armor break triggers retaliation',
    triggers: [CombatEventType.armorBroken],
    effect: (event, state) {
      state.burnImmune = true;
      state.burnImmunityTurns = 1;
      return PassiveResult(
        logMessage:
            '💥 Earthen Retaliation: Armor broken! Shockwave retaliates for 5 damage!',
        damageModifier: 5, // Dealt to player
        statusToApply: EffectType.burn,
        statusValue: 0, // Immunity flag
        statusDuration: 1,
      );
    },
  );

  // ================== TEMPEST TWIN A (Wind) ==================

  /// Cyclone Momentum - Consecutive actions increase damage.
  static EnemyPassive cycloneMomentum() => EnemyPassive(
    id: 'cycloneMomentum',
    name: 'Cyclone Momentum',
    description:
        'Every consecutive action increases damage by 10%. Resets if stunned or slowed.',
    icon: '🌪',
    category: PassiveCategory.elemental,
    triggerHint: 'Consecutive attacks power up',
    triggers: [CombatEventType.damageDealt, CombatEventType.statusApplied],
    effect: (event, state) {
      // Reset on slow/stun
      if (event.type == CombatEventType.statusApplied &&
          event.effectType == EffectType.slow) {
        final oldStacks = state.consecutiveActions;
        state.consecutiveActions = 0;
        if (oldStacks > 0) {
          return PassiveResult(
            logMessage: '🌪 Cyclone Momentum: Slowed! Momentum reset.',
          );
        }
        return PassiveResult.none();
      }

      // Increase on attack
      if (event.type == CombatEventType.damageDealt) {
        state.consecutiveActions++;
        final bonus = state.consecutiveActions * 10;
        return PassiveResult(
          logMessage:
              '🌪 Cyclone Momentum: ${state.consecutiveActions} stack(s), +$bonus% damage!',
          priorityBonus: bonus ~/ 10,
        );
      }

      return PassiveResult.none();
    },
  );

  /// Twin Synchrony - If the other twin acts, gain +1 spell priority.
  static EnemyPassive twinSynchrony() => EnemyPassive(
    id: 'twinSynchrony',
    name: 'Twin Synchrony',
    description: 'If the other Twin acts this turn, gains +1 spell priority.',
    icon: '🔗',
    category: PassiveCategory.behavioral,
    triggerHint: 'Twin actions boost priority',
    triggers: [CombatEventType.turnStart],
    effect: (event, state) {
      if (state.twinActedThisTurn) {
        return PassiveResult(
          logMessage: '🔗 Twin Synchrony: Sibling\'s action boosts priority!',
          priorityBonus: 1,
        );
      }
      return PassiveResult.none();
    },
  );

  // ================== TEMPEST TWIN B (Wind) ==================

  /// Gale Veil - First incoming hit each turn deals 50% damage.
  static EnemyPassive galeVeil() => EnemyPassive(
    id: 'galeVeil',
    name: 'Gale Veil',
    description: 'The first incoming hit each turn deals only 50% damage.',
    icon: '🌬',
    category: PassiveCategory.elemental,
    triggerHint: 'First hit reduced',
    triggers: [CombatEventType.damageTaken],
    effect: (event, state) {
      // Only trigger on first spell of the turn
      if (state.spellsThisTurn == 1 && (event.damage ?? 0) > 0) {
        final reduced = (event.damage! * 0.5).round();
        return PassiveResult(
          logMessage: '🌬 Gale Veil: First hit softened! ($reduced damage)',
          damageModifier: -reduced,
        );
      }
      return PassiveResult.none();
    },
  );

  // ================== GLACIAL EXECUTIONER (Water) ==================

  /// Permafrost Edge - Attacks against Slowed targets apply Freeze.
  static EnemyPassive permafrostEdge() => EnemyPassive(
    id: 'permafrostEdge',
    name: 'Permafrost Edge',
    description: 'Attacks against Slowed targets apply Freeze for 1 turn.',
    icon: '❄️',
    category: PassiveCategory.elemental,
    triggerHint: 'Slowed targets get Frozen',
    triggers: [CombatEventType.damageDealt],
    effect: (event, state) {
      // Check if target is slowed in context
      final targetSlowed = event.context['targetSlowed'] as bool? ?? false;
      if (targetSlowed && (event.damage ?? 0) > 0) {
        return PassiveResult(
          logMessage: '❄️ Permafrost Edge: Target is Slowed → Frozen!',
          statusToApply: EffectType.slow, // Using slow as freeze proxy
          statusValue: 1,
          statusDuration: 1,
        );
      }
      return PassiveResult.none();
    },
  );

  /// Cold Precision - +20% damage against targets below 50% HP.
  static EnemyPassive coldPrecision() => EnemyPassive(
    id: 'coldPrecision',
    name: 'Cold Precision',
    description: 'Damage increases by 20% against enemies below 50% HP.',
    icon: '🎯',
    category: PassiveCategory.behavioral,
    triggerHint: 'Executes low HP targets',
    triggers: [CombatEventType.damageDealt],
    effect: (event, state) {
      final targetLowHP = event.context['targetBelowHalf'] as bool? ?? false;
      if (targetLowHP) {
        return PassiveResult(
          logMessage: '🎯 Cold Precision: Target below 50% HP, +20% damage!',
          damageModifier: ((event.damage ?? 0) * 0.2).round(),
        );
      }
      return PassiveResult.none();
    },
  );

  // ================== INFERNAL WARLORD (Fire) ==================

  /// Blazing Adaptation - Gains resistance to repeated elements.
  static EnemyPassive blazingAdaptation() => EnemyPassive(
    id: 'blazingAdaptation',
    name: 'Blazing Adaptation',
    description:
        'After being hit by the same element twice, gains 25% resistance to that element.',
    icon: '🔥',
    category: PassiveCategory.elemental,
    triggerHint: 'Adapts to repeated elements',
    triggers: [CombatEventType.damageTaken],
    effect: (event, state) {
      if (event.element != null && (event.damage ?? 0) > 0) {
        state.recordElementHit(event.element!);
        final hitCount = state.getElementHitCount(event.element!);
        if (hitCount >= 2) {
          final resistance = ((hitCount - 1) * 25).clamp(0, 50);
          return PassiveResult(
            logMessage:
                '🔥 Blazing Adaptation: ${event.element!.displayName} resistance gained ($resistance%)!',
            damageModifier: -((event.damage! * resistance / 100).round()),
          );
        }
      }
      return PassiveResult.none();
    },
  );

  /// War Temper - Each burn tick grants +1 attack damage.
  static EnemyPassive warTemper() => EnemyPassive(
    id: 'warTemper',
    name: 'War Temper',
    description: 'Each time a Burn ticks, gains +1 attack damage (stacking).',
    icon: '⚔️',
    category: PassiveCategory.behavioral,
    triggerHint: 'Burns fuel rage',
    triggers: [CombatEventType.burnTick],
    effect: (event, state) {
      state.warTemperStacks++;
      return PassiveResult(
        logMessage:
            '⚔️ War Temper: Burn fuels rage! +${state.warTemperStacks} permanent damage.',
        damageModifier: 1, // Permanent bonus
      );
    },
  );

  // ================== STONE SENTINEL (Earth) ==================

  /// Immutable Form - Cannot lose more than 20% max HP per turn.
  static EnemyPassive immutableForm() => EnemyPassive(
    id: 'immutableForm',
    name: 'Immutable Form',
    description: 'Cannot lose more than 20% of max HP in a single turn.',
    icon: '🗿',
    category: PassiveCategory.elemental,
    triggerHint: 'Damage capped per turn',
    triggers: [CombatEventType.damageTaken],
    effect: (event, state) {
      // This is handled at combat system level with damage cap
      // The passive just provides the visual indicator
      return PassiveResult(
        logMessage: '🗿 Immutable Form: Damage limited this turn.',
      );
    },
  );

  /// Bastion Protocol - If Armor > 0 at turn start, convert 50% to HP.
  static EnemyPassive bastionProtocol() => EnemyPassive(
    id: 'bastionProtocol',
    name: 'Bastion Protocol',
    description:
        'If Armor is greater than 0 at turn start, converts 50% of Armor into HP.',
    icon: '🛡️',
    category: PassiveCategory.behavioral,
    triggerHint: 'Armor converts to HP',
    triggers: [CombatEventType.turnStart],
    effect: (event, state) {
      if (state.armorAtTurnStart > 0) {
        final healing = (state.armorAtTurnStart * 0.5).round();
        return PassiveResult(
          logMessage:
              '🛡️ Bastion Protocol: ${state.armorAtTurnStart} Armor → +$healing HP!',
          damageModifier: -healing, // Negative damage = healing
        );
      }
      return PassiveResult.none();
    },
  );

  // ================== TYPHOON HERALD (Water) ==================

  /// Riptide Casting - After casting a spell, apply Slow to target.
  static EnemyPassive riptideCasting() => EnemyPassive(
    id: 'riptideCasting',
    name: 'Riptide Casting',
    description: 'After casting a spell, applies Slow to the target.',
    icon: '🌊',
    category: PassiveCategory.elemental,
    triggerHint: 'Spells apply Slow',
    triggers: [CombatEventType.damageDealt],
    effect: (event, state) {
      return PassiveResult(
        logMessage: '🌊 Riptide Casting: Spell impact slows target!',
        statusToApply: EffectType.slow,
        statusValue: 1,
        statusDuration: 1,
      );
    },
  );

  /// Tempest Flow - Acts again every 4th turn if above 50% HP.
  static EnemyPassive tempestFlow() => EnemyPassive(
    id: 'tempestFlow',
    name: 'Tempest Flow',
    description: 'Acts again every 4th turn if above 50% HP.',
    icon: '⚡',
    category: PassiveCategory.behavioral,
    triggerHint: 'Extra action every 4 turns',
    triggers: [CombatEventType.turnEnd],
    effect: (event, state) {
      state.extraTurnCounter++;
      final aboveHalfHP = event.context['aboveHalfHP'] as bool? ?? true;

      if (state.extraTurnCounter >= 4 && aboveHalfHP) {
        state.extraTurnCounter = 0;
        return PassiveResult(
          logMessage: '⚡ Tempest Flow: The storm surges! Extra action!',
          actAgain: true,
        );
      }
      return PassiveResult.none();
    },
  );

  // ================== BOSS: GATEKEEPER OF PYRE ==================

  /// Forge of Endurance - Each armor gain also grants +1 permanent damage.
  static EnemyPassive forgeOfEndurance() => EnemyPassive(
    id: 'forgeOfEndurance',
    name: 'Forge of Endurance',
    description:
        'Each time the Gatekeeper gains Armor, it also gains +1 permanent damage.',
    icon: '🔨',
    category: PassiveCategory.systemic,
    triggerHint: 'Armor = Damage growth',
    triggers: [CombatEventType.armorGained],
    effect: (event, state) {
      state.permanentDamageBonus++;
      return PassiveResult(
        logMessage:
            '🔨 Forge of Endurance: Armor forged into power! +${state.permanentDamageBonus} damage.',
        damageModifier: 1,
      );
    },
  );

  // ================== BOSS: GATEKEEPER OF TIDE ==================

  /// Tidal Reversal - First spell each turn has 50% reduced effect.
  static EnemyPassive tidalReversal() => EnemyPassive(
    id: 'tidalReversal',
    name: 'Tidal Reversal',
    description:
        'The first spell cast against it each turn has its effect reduced by 50%.',
    icon: '🌀',
    category: PassiveCategory.systemic,
    triggerHint: 'First spell weakened',
    triggers: [CombatEventType.spellCastAgainst],
    effect: (event, state) {
      final isFirst = event.context['isFirstSpellThisTurn'] as bool? ?? false;
      if (isFirst) {
        final reduction = ((event.damage ?? 0) * 0.5).round();
        return PassiveResult(
          logMessage:
              '🌀 Tidal Reversal: First spell disrupted! -$reduction damage.',
          damageModifier: -reduction,
        );
      }
      return PassiveResult.none();
    },
  );

  // ================== PASSIVE PRESETS BY ENEMY ==================

  /// Gets all passives for Burnward Colossus.
  static List<EnemyPassive> burnwardColossusPassives() => [
    moltenCarapace(),
    earthenRetaliation(),
  ];

  /// Gets all passives for Tempest Twin A.
  static List<EnemyPassive> tempestTwinAPassives() => [
    cycloneMomentum(),
    twinSynchrony(),
  ];

  /// Gets all passives for Tempest Twin B.
  static List<EnemyPassive> tempestTwinBPassives() => [
    galeVeil(),
    twinSynchrony(),
  ];

  /// Gets all passives for Glacial Executioner.
  static List<EnemyPassive> glacialExecutionerPassives() => [
    permafrostEdge(),
    coldPrecision(),
  ];

  /// Gets all passives for Infernal Warlord.
  static List<EnemyPassive> infernalWarlordPassives() => [
    blazingAdaptation(),
    warTemper(),
  ];

  /// Gets all passives for Stone Sentinel.
  static List<EnemyPassive> stoneSentinelPassives() => [
    immutableForm(),
    bastionProtocol(),
  ];

  /// Gets all passives for Typhoon Herald.
  static List<EnemyPassive> typhoonHeraldPassives() => [
    riptideCasting(),
    tempestFlow(),
  ];

  /// Gets all passives for Gatekeeper of Pyre.
  static List<EnemyPassive> gatekeeperPyrePassives() => [
    // Given: Immune to Burn, Resistant to Fire (handled as modifiers)
    forgeOfEndurance(),
  ];

  /// Gets all passives for Gatekeeper of Tide.
  static List<EnemyPassive> gatekeeperTidePassives() => [
    // Given: Immune to Slow, Resistant to Water (handled as modifiers)
    tidalReversal(),
  ];

  /// Gets passives by enemy ID.
  static List<EnemyPassive> getPassivesForEnemy(String enemyId) {
    switch (enemyId) {
      case 'burnwardColossus':
        return burnwardColossusPassives();
      case 'tempestTwinA':
        return tempestTwinAPassives();
      case 'tempestTwinB':
        return tempestTwinBPassives();
      case 'glacialExecutioner':
        return glacialExecutionerPassives();
      case 'infernalWarlord':
        return infernalWarlordPassives();
      case 'stoneSentinel':
        return stoneSentinelPassives();
      case 'typhoonHerald':
        return typhoonHeraldPassives();
      case 'gatekeeper_pyre':
        return gatekeeperPyrePassives();
      case 'gatekeeper_tide':
        return gatekeeperTidePassives();
      default:
        return [];
    }
  }
}
