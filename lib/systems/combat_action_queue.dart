import 'dart:async';
import '../domain/enemy.dart';
import '../domain/mage.dart';
import '../domain/spell.dart';
import '../domain/effect.dart';

/// Types of combat actions.
enum CombatActionType {
  playerSpellCast,
  enemyAttack,
  enemyDefend,
  enemyDebuff,
  statusTick,
  statusApply,
  buff,
  death,
}

/// Represents a single combat action to be executed.
///
/// Actions are executed in a strict sequence:
/// 1. Resolve intent (who attacks whom)
/// 2. Play animation
/// 3. Play sound effect
/// 4. Delay (configurable)
/// 5. Apply damage/effect
/// 6. Update UI state
/// 7. Check for death/end
abstract class CombatAction {
  final CombatActionType type;
  final String description;

  CombatAction({required this.type, required this.description});

  /// Execute the action asynchronously.
  /// Returns a result containing logs and state changes.
  Future<CombatActionResult> execute();
}

/// Result of executing a combat action.
class CombatActionResult {
  final List<String> logs;
  final int damageDealt;
  final int healingDone;
  final List<String> statusesApplied;
  final bool targetDefeated;
  final String? soundKey; // Sound to play for this action

  CombatActionResult({
    this.logs = const [],
    this.damageDealt = 0,
    this.healingDone = 0,
    this.statusesApplied = const [],
    this.targetDefeated = false,
    this.soundKey,
  });

  CombatActionResult copyWith({
    List<String>? logs,
    int? damageDealt,
    int? healingDone,
    List<String>? statusesApplied,
    bool? targetDefeated,
    String? soundKey,
  }) {
    return CombatActionResult(
      logs: logs ?? this.logs,
      damageDealt: damageDealt ?? this.damageDealt,
      healingDone: healingDone ?? this.healingDone,
      statusesApplied: statusesApplied ?? this.statusesApplied,
      targetDefeated: targetDefeated ?? this.targetDefeated,
      soundKey: soundKey ?? this.soundKey,
    );
  }
}

/// Player spell cast action.
class PlayerSpellCastAction extends CombatAction {
  final Mage caster;
  final Spell spell;
  final List<Enemy> enemies;
  final int targetIndex;
  final double damageMultiplier;

  /// Callback invoked BEFORE damage is applied (for animation/sound).
  final Future<void> Function(Spell spell, int targetIndex)? onBeforeApply;

  /// Callback invoked AFTER damage is applied (for UI update).
  final void Function(CombatActionResult result)? onAfterApply;

  PlayerSpellCastAction({
    required this.caster,
    required this.spell,
    required this.enemies,
    required this.targetIndex,
    this.damageMultiplier = 1.0,
    this.onBeforeApply,
    this.onAfterApply,
  }) : super(
         type: CombatActionType.playerSpellCast,
         description: '${caster.name} casts ${spell.displayName}',
       );

  @override
  Future<CombatActionResult> execute() async {
    final logs = <String>[];
    int totalDamage = 0;
    final statusesApplied = <String>[];
    int enemiesDefeated = 0;

    // Get living enemies
    final livingEnemies = enemies.where((e) => e.isAlive).toList();

    // Validate cast
    if (!caster.canCast(spell)) {
      return CombatActionResult(
        logs: [
          'Cannot cast ${spell.displayName} - insufficient mana or actions',
        ],
        soundKey: null,
      );
    }

    // Step 1: Consume resources (this is the "intent resolution")
    caster.consumeForCast(spell);
    logs.add(
      '${caster.name} casts ${spell.displayName} (${spell.manaCost} mana)',
    );

    // Step 2 & 3: Animation and sound (via callback - happens BEFORE damage)
    if (onBeforeApply != null) {
      await onBeforeApply!(spell, targetIndex);
    }

    // Step 4: Delay is handled by the callback

    // Step 5 & 6: Apply damage/effects
    for (final effect in spell.effects) {
      final effectResult = _resolveEffect(
        effect: effect,
        livingEnemies: livingEnemies,
        targetIndex: targetIndex,
      );

      logs.addAll(effectResult.logs);
      totalDamage += effectResult.damageDealt;
      statusesApplied.addAll(effectResult.statusesApplied);
    }

    // Step 7: Check for defeated enemies
    for (final enemy in livingEnemies) {
      if (!enemy.isAlive) {
        logs.add('${enemy.name} is defeated!');
        enemiesDefeated++;
      }
    }

    final result = CombatActionResult(
      logs: logs,
      damageDealt: totalDamage,
      statusesApplied: statusesApplied,
      targetDefeated: enemiesDefeated > 0,
      soundKey: spell.id, // Spell sound key
    );

    // Notify after apply
    onAfterApply?.call(result);

    return result;
  }

  CombatActionResult _resolveEffect({
    required Effect effect,
    required List<Enemy> livingEnemies,
    required int targetIndex,
  }) {
    final logs = <String>[];
    int damage = 0;
    final statuses = <String>[];

    // Determine targets
    List<Enemy> targets;
    switch (effect.targetRule) {
      case TargetRule.single:
        if (targetIndex < livingEnemies.length) {
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
        targets = [];
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
          caster.applyStatusEffect(effect);
          logs.add(
            '${caster.name} gains ${effect.value} Armor for ${effect.duration} turn(s)',
          );
          statuses.add('armor');
          break;
        case EffectType.actionGain:
          caster.actionsRemaining += effect.value;
          logs.add('${caster.name} gains ${effect.value} action(s)');
          break;
        default:
          break;
      }
      return CombatActionResult(logs: logs, statusesApplied: statuses);
    }

    // Handle enemy-targeting effects
    for (final target in targets) {
      if (!target.isAlive) continue;

      switch (effect.type) {
        case EffectType.damage:
          final multiplier = spell.element.getMultiplierAgainst(target.element);
          final baseDamage = effect.value;

          // Calculate weaken
          double weakenMultiplier = 1.0;
          for (final status in caster.statusEffects) {
            if (status.type == EffectType.weaken) {
              weakenMultiplier *= (100 - status.value) / 100.0;
            }
          }

          final finalDamage =
              (baseDamage * multiplier * damageMultiplier * weakenMultiplier)
                  .round();
          final actualDamage = target.takeDamage(finalDamage);

          logs.add('${spell.displayName} hits ${target.name}');

          if (actualDamage > 0 && multiplier != 1.0) {
            logs.add(spell.element.getEffectivenessText(target.element));
          }

          logs.add('Damage: $actualDamage');
          damage += actualDamage;
          break;

        case EffectType.burn:
          target.applyStatusEffect(effect);
          logs.add(
            'Burn applied to ${target.name} (${effect.value}/turn for ${effect.duration} turns)',
          );
          statuses.add('burn');
          break;

        case EffectType.slow:
          target.applyStatusEffect(effect);
          logs.add('Slow applied to ${target.name}');
          statuses.add('slow');
          break;

        case EffectType.weaken:
          target.applyStatusEffect(effect);
          logs.add('Weaken applied to ${target.name} (-${effect.value}%)');
          statuses.add('weaken');
          break;

        case EffectType.delay:
          target.isDelayed = true;
          logs.add('${target.name} is delayed!');
          statuses.add('delay');
          break;

        default:
          break;
      }
    }

    return CombatActionResult(
      logs: logs,
      damageDealt: damage,
      statusesApplied: statuses,
    );
  }
}

/// Enemy attack action.
class EnemyAttackAction extends CombatAction {
  final Enemy enemy;
  final Mage target;

  /// Callback invoked BEFORE damage is applied.
  final Future<void> Function(Enemy enemy)? onBeforeApply;

  /// Callback invoked AFTER damage is applied.
  final void Function(int damage)? onAfterApply;

  EnemyAttackAction({
    required this.enemy,
    required this.target,
    this.onBeforeApply,
    this.onAfterApply,
  }) : super(
         type: CombatActionType.enemyAttack,
         description: '${enemy.name} attacks',
       );

  @override
  Future<CombatActionResult> execute() async {
    final logs = <String>[];

    // Step 1: Intent is already resolved (enemy.intent == attack)

    // Step 2 & 3: Animation and sound (via callback)
    if (onBeforeApply != null) {
      await onBeforeApply!(enemy);
    }

    // Step 5: Apply damage
    final damage = enemy.getEffectiveDamage();
    final actualDamage = target.takeDamage(damage);

    logs.add(
      '⚔️  ${enemy.name} attacks ${target.name} for $actualDamage damage!',
    );
    logs.add('→ ${target.name} HP: ${target.currentHP}/${target.maxHP}');

    // Notify after
    onAfterApply?.call(actualDamage);

    return CombatActionResult(
      logs: logs,
      damageDealt: actualDamage,
      targetDefeated: !target.isAlive,
      soundKey: 'enemy_attack',
    );
  }
}

/// Enemy defend action.
class EnemyDefendAction extends CombatAction {
  final Enemy enemy;

  /// Callback invoked when defending.
  final Future<void> Function(Enemy enemy)? onExecute;

  EnemyDefendAction({required this.enemy, this.onExecute})
    : super(
        type: CombatActionType.enemyDefend,
        description: '${enemy.name} defends',
      );

  @override
  Future<CombatActionResult> execute() async {
    // Callback for animation/sound
    if (onExecute != null) {
      await onExecute!(enemy);
    }

    // Apply armor
    enemy.applyStatusEffect(
      Effect(type: EffectType.armor, value: enemy.armorGain, duration: 2),
    );

    return CombatActionResult(
      logs: ['🛡️  ${enemy.name} defends, gaining ${enemy.armorGain} armor.'],
      soundKey: 'armor',
    );
  }
}

/// Enemy debuff action.
class EnemyDebuffAction extends CombatAction {
  final Enemy enemy;
  final Mage target;

  /// Callback invoked when debuffing.
  final Future<void> Function(Enemy enemy)? onExecute;

  EnemyDebuffAction({required this.enemy, required this.target, this.onExecute})
    : super(
        type: CombatActionType.enemyDebuff,
        description: '${enemy.name} debuffs',
      );

  @override
  Future<CombatActionResult> execute() async {
    // Callback for animation/sound
    if (onExecute != null) {
      await onExecute!(enemy);
    }

    // Apply weaken
    target.applyStatusEffect(
      Effect(type: EffectType.weaken, value: 15, duration: 2),
    );

    return CombatActionResult(
      logs: [
        '💀 ${enemy.name} weakens ${target.name}! (-15% damage for 2 turns)',
      ],
      statusesApplied: ['weaken'],
      soundKey: 'debuff',
    );
  }
}

/// Status effect tick action (e.g., burn damage).
class StatusTickAction extends CombatAction {
  final String targetName;
  final bool isPlayer;
  final EffectType effectType;
  final int value;

  /// Callback to apply the status tick.
  final Future<int> Function()? onApply;

  StatusTickAction({
    required this.targetName,
    required this.isPlayer,
    required this.effectType,
    required this.value,
    this.onApply,
  }) : super(
         type: CombatActionType.statusTick,
         description: '${effectType.name} ticks on $targetName',
       );

  @override
  Future<CombatActionResult> execute() async {
    int damage = 0;
    String? soundKey;

    if (onApply != null) {
      damage = await onApply!();
    }

    if (effectType == EffectType.burn) {
      soundKey = 'burn';
    }

    return CombatActionResult(
      logs: ['🔥 $targetName takes $damage burn damage'],
      damageDealt: damage,
      soundKey: soundKey,
    );
  }
}

/// Combat action queue that serializes all combat actions.
///
/// Ensures:
/// - Actions resolve fully before the next starts
/// - Animations/sounds play before state changes
/// - Proper sequencing of multi-hit/combo actions
class CombatActionQueue {
  final List<CombatAction> _queue = [];
  bool _isProcessing = false;
  bool _isPaused = false;

  /// Callback invoked after each action completes.
  final void Function(CombatActionResult result)? onActionComplete;

  /// Callback invoked when the queue is empty.
  final void Function()? onQueueEmpty;

  CombatActionQueue({this.onActionComplete, this.onQueueEmpty});

  /// Add an action to the queue.
  void enqueue(CombatAction action) {
    _queue.add(action);
    _processQueue();
  }

  /// Add multiple actions to the queue.
  void enqueueAll(List<CombatAction> actions) {
    _queue.addAll(actions);
    _processQueue();
  }

  /// Clear the queue (e.g., on combat end).
  void clear() {
    _queue.clear();
    _isProcessing = false;
    _isPaused = false;
  }

  /// Pause queue processing.
  void pause() {
    _isPaused = true;
  }

  /// Resume queue processing.
  void resume() {
    _isPaused = false;
    _processQueue();
  }

  /// Check if queue is empty.
  bool get isEmpty => _queue.isEmpty;

  /// Check if currently processing.
  bool get isProcessing => _isProcessing;

  /// Process the queue.
  Future<void> _processQueue() async {
    if (_isProcessing || _isPaused) return;
    if (_queue.isEmpty) {
      onQueueEmpty?.call();
      return;
    }

    _isProcessing = true;

    while (_queue.isNotEmpty && !_isPaused) {
      final action = _queue.removeAt(0);

      try {
        final result = await action.execute();
        onActionComplete?.call(result);
      } catch (e) {
        print('CombatActionQueue: Error executing action: $e');
      }
    }

    _isProcessing = false;

    if (_queue.isEmpty) {
      onQueueEmpty?.call();
    }
  }
}
