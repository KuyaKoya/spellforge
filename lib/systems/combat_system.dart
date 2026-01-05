import '../domain/effect.dart';
import '../domain/enemy.dart';
import '../domain/elite_enemy.dart';
import '../domain/boss_enemy.dart';
import '../domain/combat_event.dart';
import '../domain/mage.dart';
import 'spell_system.dart';
import 'audio_system.dart';

/// Represents the state of an ongoing combat.
enum CombatPhase { playerTurn, enemyTurn, statusResolution, victory, defeat }

/// Result of a combat encounter.
class CombatResult {
  final bool playerWon;
  final List<String> fullLog;
  final int turnsElapsed;

  CombatResult({
    required this.playerWon,
    required this.fullLog,
    required this.turnsElapsed,
  });
}

/// Manages turn-based combat between mage and enemies.
class CombatSystem {
  final Mage mage;
  final List<Enemy> enemies;
  final List<String> combatLog;

  /// Callback to notify system of state changes (for UI updates during async operations)
  final Future<void> Function()? onStateChanged;

  /// Damage multiplier from temporary buffs (e.g. Rest Site Train).
  final double damageMultiplier;

  CombatPhase phase;
  int currentTurn;
  bool _playerTurnHeaderLogged = false;

  CombatSystem({
    required this.mage,
    required this.enemies,
    this.damageMultiplier = 1.0,
    this.onStateChanged,
  }) : combatLog = [],
       phase = CombatPhase.playerTurn,
       currentTurn = 1;

  /// Whether combat is still ongoing.
  bool get isOngoing =>
      phase != CombatPhase.victory && phase != CombatPhase.defeat;

  /// Whether it's the player's turn.
  bool get isPlayerTurn => phase == CombatPhase.playerTurn;

  /// All living enemies.
  List<Enemy> get livingEnemies => enemies.where((e) => e.isAlive).toList();

  /// Whether the player can still take actions.
  bool get canPlayerAct {
    if (!isPlayerTurn) return false;
    if (mage.actionsRemaining <= 0) return false;

    // Check if any spell can be cast
    for (final spell in mage.spellLoadout) {
      if (mage.canCast(spell)) return true;
    }
    return false;
  }

  /// Starts combat, resetting states.
  void startCombat() {
    currentTurn = 1;
    phase = CombatPhase.playerTurn;
    mage.resetActions();
    mage.mana = mage.maxMana; // Restore mana at combat start

    combatLog.clear();
    combatLog.add('╔══════════════════════════════════════╗');
    combatLog.add('║         ⚔️  COMBAT START  ⚔️          ║');
    combatLog.add('╚══════════════════════════════════════╝');
    combatLog.add('');
    combatLog.add(
      '${mage.name} encounters ${enemies.length} ${enemies.length == 1 ? 'enemy' : 'enemies'}!',
    );
    combatLog.add('');
    // Phase 7.6.8: Trigger battle start passives for elites
    for (final enemy in enemies) {
      if (enemy is EliteEnemy) {
        enemy.resetTurnState(); // Ensure cleaner start
        final results = enemy.triggerPassives(CombatEvent.battleStart(enemy));
        for (final result in results) {
          if (result.logMessage != null) {
            combatLog.add('  ⚠️ ${result.logMessage}');
          }
        }
      }
    }
    combatLog.add('');

    // Log the first player turn
    _logPlayerTurnHeader();
    _logStatus();
  }

  /// Logs the player turn header.
  void _logPlayerTurnHeader() {
    if (!_playerTurnHeaderLogged) {
      combatLog.add('┌──────────────────────────────────────┐');
      combatLog.add(
        '│  TURN $currentTurn - ${mage.name.toUpperCase()}\'S TURN',
      );
      combatLog.add('└──────────────────────────────────────┘');
      combatLog.add('');
      _playerTurnHeaderLogged = true;
    }
  }

  /// Logs current status of all combatants.
  void _logStatus() {
    combatLog.add('─── YOUR STATUS ───');
    combatLog.add('${mage.name} [Lv.${mage.level}]');
    combatLog.add('  ❤️  HP: ${mage.currentHP}/${mage.maxHP}');
    combatLog.add('  💧 Mana: ${mage.mana}/${mage.maxMana}');
    combatLog.add('  ⚡ Actions: ${mage.actionsRemaining}');
    if (mage.statusEffects.isNotEmpty) {
      combatLog.add(
        '  📋 Effects: ${mage.statusEffects.map((e) => e.displayText).join(', ')}',
      );
    }
    combatLog.add('');

    final living = livingEnemies;
    combatLog.add('─── ENEMIES (${living.length} remaining) ───');
    for (int i = 0; i < living.length; i++) {
      final enemy = living[i];
      combatLog.add('[${i + 1}] ${enemy.name} [${enemy.element.displayName}]');
      combatLog.add('    ❤️  HP: ${enemy.currentHP}/${enemy.maxHP}');
      combatLog.add('    🎯 Intent: ${_getIntentDescription(enemy)}');
      if (enemy.statusEffects.isNotEmpty) {
        combatLog.add(
          '    📋 Effects: ${enemy.statusEffects.map((e) => e.displayText).join(', ')}',
        );
      }
      if (enemy.isDelayed) {
        combatLog.add('    ⏸️  DELAYED');
      }
    }
    combatLog.add('');
  }

  /// Gets a descriptive intent string for an enemy.
  String _getIntentDescription(Enemy enemy) {
    switch (enemy.intent) {
      case EnemyIntent.attack:
        return '⚔️  Attack (${enemy.getEffectiveDamage()} damage)';
      case EnemyIntent.defend:
        return '🛡️  Defend (+${enemy.armorGain} armor)';
      case EnemyIntent.debuff:
        return '💀 Debuff (Weaken -15%)';
    }
  }

  /// Casts a spell at a target. Returns the detailed result.
  SpellCastResult? castSpell(int spellIndex, {int? targetIndex}) {
    if (!isPlayerTurn) return null;
    if (spellIndex < 0 || spellIndex >= mage.spellLoadout.length) return null;

    final spell = mage.spellLoadout[spellIndex];

    // Play spell sound
    AudioSystem.playSpellSound(spell.id);

    final result = SpellSystem.castSpell(
      caster: mage,
      spell: spell,
      enemies: enemies,
      targetIndex: targetIndex ?? 0,
      damageMultiplier: damageMultiplier,
    );

    // Play enemy death sound if any died
    if (result.enemiesDefeated > 0) {
      AudioSystem.playEnemyDeath();
    }

    // Play debuff sound if applied
    for (final log in result.logs) {
      if (log.contains('Slow applied') || log.contains('Weaken applied')) {
        AudioSystem.playDebuff();
        break; // Play once per cast even if multiple applied
      }
    }

    combatLog.addAll(result.logs);
    combatLog.add('');

    // Check for victory
    if (livingEnemies.isEmpty) {
      _endCombat(playerWon: true);
      return result;
    }

    // Log remaining resources after cast
    if (result.success) {
      combatLog.add(
        '  → Remaining: ${mage.mana} mana | ${mage.actionsRemaining} action(s)',
      );
      combatLog.add('');
    }

    return result;
  }

  /// Ends the player's turn.
  Future<void> endPlayerTurn() async {
    if (!isPlayerTurn) return;

    combatLog.add('${mage.name} ends their turn.');
    combatLog.add('');

    _playerTurnHeaderLogged = false;
    phase = CombatPhase.enemyTurn;

    // Notify UI before enemy turn starts
    await onStateChanged?.call();

    await _executeEnemyTurn();
  }

  /// Automatically ends the turn (when no actions/mana left).
  Future<void> autoEndTurn() async {
    combatLog.add('⚠️  No more actions available.');
    await endPlayerTurn();
  }

  /// Executes all enemy actions asynchronously.
  Future<void> _executeEnemyTurn() async {
    combatLog.add('┌──────────────────────────────────────┐');
    combatLog.add('│  TURN $currentTurn - ENEMY TURN');
    combatLog.add('└──────────────────────────────────────┘');
    combatLog.add('');

    await onStateChanged?.call();
    await Future.delayed(const Duration(milliseconds: 500));

    final living = livingEnemies;

    // Phase 7.6.8: Trigger turn start passives for elites
    for (final enemy in living) {
      if (enemy is EliteEnemy) {
        final results = enemy.triggerPassives(
          CombatEvent.turnStart(source: enemy, turnNumber: currentTurn),
        );
        for (final result in results) {
          if (result.logMessage != null) {
            combatLog.add('  ⚠️ ${result.logMessage}');
          }
        }
      }
    }

    for (int i = 0; i < living.length; i++) {
      final enemy = living[i];

      // Delay between enemies
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 800));
      }

      if (enemy.isDelayed) {
        combatLog.add('⏸️  ${enemy.name} is delayed and skips their turn.');
        combatLog.add('');
        await onStateChanged?.call();
        continue;
      }

      combatLog.add('► ${enemy.name}\'s action:');
      await onStateChanged?.call();

      await _executeEnemyAction(enemy);

      // Phase 7.6.8: Handle Relentless elite modifier (double action)
      if (enemy is EliteEnemy && mage.isAlive && enemy.isAlive) {
        if (enemy.canActTwice()) {
          await Future.delayed(const Duration(milliseconds: 600));
          combatLog.add('⚡ ${enemy.name} is Relentless and acts again!');
          await _executeEnemyAction(enemy);
        }
      }

      combatLog.add('');
      await onStateChanged?.call();

      if (!mage.isAlive) {
        _endCombat(playerWon: false);
        return;
      }
    }

    // Phase 7.6.8: Trigger turn end passives for elites
    for (final enemy in living) {
      if (enemy is EliteEnemy && enemy.isAlive) {
        final results = enemy.triggerPassives(
          CombatEvent.turnEnd(source: enemy, turnNumber: currentTurn),
        );
        for (final result in results) {
          if (result.logMessage != null) {
            combatLog.add('  ⚠️ ${result.logMessage}');
          }
        }
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    _resolveStatusEffects();
  }

  /// Executes a single enemy's action based on intent asynchronously.
  Future<void> _executeEnemyAction(Enemy enemy) async {
    switch (enemy.intent) {
      case EnemyIntent.attack:
        // Sync point: Sound -> Wait -> Damage -> Update
        AudioSystem.playEnemyAttack();

        // Wait for impact
        await Future.delayed(const Duration(milliseconds: 400));

        final damage = enemy.getEffectiveDamage();
        final actualDamage = mage.takeDamage(damage);
        combatLog.add('  ⚔️  Attacks ${mage.name} for $actualDamage damage!');
        combatLog.add('  → ${mage.name} HP: ${mage.currentHP}/${mage.maxHP}');

        // Trigger UI update immediately after damage
        onStateChanged?.call();
        break;

      case EnemyIntent.defend:
        AudioSystem.playBuff();
        enemy.applyStatusEffect(
          Effect(type: EffectType.armor, value: enemy.armorGain, duration: 2),
        );
        combatLog.add('  🛡️  Defends, gaining ${enemy.armorGain} armor.');
        onStateChanged?.call();
        break;

      case EnemyIntent.debuff:
        AudioSystem.playDebuff();
        mage.applyStatusEffect(
          Effect(type: EffectType.weaken, value: 15, duration: 2),
        );
        combatLog.add('  💀 Weakens ${mage.name}! (-15% damage for 2 turns)');
        onStateChanged?.call();
        break;
    }

    // Choose next intent
    enemy.chooseNextIntent();
  }

  /// Resolves status effects at turn boundary.
  void _resolveStatusEffects() {
    final hasStatusEffects =
        mage.statusEffects.isNotEmpty ||
        enemies.any((e) => e.isAlive && e.statusEffects.isNotEmpty);

    if (hasStatusEffects) {
      combatLog.add('┌──────────────────────────────────────┐');
      combatLog.add('│  STATUS EFFECTS');
      combatLog.add('└──────────────────────────────────────┘');
      combatLog.add('');

      // Resolve mage status effects
      if (mage.statusEffects.isNotEmpty) {
        combatLog.add('${mage.name}:');
        final mageLogs = mage.processStatusEffects();
        for (final log in mageLogs) {
          if (log.contains('burn damage')) {
            AudioSystem.playBurn();
          }
          combatLog.add('  $log');
        }
        combatLog.add('');
      }

      if (!mage.isAlive) {
        _endCombat(playerWon: false);
        return;
      }

      // Resolve enemy status effects
      for (final enemy in enemies.where((e) => e.isAlive)) {
        if (enemy.statusEffects.isNotEmpty) {
          combatLog.add('${enemy.name}:');
          final enemyLogs = enemy.processStatusEffects();
          for (final log in enemyLogs) {
            if (log.contains('burn damage')) {
              AudioSystem.playBurn();
            }
            combatLog.add('  $log');
          }

          if (!enemy.isAlive) {
            AudioSystem.playEnemyDeath();
            combatLog.add('  💀 ${enemy.name} is defeated by status effects!');
          }
          combatLog.add('');
        }
      }

      // Check for victory after burns
      if (livingEnemies.isEmpty) {
        _endCombat(playerWon: true);
        return;
      }
    }

    // Start new turn
    _startNewTurn();

    // Final UI update
    onStateChanged?.call();
  }

  /// Starts a new player turn.
  void _startNewTurn() {
    currentTurn++;
    phase = CombatPhase.playerTurn;
    _playerTurnHeaderLogged = false;
    mage.resetActions();

    // Reset periodic state for enemies (e.g. Elite damage caps)
    for (final enemy in enemies) {
      if (enemy is EliteEnemy) {
        enemy.resetTurnState();
      }
    }

    // Restore some mana each turn
    final manaRestored = mage.restoreMana(2);

    _logPlayerTurnHeader();

    if (manaRestored > 0) {
      combatLog.add('💧 ${mage.name} recovers $manaRestored mana.');
      combatLog.add('');
    }

    _logStatus();
  }

  /// Ends combat with the given result.
  void _endCombat({required bool playerWon}) {
    phase = playerWon ? CombatPhase.victory : CombatPhase.defeat;

    combatLog.add('');
    combatLog.add('╔══════════════════════════════════════╗');
    if (playerWon) {
      // Check if boss win
      if (enemies.any((e) => e is BossEnemy)) {
        AudioSystem.playBossWin();
      }

      combatLog.add('║         🎉 VICTORY! 🎉               ║');
      combatLog.add('╚══════════════════════════════════════╝');
      combatLog.add('');
      combatLog.add('${mage.name} is triumphant!');
    } else {
      AudioSystem.playBattleDefeat();
      combatLog.add('║         💀 DEFEAT 💀                 ║');
      combatLog.add('╚══════════════════════════════════════╝');
      combatLog.add('');
      combatLog.add('${mage.name} has fallen...');
    }

    // Final update for combat end
    onStateChanged?.call();
  }

  /// Gets the combat result (only valid after combat ends).
  CombatResult? getResult() {
    if (isOngoing) return null;

    return CombatResult(
      playerWon: phase == CombatPhase.victory,
      fullLog: List.from(combatLog),
      turnsElapsed: currentTurn,
    );
  }

  /// Gets available actions for the current state.
  List<String> getAvailableActions() {
    if (!isPlayerTurn) return [];

    final actions = <String>[];

    for (int i = 0; i < mage.spellLoadout.length; i++) {
      final spell = mage.spellLoadout[i];
      if (mage.canCast(spell)) {
        actions.add(
          '[${i + 1}] Cast ${spell.displayName} (${spell.manaCost} mana)',
        );
      } else {
        actions.add('[${i + 1}] ${spell.displayName} (insufficient mana)');
      }
    }

    actions.add('[E] End Turn');

    return actions;
  }
}
