import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../../systems/combat_system.dart';
import '../../systems/shop_system.dart';
import '../../systems/audio_manager.dart';
import '../../domain/mage.dart';
import '../../domain/enemy.dart';
import '../../domain/elite_enemy.dart';
import '../../domain/boss_enemy.dart';
import '../../game/game_loop.dart'; // Import GameLoop
import '../../data/item_definitions.dart'; // Import ItemRegistry
import '../../domain/spell.dart';
import '../../domain/effect.dart';
import '../../narrative/journey_log.dart';
import '../../nodes/node_map_system.dart';
import '../../systems/node_resolver.dart';
import '../../systems/exp_system.dart';
import '../components/components.dart';
import 'battle_scene.dart';
import 'status_bars.dart';
import 'battle_action_menu.dart';
import 'floating_damage.dart';

import '../utils/game_colors.dart';
import 'sprite_overlay.dart';

/// Configurable timing delays for battle flow.
/// All values in milliseconds.
/// Note: Reduced from original values to eliminate lag perception.
class BattleTiming {
  /// Delay after showing effectiveness message.
  static const int effectivenessDisplay = 600; // Was 800

  /// Delay after showing damage result.
  static const int damageResultDisplay = 600; // Was 900

  /// Delay after enemy fainted message.
  static const int enemyFaintedDisplay = 800; // Was 1100

  /// Delay after enemy damage display.
  static const int enemyDamageDisplay = 500; // Was 700

  /// Delay for enemy non-attack actions (defend, debuff).
  static const int enemyOtherActionDisplay = 500; // Was 700
}

/// Combat phases for Pokémon-style sequential combat.
enum CombatPhase {
  playerSelect, // Player choosing action
  playerAction, // Playing player's attack animation/text
  enemyAction, // Playing enemy's attack animation/text
  turnTransition, // Brief pause between turns
  combatEnd, // Victory/defeat
}

/// Battle screen with Pokémon-style turn-based combat flow.
///
/// Flow:
/// 1. Player selects action (Fight menu)
/// 2. "Mage used [Spell]!" → Animation → "It's super effective!" → Damage
/// 3. Enemy turn: "[Enemy] attacks!" → Animation → Damage to player
/// 4. Return to step 1
class BattleScreen extends StatefulWidget {
  final CombatSystem combat;
  final Mage mage;
  final List<Enemy> enemies;
  final NodeMapSystem nodeMapSystem;
  final JourneyLog journeyLog;
  final int currentDepth;
  final int totalDepths;
  final int runNumber;
  final List<TemporaryBuff>? temporaryBuffs;
  final VoidCallback? onCombatEnd;
  final VoidCallback? onRetreat;
  final void Function(String)? onInput;
  final GameLoop? gameLoop; // Add GameLoop

  const BattleScreen({
    super.key,
    required this.combat,
    required this.mage,
    required this.enemies,
    required this.nodeMapSystem,
    required this.journeyLog,
    required this.currentDepth,
    required this.totalDepths,
    this.runNumber = 1,
    this.temporaryBuffs,
    this.onCombatEnd,
    this.onRetreat,
    this.onInput,
    this.gameLoop, // Optional for now to avoid breaking tests/previews immediately
  });

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late BattleScene _battleScene;

  // Combat phase state machine
  CombatPhase _phase = CombatPhase.playerSelect;

  // UI State
  BattleMenuState _menuState = BattleMenuState.root;
  Spell? _inspectedSpell;
  int? _selectedEnemyIndex;
  Spell? _pendingSpell;

  // Dialog text (Pokémon-style narration)
  String _dialogText = '';
  bool _waitingForTap = false;
  VoidCallback? _onTapContinue;

  // Combat Log (for reference)
  final List<CombatLogEntry> _combatLogEntries = [];
  bool _showCombatLog = false;

  // Battle inspection overlay
  bool _showBattleInspection = false;

  // Floating damage controller
  final FloatingDamageController _damageController = FloatingDamageController();

  // Action sequence ID - incremented when a new action starts.
  // Pending events check this to see if they should still execute.
  int _actionSequenceId = 0;

  // EXP Animation State
  int? _animCurrentExp;
  int? _animMaxExp;
  int? _animLevel;

  @override
  void initState() {
    super.initState();
    _battleScene = BattleScene(
      mage: widget.mage,
      enemies: widget.enemies,
      onDamageDealt: _onDamageDealt,
      onStatusApplied: _onStatusApplied,
    );
    // Player always selects action first (Pokémon-style)
    // Speed determines execution order AFTER selection
    _setDialogText('What will ${widget.mage.name} do?');
  }

  /// Start a new action sequence, invalidating all pending events from previous sequences.
  int _startNewActionSequence() {
    _actionSequenceId++;
    AudioManager.instance.clearSfxQueue();
    return _actionSequenceId;
  }

  /// Check if the given sequence ID is still the current one.
  bool _isSequenceValid(int sequenceId) {
    return sequenceId == _actionSequenceId && mounted;
  }

  /// Delayed execution that respects action sequence cancellation.
  Future<void> _delayedAction(
    int sequenceId,
    int milliseconds,
    VoidCallback action,
  ) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
    if (_isSequenceValid(sequenceId)) {
      action();
    }
  }

  void _onDamageDealt(int index, int damage, bool isPlayer) {
    _damageController.showDamage(
      targetIndex: index,
      damage: damage,
      isPlayer: isPlayer,
    );
  }

  void _onStatusApplied(int index, String status, bool isPlayer) {
    _damageController.showStatus(
      targetIndex: index,
      status: status,
      isPlayer: isPlayer,
    );
  }

  void _setDialogText(
    String text, {
    bool waitForTap = false,
    VoidCallback? onTap,
  }) {
    setState(() {
      _dialogText = text;
      _waitingForTap = waitForTap;
      _onTapContinue = onTap;
    });
  }

  void _handleDialogTap() {
    if (_waitingForTap && _onTapContinue != null) {
      _onTapContinue!();
    }
  }

  // ==================== MENU ACTIONS ====================

  void _handleMenuAction(BattleMenuAction action) {
    if (_phase != CombatPhase.playerSelect) return;

    switch (action) {
      case BattleMenuAction.spells:
        setState(() => _menuState = BattleMenuState.spellSelect);
        _setDialogText('Choose a spell to cast.');
        break;
      case BattleMenuAction.inspect:
        setState(() => _showBattleInspection = true);
        break;
      case BattleMenuAction.items:
        _showInventoryDialog();
        break;
      case BattleMenuAction.retreat:
        _handleRetreat();
        break;
      case BattleMenuAction.back:
        setState(() {
          _menuState = BattleMenuState.root;
          _pendingSpell = null;
        });
        _setDialogText('What will ${widget.mage.name} do?');
        break;
      case BattleMenuAction.endTurn:
        _startEnemyPhase();
        break;
    }
  }

  void _handleSpellSelect(Spell spell) {
    if (_phase != CombatPhase.playerSelect) return;

    if (!widget.mage.canCast(spell)) {
      _setDialogText('Not enough mana to cast ${spell.name}!');
      return;
    }

    final needsTarget = spell.effects.any(
      (e) => e.targetRule == TargetRule.single,
    );

    if (needsTarget && widget.combat.livingEnemies.length > 1) {
      setState(() {
        _pendingSpell = spell;
        _menuState = BattleMenuState.targetSelect;
      });
      _setDialogText('Choose a target for ${spell.name}.');
    } else {
      _executePlayerSpell(spell, 0);
    }
  }

  void _handleTargetSelect(int enemyIndex) {
    if (_pendingSpell != null) {
      _executePlayerSpell(_pendingSpell!, enemyIndex);
    }
  }

  // ==================== PLAYER ACTION PHASE ====================

  /// Pokémon-style turn execution:
  /// 1. Player selects action (already done when this is called)
  /// 2. Speed determines execution order
  /// 3. Faster combatant attacks first, then slower
  /// 4. Turn ends
  Future<void> _executePlayerSpell(Spell spell, int targetIndex) async {
    final spellIndex = widget.mage.spellLoadout.indexOf(spell);
    if (spellIndex < 0) return;

    final enemies = widget.combat.livingEnemies;
    if (enemies.isEmpty) return;

    final enemy = enemies[targetIndex.clamp(0, enemies.length - 1)];

    // Start new action sequence - cancels any pending events from previous actions
    final seqId = _startNewActionSequence();

    // Transition to action phase
    setState(() {
      _phase = CombatPhase.playerAction;
      _menuState = BattleMenuState.root;
      _pendingSpell = null;
    });

    // Check speed: if enemy is faster, enemy attacks first BEFORE player spell
    if (widget.combat.enemyGoesFirst) {
      // Enemy attacks first
      await _executeEnemyFirstThenPlayer(
        seqId,
        spell,
        spellIndex,
        targetIndex,
        enemy,
      );
    } else {
      // Player attacks first (normal flow)
      await _executePlayerFirstThenEnemy(
        seqId,
        spell,
        spellIndex,
        targetIndex,
        enemy,
      );
    }
  }

  /// Execute when player is faster: player spell → enemy attack → turn end
  Future<void> _executePlayerFirstThenEnemy(
    int seqId,
    Spell spell,
    int spellIndex,
    int targetIndex,
    Enemy enemy,
  ) async {
    // Show spell cast message
    _setDialogText('${widget.mage.name} used ${spell.name}!');
    _battleScene.playMageCast();

    _logCombat(
      CombatLogBuilder.spellCast(
        widget.mage.name,
        spell.name,
        spell.element.displayName,
      ),
    );

    // Wait for sound to finish
    await AudioManager.instance.playSpellSfxAndWait(spell.id);
    if (!_isSequenceValid(seqId)) return;

    // Apply player damage
    _applyPlayerSpellDamage(seqId, spell, spellIndex, targetIndex, enemy);
  }

  /// Execute when enemy is faster: enemy attack → player spell → turn end
  Future<void> _executeEnemyFirstThenPlayer(
    int seqId,
    Spell spell,
    int spellIndex,
    int targetIndex,
    Enemy enemy,
  ) async {
    // Store the spell info for after enemy attack
    _pendingSpellForAfterEnemy = (spell, spellIndex, targetIndex, enemy);
    _currentSeqIdForEnemyFirst = seqId;

    // Prepare enemy phase (get intents without ending player turn)
    _cachedEnemyActions = widget.combat.prepareInitialEnemyPhase();

    if (_cachedEnemyActions.isEmpty) {
      // No enemies to act, proceed with player spell
      await _continueWithPlayerSpell(seqId);
      return;
    }

    // Execute enemy actions, then continue with player spell
    _executeEnemyActionThenPlayerSpell(0);
  }

  /// Stored spell info for when enemy attacks first
  (Spell, int, int, Enemy)? _pendingSpellForAfterEnemy;
  int _currentSeqIdForEnemyFirst = 0;

  /// Execute enemy action, then proceed with player's pending spell
  Future<void> _executeEnemyActionThenPlayerSpell(int index) async {
    final seqId = _currentSeqIdForEnemyFirst;

    if (index >= _cachedEnemyActions.length) {
      // All enemies have acted, now player's spell executes
      await _continueWithPlayerSpell(seqId);
      return;
    }

    final (enemyActor, intent) = _cachedEnemyActions[index];

    if (!enemyActor.isAlive) {
      _executeEnemyActionThenPlayerSpell(index + 1);
      return;
    }

    // Show enemy intent and play sound
    final intentText = intent.vagueDescription;
    _setDialogText('${enemyActor.name} $intentText');

    switch (intent) {
      case EnemyIntent.attack:
        await AudioManager.instance.playSfxAndWait('enemy_attack');
        break;
      case EnemyIntent.defend:
        await AudioManager.instance.playSfxAndWait('armor');
        break;
      case EnemyIntent.debuff:
        await AudioManager.instance.playSfxAndWait('debuff');
        break;
      case EnemyIntent.spell:
        await AudioManager.instance.playSfxAndWait('spell_cast');
        break;
    }

    if (!_isSequenceValid(seqId) || !mounted) return;

    // Apply enemy action
    final result = widget.combat.executeEnemyActionManual(enemyActor, intent);

    if (result.skipped) {
      _setDialogText('${enemyActor.name} is stunned and skips their turn!');
      await Future.delayed(
        const Duration(milliseconds: BattleTiming.enemyOtherActionDisplay),
      );
      if (_isSequenceValid(seqId)) {
        _executeEnemyActionThenPlayerSpell(index + 1);
      }
      return;
    }

    // Show result
    switch (intent) {
      case EnemyIntent.attack:
        _onDamageDealt(0, result.damageDealt, true);
        _setDialogText(
          '${widget.mage.name} took ${result.damageDealt} damage!',
        );

        await Future.delayed(
          const Duration(milliseconds: BattleTiming.enemyDamageDisplay),
        );
        if (!_isSequenceValid(seqId)) return;

        // Check if player died
        if (result.targetDefeated || !widget.mage.isAlive) {
          AudioManager.instance.playPlayerDefeat();
          _checkCombatEnd();
          return;
        }
        break;

      case EnemyIntent.defend:
        _setDialogText('${enemyActor.name} is defending!');
        await Future.delayed(
          const Duration(milliseconds: BattleTiming.enemyOtherActionDisplay),
        );
        break;

      case EnemyIntent.debuff:
        _setDialogText('${enemyActor.name} weakens ${widget.mage.name}!');
        await Future.delayed(
          const Duration(milliseconds: BattleTiming.enemyOtherActionDisplay),
        );
        break;

      case EnemyIntent.spell:
        final spell = enemyActor.pendingSpell;
        if (spell != null) {
          _setDialogText('${enemyActor.name} casts ${spell.name}!');
        } else {
          _setDialogText('${enemyActor.name} casts a spell!');
        }
        _onDamageDealt(0, result.damageDealt, true);
        await Future.delayed(
          const Duration(milliseconds: BattleTiming.damageResultDisplay),
        );
        if (!_isSequenceValid(seqId)) return;
        if (result.targetDefeated || !widget.mage.isAlive) {
          AudioManager.instance.playPlayerDefeat();
          _checkCombatEnd();
          return;
        }
        break;
    }

    if (!_isSequenceValid(seqId)) return;

    // Next enemy or continue to player spell
    _executeEnemyActionThenPlayerSpell(index + 1);
  }

  /// Continue with player's spell after enemy has attacked first
  Future<void> _continueWithPlayerSpell(int seqId) async {
    if (!_isSequenceValid(seqId) || !mounted) return;
    if (_pendingSpellForAfterEnemy == null) return;

    final (spell, spellIndex, targetIndex, enemy) = _pendingSpellForAfterEnemy!;
    _pendingSpellForAfterEnemy = null;

    // Check if player is still alive
    if (!widget.mage.isAlive) {
      _checkCombatEnd();
      return;
    }

    // Now execute player spell
    _setDialogText('${widget.mage.name} used ${spell.name}!');
    _battleScene.playMageCast();

    _logCombat(
      CombatLogBuilder.spellCast(
        widget.mage.name,
        spell.name,
        spell.element.displayName,
      ),
    );

    await AudioManager.instance.playSpellSfxAndWait(spell.id);
    if (!_isSequenceValid(seqId)) return;

    // Apply player damage - but need to re-check target
    final enemies = widget.combat.livingEnemies;
    if (enemies.isEmpty) {
      // All enemies died from something, check combat end
      _checkCombatEnd();
      return;
    }

    final currentEnemy = enemies[targetIndex.clamp(0, enemies.length - 1)];
    _applyPlayerSpellDamageAfterEnemy(
      seqId,
      spell,
      spellIndex,
      targetIndex,
      currentEnemy,
    );
  }

  /// Apply player spell damage after enemy has already attacked (skip enemy phase after)
  void _applyPlayerSpellDamageAfterEnemy(
    int seqId,
    Spell spell,
    int spellIndex,
    int targetIndex,
    Enemy enemy,
  ) {
    if (!_isSequenceValid(seqId)) return;

    final result = widget.combat.castSpell(
      spellIndex,
      targetIndex: targetIndex,
    );

    if (result == null || !result.success) {
      _setDialogText('But it failed...');
      _afterPlayerActionSkipEnemyPhase(seqId);
      return;
    }

    // Play sounds for defeated enemies
    if (result.enemiesDefeated > 0) {
      bool bossDead = false, eliteDead = false;
      for (final e in widget.enemies) {
        if (!e.isAlive) {
          if (e is BossEnemy) {
            bossDead = true;
          } else if (e is EliteEnemy)
            eliteDead = true;
        }
      }
      if (bossDead) {
        AudioManager.instance.playSfx('boss_death');
      } else if (eliteDead)
        AudioManager.instance.playSfx('elite_death');
      else
        AudioManager.instance.playEnemyDeath();
    }

    // Show floating damage
    if (result.totalDamage > 0) {
      _onDamageDealt(targetIndex, result.totalDamage, false);
      _logCombat(CombatLogBuilder.damage(enemy.name, result.totalDamage));
    }

    // Effectiveness message
    final multiplier = spell.element.getMultiplierAgainst(enemy.element);
    if (multiplier > 1.0) {
      _setDialogText("It's super effective!");
      _delayedAction(seqId, BattleTiming.effectivenessDisplay, () {
        _showDamageResultSkipEnemy(seqId, enemy, result.totalDamage);
      });
    } else if (multiplier < 1.0) {
      _setDialogText("It's not very effective...");
      _delayedAction(seqId, BattleTiming.effectivenessDisplay, () {
        _showDamageResultSkipEnemy(seqId, enemy, result.totalDamage);
      });
    } else {
      _showDamageResultSkipEnemy(seqId, enemy, result.totalDamage);
    }
  }

  void _showDamageResultSkipEnemy(int seqId, Enemy enemy, int damage) {
    if (!_isSequenceValid(seqId)) return;

    if (!enemy.isAlive) {
      _setDialogText('${enemy.name} fainted!');
      _delayedAction(seqId, BattleTiming.enemyFaintedDisplay, () {
        _afterPlayerActionSkipEnemyPhase(seqId);
      });
    } else {
      _setDialogText('${enemy.name} took $damage damage!');
      _delayedAction(seqId, BattleTiming.damageResultDisplay, () {
        _afterPlayerActionSkipEnemyPhase(seqId);
      });
    }
  }

  /// After player action when enemy has already attacked this turn
  void _afterPlayerActionSkipEnemyPhase(int seqId) {
    if (!_isSequenceValid(seqId)) return;

    // Check for combat end
    if (_checkCombatEnd()) return;

    // Finalize the turn (status effects, etc.) then start new turn
    widget.combat.finalizeEnemyPhase();
    if (_checkCombatEnd()) return;

    // Check if player can still act (multi-action)
    if (widget.combat.canPlayerAct) {
      setState(() => _phase = CombatPhase.playerSelect);
      _setDialogText('What will ${widget.mage.name} do?');
    } else {
      _startNewPlayerTurn();
    }
  }

  /// Apply spell damage and show results (called after animation + sound).
  void _applyPlayerSpellDamage(
    int seqId,
    Spell spell,
    int spellIndex,
    int targetIndex,
    Enemy enemy,
  ) {
    if (!_isSequenceValid(seqId)) return;

    // NOW apply the actual spell effect
    final result = widget.combat.castSpell(
      spellIndex,
      targetIndex: targetIndex,
    );

    if (result == null || !result.success) {
      _setDialogText('But it failed...');
      _afterPlayerAction(seqId);
      return;
    }

    // Play additional sounds based on result
    if (result.enemiesDefeated > 0) {
      bool bossDead = false;
      bool eliteDead = false;

      for (final enemy in widget.enemies) {
        if (!enemy.isAlive) {
          if (enemy is BossEnemy) {
            bossDead = true;
          } else if (enemy is EliteEnemy)
            eliteDead = true;
        }
      }

      // We don't await death sounds because we want to flow into victory check/UI updates
      if (bossDead) {
        AudioManager.instance.playSfx('boss_death');
      } else if (eliteDead) {
        AudioManager.instance.playSfx('elite_death');
      } else {
        AudioManager.instance.playEnemyDeath();
      }
    }

    // Check for status effects applied
    for (final log in result.logs) {
      if (log.contains('Slow applied') || log.contains('Weaken applied')) {
        AudioManager.instance.playDebuff();
        break;
      }
    }

    // Check elemental effectiveness
    final multiplier = spell.element.getMultiplierAgainst(enemy.element);
    String effectivenessMsg = '';
    if (multiplier > 1.0) {
      effectivenessMsg = "It's super effective!";
    } else if (multiplier < 1.0) {
      effectivenessMsg = "It's not very effective...";
    }

    // Show floating damage number
    if (result.totalDamage > 0) {
      _onDamageDealt(targetIndex, result.totalDamage, false);
      _logCombat(CombatLogBuilder.damage(enemy.name, result.totalDamage));
    }

    // Show effectiveness message or damage result
    if (effectivenessMsg.isNotEmpty) {
      _setDialogText(effectivenessMsg);
      _delayedAction(seqId, BattleTiming.effectivenessDisplay, () {
        _showDamageResult(seqId, enemy, result.totalDamage);
      });
    } else {
      _showDamageResult(seqId, enemy, result.totalDamage);
    }
  }

  void _showDamageResult(int seqId, Enemy enemy, int damage) {
    if (!_isSequenceValid(seqId)) return;

    if (!enemy.isAlive) {
      _setDialogText('${enemy.name} fainted!');
      _delayedAction(seqId, BattleTiming.enemyFaintedDisplay, () {
        _afterPlayerAction(seqId);
      });
    } else {
      _setDialogText('${enemy.name} took $damage damage!');
      _delayedAction(seqId, BattleTiming.damageResultDisplay, () {
        _afterPlayerAction(seqId);
      });
    }
  }

  void _afterPlayerAction(int seqId) {
    if (!_isSequenceValid(seqId)) return;

    // Check for combat end
    if (_checkCombatEnd()) return;

    // Check if player can still act
    if (widget.combat.canPlayerAct) {
      // Player has more actions, return to selection
      setState(() => _phase = CombatPhase.playerSelect);
      _setDialogText('What will ${widget.mage.name} do?');
    } else {
      // No more actions, proceed to enemy phase
      _startEnemyPhase();
    }
  }

  // ==================== INVENTORY UI ====================

  void _showInventoryDialog() {
    if (widget.gameLoop == null) {
      _setDialogText('Inventory unavailable.');
      return;
    }

    // Access inventory via GameLoop -> GameState
    final consumables =
        widget.gameLoop!.state.inventory.progression.consumables;

    if (consumables.isEmpty) {
      _setDialogText('Your inventory is empty.');
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF161b22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade800),
          ),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'INVENTORY',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: Builder(
                    builder: (context) {
                      // Group items by ID to count quantities
                      final Map<String, int> counts = {};
                      for (final id in consumables) {
                        counts[id] = (counts[id] ?? 0) + 1;
                      }

                      final uniqueIds = counts.keys.toList();

                      return GridView.builder(
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: uniqueIds.length,
                        itemBuilder: (context, index) {
                          final itemId = uniqueIds[index];
                          final count = counts[itemId] ?? 0;
                          final itemDef = ItemRegistry.getItem(itemId);

                          if (itemDef == null) return const SizedBox.shrink();

                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF21262d),
                              border: Border.all(
                                color: const Color(0xFF30363d),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _useItem(itemId, itemDef.name);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        '🧪',
                                        style: TextStyle(fontSize: 24),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        itemDef.name,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF161b22),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF30363d),
                                          ),
                                        ),
                                        child: Text(
                                          'x$count',
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF58a6ff),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    child: const Text(
                      'CLOSE',
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _useItem(String itemId, String itemName) {
    if (widget.gameLoop == null) return;

    // Use the item
    final resultMsg = widget.gameLoop!.useConsumable(itemId);

    // Show result
    _setDialogText('Used $itemName! $resultMsg');

    // Play sound?
    AudioManager.instance.playSfx(
      'potion_use',
    ); // Assuming sound exists or will check

    // End turn? Usually items take a turn.
    // Pokemon style: Items take a turn.
    // "Mage used Potion!" -> Result -> Enemy Turn.
    _delayedAction(
      _startNewActionSequence(),
      BattleTiming.damageResultDisplay,
      () {
        _startEnemyPhase();
      },
    );
  }

  // ==================== ENEMY ACTION PHASE ====================

  /// Cached enemy actions for manual execution (enemy, intent pairs).
  List<(Enemy, EnemyIntent)> _cachedEnemyActions = [];

  /// Current enemy phase sequence ID.
  int _enemyPhaseSeqId = 0;

  /// Start enemy phase with UI-controlled timing.
  ///
  /// Uses prepareEnemyPhase to capture intents WITHOUT applying damage,
  /// then executes each action with proper timing: Intent+Sound → Delay → Damage.
  void _startEnemyPhase() {
    // Start new sequence for enemy phase
    _enemyPhaseSeqId = _startNewActionSequence();

    setState(() => _phase = CombatPhase.enemyAction);

    // Prepare phase and get enemy actions without executing them
    _cachedEnemyActions = widget.combat.prepareEnemyPhase();
    _logCombat(CombatLogBuilder.turnMarker(widget.combat.currentTurn));

    // Check if no enemies (edge case)
    if (_cachedEnemyActions.isEmpty) {
      _finalizeEnemyPhase();
      return;
    }

    // Execute each enemy's action sequentially with proper timing
    _executeEnemyActionWithTiming(0);
  }

  /// Execute a single enemy action with proper timing sequence:
  /// 1. Show intent message + play sound IMMEDIATELY
  /// 2. WAIT for sound to finish
  /// 3. Apply damage
  /// 4. Show result
  /// 5. Next enemy or finalize
  Future<void> _executeEnemyActionWithTiming(int index) async {
    final seqId = _enemyPhaseSeqId;

    if (index >= _cachedEnemyActions.length) {
      _finalizeEnemyPhase();
      return;
    }

    final (enemy, intent) = _cachedEnemyActions[index];

    // Check if enemy is still alive (might have died from burn, etc.)
    if (!enemy.isAlive) {
      _executeEnemyActionWithTiming(index + 1);
      return;
    }

    // STEP 1: Show enemy intent AND play sound IMMEDIATELY
    final intentText = intent.vagueDescription;
    _setDialogText('${enemy.name} $intentText');

    switch (intent) {
      case EnemyIntent.attack:
        await AudioManager.instance.playSfxAndWait('enemy_attack');
        break;
      case EnemyIntent.defend:
        await AudioManager.instance.playSfxAndWait('armor');
        break;
      case EnemyIntent.debuff:
        await AudioManager.instance.playSfxAndWait('debuff');
        break;
      case EnemyIntent.spell:
        await AudioManager.instance.playSfxAndWait('spell_cast');
        break;
    }

    // Check validity after await
    if (_enemyPhaseSeqId != seqId || !mounted) return;

    // STEP 2: Apply damage immediately after sound
    _applyEnemyAction(seqId, index, enemy, intent);
  }

  /// Apply enemy action damage and show result.
  void _applyEnemyAction(
    int seqId,
    int index,
    Enemy enemy,
    EnemyIntent intent,
  ) {
    if (!_isSequenceValid(seqId)) return;

    // Apply the action (damage/buff/debuff)
    final result = widget.combat.executeEnemyActionManual(enemy, intent);

    // Handle skipped action (delayed enemy)
    if (result.skipped) {
      _setDialogText('${enemy.name} is stunned and skips their turn!');
      _delayedAction(seqId, BattleTiming.enemyOtherActionDisplay, () {
        _executeEnemyActionWithTiming(index + 1);
      });
      return;
    }

    // Show result based on intent
    switch (intent) {
      case EnemyIntent.attack:
        // Show floating damage
        _onDamageDealt(0, result.damageDealt, true);

        _setDialogText(
          '${widget.mage.name} took ${result.damageDealt} damage!',
        );

        _delayedAction(seqId, BattleTiming.enemyDamageDisplay, () {
          // Check if player died
          if (result.targetDefeated || !widget.mage.isAlive) {
            AudioManager.instance.playPlayerDefeat();
            _checkCombatEnd();
            return;
          }

          // Next enemy
          _executeEnemyActionWithTiming(index + 1);
        });
        break;

      case EnemyIntent.defend:
        _setDialogText('${enemy.name} is defending!');
        _delayedAction(seqId, BattleTiming.enemyOtherActionDisplay, () {
          _executeEnemyActionWithTiming(index + 1);
        });
        break;

      case EnemyIntent.debuff:
        _setDialogText('${enemy.name} weakens ${widget.mage.name}!');
        _delayedAction(seqId, BattleTiming.enemyOtherActionDisplay, () {
          _executeEnemyActionWithTiming(index + 1);
        });
        break;

      case EnemyIntent.spell:
        final spell = enemy.pendingSpell;
        final spellName = spell?.name ?? 'a spell';
        _setDialogText('${enemy.name} casts $spellName!');
        _onDamageDealt(0, result.damageDealt, true);
        _delayedAction(seqId, BattleTiming.damageResultDisplay, () {
          if (result.targetDefeated || !widget.mage.isAlive) {
            AudioManager.instance.playPlayerDefeat();
            _checkCombatEnd();
            return;
          }
          _executeEnemyActionWithTiming(index + 1);
        });
        break;
    }
  }

  /// Finalize enemy phase after all actions complete.
  void _finalizeEnemyPhase() {
    _cachedEnemyActions = [];

    // Let combat system handle status effects and turn transition
    widget.combat.finalizeEnemyPhase();

    // Check for combat end from status effects (burn damage, etc.)
    if (_checkCombatEnd()) return;

    _startNewPlayerTurn();
  }

  void _startNewPlayerTurn() {
    // Check for combat end
    if (_checkCombatEnd()) return;

    setState(() => _phase = CombatPhase.playerSelect);
    _setDialogText('What will ${widget.mage.name} do?');
  }

  // ==================== COMBAT END & RETREAT ====================

  void _handleRetreat() {
    _setDialogText('"Retreat is not failure. It is recognition."');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        if (widget.onRetreat != null) {
          widget.onRetreat!();
        } else {
          widget.onCombatEnd?.call();
        }
      }
    });
  }

  bool _checkCombatEnd() {
    final allEnemiesDead = widget.combat.livingEnemies.isEmpty;
    final playerDead = !widget.mage.isAlive;
    final combatOver = !widget.combat.isOngoing || allEnemiesDead || playerDead;

    if (combatOver) {
      setState(() => _phase = CombatPhase.combatEnd);

      final isVictory = allEnemiesDead && widget.mage.isAlive;
      if (isVictory) {
        // Play victory sound
        AudioManager.instance.playBattleWin();
        _setDialogText('You won the battle!');
        _logCombat(CombatLogBuilder.system('VICTORY'));

        // Trigger EXP Animation
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) _triggerExpAnimation();
        });
      } else {
        // Play defeat sound (if not already played by enemy action)
        AudioManager.instance.playPlayerDefeat();
        _setDialogText('${widget.mage.name} was defeated...');
        _logCombat(CombatLogBuilder.system('DEFEAT'));

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            widget.onCombatEnd?.call();
          }
        });
      }
      return true;
    }
    return false;
  }

  Future<void> _triggerExpAnimation() async {
    // Calculate EXP gain
    // Assuming all enemies defeated on victory
    // Check if Elite or Boss is present in original list
    final isElite = widget.enemies.any((e) => e is EliteEnemy);
    final isBoss = widget.enemies.any((e) => e is BossEnemy);

    final rewards = NodeResolver.calculateCombatReward(
      depth: widget.currentDepth,
      enemiesDefeated: widget.enemies.length,
      isElite: isElite,
      isBoss: isBoss,
    );

    final expGain = rewards['experience'] ?? 0;
    if (expGain <= 0) {
      widget.onCombatEnd?.call();
      return;
    }

    _setDialogText('Gained $expGain EXP!');
    final sfxHandle = await AudioManager.instance.playSfxWithControl(
      AudioManager.sfxExpGain,
    );

    // Initial state
    int startTotalExp =
        ExpSystem.totalExpForLevel(widget.mage.level) + widget.mage.currentExp;
    int targetTotalExp = startTotalExp + expGain;

    // Animation loop (1.5 seconds)
    final steps = 30;
    final duration = const Duration(milliseconds: 1500);
    final stepTime = duration.inMilliseconds ~/ steps;

    for (int i = 1; i <= steps; i++) {
      if (!mounted) {
        if (sfxHandle != null) {
          AudioManager.instance.stopSfx(sfxHandle);
        }
        return;
      }

      final progress = i / steps;
      final currentTotal = (startTotalExp + (expGain * progress)).toInt().clamp(
        startTotalExp,
        targetTotalExp,
      );

      // Resolve level and relative EXP
      final vLevel = ExpSystem.levelForTotalExp(currentTotal);
      final vLevelStartExp = ExpSystem.totalExpForLevel(vLevel);
      final vCurrentExp = currentTotal - vLevelStartExp;
      final vMaxExp = ExpSystem.expToNextLevel(vLevel);

      setState(() {
        _animLevel = vLevel;
        _animCurrentExp = vCurrentExp;
        _animMaxExp = vMaxExp > 0 ? vMaxExp : 1;
      });

      await Future.delayed(Duration(milliseconds: stepTime));
    }

    if (sfxHandle != null) {
      await AudioManager.instance.stopSfx(sfxHandle);
    }

    // Ensure final state
    setState(() {
      final vLevel = ExpSystem.levelForTotalExp(targetTotalExp);
      final vLevelStartExp = ExpSystem.totalExpForLevel(vLevel);
      _animLevel = vLevel;
      _animCurrentExp = targetTotalExp - vLevelStartExp;
      final max = ExpSystem.expToNextLevel(vLevel);
      _animMaxExp = max > 0 ? max : 1;
    });

    if (_animLevel! > widget.mage.level) {
      _setDialogText('Level Up! (${widget.mage.level} \u2192 $_animLevel)');
      AudioManager.instance.playLevelUp();
      await Future.delayed(const Duration(seconds: 2));
    } else {
      await Future.delayed(const Duration(seconds: 1));
    }

    widget.onCombatEnd?.call();
  }

  // Helper just in case imports are missing (ExpSystem is likely needed)
  // Ensure "import '../../systems/exp_system.dart';" is present.
  // It is likely already there or needs adding.

  void _logCombat(CombatLogEntry entry) {
    setState(() {
      _combatLogEntries.add(entry);
      if (_combatLogEntries.length > 50) {
        _combatLogEntries.removeAt(0);
      }
    });
  }

  void _showSpellInspection(Spell spell) {
    setState(() => _inspectedSpell = spell);
  }

  void _hideSpellInspection() {
    setState(() => _inspectedSpell = null);
  }

  void _toggleCombatLog() {
    setState(() => _showCombatLog = !_showCombatLog);
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0d1117),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;

            // Zone heights (Pokémon-style distribution)
            final zone1Height = screenHeight * 0.35; // Enemy area
            final zone2Height = screenHeight * 0.25; // Battlefield
            final zone4Height = screenHeight * 0.25; // Action panel

            return Stack(
              children: [
                // Background battle scene
                Positioned.fill(child: GameWidget(game: _battleScene)),

                // ZONE 1: Enemy area
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: zone1Height + zone2Height * 0.3,
                  child: _buildEnemyZone(constraints.maxWidth),
                ),

                // ZONE 3: Player status (right side)
                Positioned(
                  bottom: zone4Height + 8,
                  right: 16,
                  child: PokemonPlayerStatusPanel(
                    mage: widget.mage,
                    temporaryBuffs: widget.temporaryBuffs,
                    currentExpOverride: _animCurrentExp,
                    maxExpOverride: _animMaxExp,
                    levelOverride: _animLevel,
                  ),
                ),

                // ZONE 4: Dialog + Action panel
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: zone4Height,
                  child: _buildBottomPanel(zone4Height),
                ),

                // Spell inspection overlay
                if (_inspectedSpell != null)
                  Positioned.fill(child: _buildSpellInspectionOverlay()),

                // Battle inspection overlay (Player/Enemy details)
                if (_showBattleInspection)
                  Positioned.fill(
                    child: BattleInspectionOverlay(
                      mage: widget.mage,
                      enemies: widget.combat.livingEnemies,
                      onClose: () =>
                          setState(() => _showBattleInspection = false),
                    ),
                  ),

                // Combat log overlay
                if (_showCombatLog)
                  Positioned(
                    bottom: zone4Height,
                    left: 0,
                    right: 0,
                    child: _buildCombatLogOverlay(),
                  ),

                // Floating damage numbers
                ..._damageController.buildWidgets(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEnemyZone(double screenWidth) {
    return Stack(
      children: [
        Positioned.fill(
          child: EnemySpriteOverlay(
            enemies: widget.combat.livingEnemies,
            highlightedIndex: _menuState == BattleMenuState.targetSelect
                ? _selectedEnemyIndex
                : null,
            onTap:
                (_menuState == BattleMenuState.targetSelect &&
                    _phase == CombatPhase.playerSelect)
                ? (index) => _handleTargetSelect(index)
                : null,
          ),
        ),

        // Enemy status panel
        Positioned(
          top: 80,
          left: 16,
          child: PokemonEnemyStatusPanel(
            enemies: widget.combat.livingEnemies,
            selectedIndex: _selectedEnemyIndex,
          ),
        ),
      ],
    );
  }

  /// Bottom panel with Pokémon-style dialog box and action menu
  Widget _buildBottomPanel(double panelHeight) {
    // For spell select and target select, use full width
    final useFullWidth =
        _menuState == BattleMenuState.spellSelect ||
        _menuState == BattleMenuState.targetSelect;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF21262d),
        border: Border(top: BorderSide(color: Color(0xFF484f58), width: 2)),
      ),
      padding: const EdgeInsets.all(8),
      child: useFullWidth ? _buildFullWidthContent() : _buildDialogAndActions(),
    );
  }

  /// Full width content for spell/target selection
  Widget _buildFullWidthContent() {
    if (_menuState == BattleMenuState.spellSelect) {
      return _buildSpellGrid();
    } else if (_menuState == BattleMenuState.targetSelect) {
      return _buildTargetGrid();
    }
    return const SizedBox();
  }

  /// Spell grid using full width (2x2 + back button)
  Widget _buildSpellGrid() {
    final spells = widget.mage.spellLoadout;

    return Row(
      children: [
        // Spell grid (2x2)
        Expanded(
          child: Column(
            children: [
              // Row 1
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: spells.isNotEmpty
                          ? _buildSpellButton(spells[0])
                          : _buildEmptySlot(),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: spells.length > 1
                          ? _buildSpellButton(spells[1])
                          : _buildEmptySlot(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Row 2
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: spells.length > 2
                          ? _buildSpellButton(spells[2])
                          : _buildEmptySlot(),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: spells.length > 3
                          ? _buildSpellButton(spells[3])
                          : _buildEmptySlot(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Back button
        SizedBox(width: 50, child: _buildBackButton()),
      ],
    );
  }

  Widget _buildSpellButton(Spell spell) {
    final canCast = widget.mage.canCast(spell);
    final textColor = _getSpellTextColor(spell, canCast);

    // Wrap with SpellInspectionWrapper for long-press details
    return SpellInspectionWrapper(
      spell: spell,
      enabled: true,
      child: GestureDetector(
        onTap: canCast ? () => _handleSpellSelect(spell) : null,
        child: Container(
          decoration: BoxDecoration(
            gradient: canCast
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [const Color(0xFF2d333b), const Color(0xFF22272e)],
                  )
                : null,
            color: canCast ? null : const Color(0xFF161b22),
            border: Border.all(
              color: canCast
                  ? GameColors.getElementColorFromString(spell.element.name)
                  : const Color(0xFF30363d),
              width: canCast ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(spell.elementIcon, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      spell.name,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getSpellTextColor(Spell spell, bool canCast) {
    if (!canCast) return const Color(0xFF484f58);
    final enemies = widget.combat.livingEnemies;
    if (enemies.isEmpty) return const Color(0xFFc9d1d9);

    bool hasStrong = false;
    bool hasWeak = false;

    for (final enemy in enemies) {
      final multiplier = spell.element.getMultiplierAgainst(enemy.element);
      if (multiplier > 1.0) hasStrong = true;
      if (multiplier < 1.0) hasWeak = true;
    }

    if (hasStrong && !hasWeak) return const Color(0xFF3fb950); // Green
    if (hasWeak && !hasStrong) return const Color(0xFFf85149); // Red
    if (hasStrong && hasWeak) return const Color(0xFFe3b341); // Yellow
    return const Color(0xFFc9d1d9); // White
  }

  Widget _buildEmptySlot() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        border: Border.all(color: const Color(0xFF21262d), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          '─',
          style: TextStyle(fontSize: 16, color: Color(0xFF484f58)),
        ),
      ),
    );
  }

  /// Target grid using full width
  Widget _buildTargetGrid() {
    final enemies = widget.combat.livingEnemies;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: enemies.asMap().entries.map((entry) {
              final index = entry.key;
              final enemy = entry.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < enemies.length - 1 ? 6 : 0,
                  ),
                  child: _buildTargetButton(enemy, index),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 50, child: _buildBackButton()),
      ],
    );
  }

  Widget _buildTargetButton(Enemy enemy, int index) {
    final hpPercent = (enemy.currentHP / enemy.maxHP).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => _handleTargetSelect(index),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GameColors.getElementColorFromString(
                enemy.element.name,
              ).withValues(alpha: 0.3),
              GameColors.getElementColorFromString(
                enemy.element.name,
              ).withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
            color: GameColors.getElementColorFromString(enemy.element.name),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(enemy.element.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  enemy.name,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFc9d1d9),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // HP bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF363636),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: hpPercent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: hpPercent > 0.5
                          ? const Color(0xFF58d854)
                          : hpPercent > 0.2
                          ? const Color(0xFFf8d030)
                          : const Color(0xFFf85888),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => _handleMenuAction(BattleMenuAction.back),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF21262d),
          border: Border.all(color: const Color(0xFF484f58), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, size: 18, color: Color(0xFF8b949e)),
              SizedBox(height: 2),
              Text(
                'BACK',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: Color(0xFF8b949e),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Standard dialog + action buttons layout
  Widget _buildDialogAndActions() {
    return Row(
      children: [
        // Left side: Dialog text box (60%)
        Expanded(
          flex: 6,
          child: GestureDetector(
            onTap: _handleDialogTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0d1117),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF484f58), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dialogText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  if (_waitingForTap) ...[
                    const SizedBox(height: 4),
                    const Text(
                      '▼ Tap to continue',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Color(0xFF8b949e),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Right side: Action buttons (40%)
        Expanded(flex: 4, child: _buildActionButtons()),
      ],
    );
  }

  Widget _buildActionButtons() {
    // During non-player phases, show waiting state
    if (_phase != CombatPhase.playerSelect) {
      return Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF161b22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF30363d)),
        ),
        child: const Center(
          child: Text(
            '...',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 24,
              color: Color(0xFF8b949e),
            ),
          ),
        ),
      );
    }

    // Combat ended
    if (_phase == CombatPhase.combatEnd) {
      return _buildCombatEndButtons();
    }

    // Player select phase - show action menu
    return Container(
      margin: const EdgeInsets.all(8),
      child: PokemonActionBox(
        state: _menuState,
        mage: widget.mage,
        enemies: widget.combat.livingEnemies,
        onAction: _handleMenuAction,
        onSpellSelect: _handleSpellSelect,
        onSpellLongPress: _showSpellInspection,
        onSpellLongPressEnd: _hideSpellInspection,
        onTargetSelect: _handleTargetSelect,
      ),
    );
  }

  Widget _buildCombatEndButtons() {
    final isVictory =
        widget.combat.livingEnemies.isEmpty && widget.mage.isAlive;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVictory
              ? [const Color(0xFF238636), const Color(0xFF2ea043)]
              : [const Color(0xFFb62324), const Color(0xFFda3633)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          isVictory ? '✨ VICTORY ✨' : '💀 DEFEAT 💀',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSpellInspectionOverlay() {
    return GestureDetector(
      onTap: _hideSpellInspection,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: SpellDetailCard(spell: _inspectedSpell!),
          ),
        ),
      ),
    );
  }

  Widget _buildCombatLogOverlay() {
    return Container(
      height: 160,
      decoration: const BoxDecoration(
        color: Color(0xFF0d1117),
        border: Border(
          top: BorderSide(color: Color(0xFF30363d), width: 1),
          bottom: BorderSide(color: Color(0xFF30363d), width: 1),
        ),
      ),
      child: CombatLogPanel(
        entries: _combatLogEntries,
        isExpanded: true,
        onToggle: _toggleCombatLog,
        compact: false,
      ),
    );
  }
}

/// Enum for battle menu states.
enum BattleMenuState { root, spellSelect, targetSelect, inspect }

/// Enum for battle menu actions.
enum BattleMenuAction { spells, inspect, items, retreat, back, endTurn }
