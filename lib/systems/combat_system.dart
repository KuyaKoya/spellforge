import '../domain/effect.dart';
import '../domain/enemy.dart';
import '../domain/mage.dart';
import 'spell_system.dart';

/// Represents the state of an ongoing combat.
enum CombatPhase { playerTurn, enemyTurn, statusResolution, victory, defeat }

/// Type of enemy action for UI display.
enum EnemyActionType { attack, defend, debuff, skipped }

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

/// Result of a single enemy action (for UI sync).
class EnemyActionResult {
  final Enemy enemy;
  final EnemyActionType actionType;
  final int damage;
  final int armorGained;
  final bool wasDelayed;

  EnemyActionResult({
    required this.enemy,
    required this.actionType,
    this.damage = 0,
    this.armorGained = 0,
    this.wasDelayed = false,
  });
}

/// Manages turn-based combat between mage and enemies.
class CombatSystem {
  final Mage mage;
  final List<Enemy> enemies;
  final List<String> combatLog;

  CombatPhase phase;
  int currentTurn;
  bool _playerTurnHeaderLogged = false;

  CombatSystem({required this.mage, required this.enemies})
    : combatLog = [],
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

  /// Gets a descriptive intent string for an enemy (A2.3: vague, not exact).
  String _getIntentDescription(Enemy enemy) {
    return '${enemy.intent.icon} ${enemy.intent.vagueDescription}';
  }

  /// Casts a spell at a target. Returns the detailed result.
  SpellCastResult? castSpell(int spellIndex, {int? targetIndex}) {
    if (!isPlayerTurn) return null;
    if (spellIndex < 0 || spellIndex >= mage.spellLoadout.length) return null;

    final spell = mage.spellLoadout[spellIndex];

    final result = SpellSystem.castSpell(
      caster: mage,
      spell: spell,
      enemies: enemies,
      targetIndex: targetIndex ?? 0,
    );

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

  /// Ends the player's turn (transitions phase, does NOT auto-execute enemy actions).
  /// Use beginEnemyPhase() and executeEnemyActionAtIndex() for UI-driven execution.
  void endPlayerTurn() {
    if (!isPlayerTurn) return;

    combatLog.add('${mage.name} ends their turn.');
    combatLog.add('');

    _playerTurnHeaderLogged = false;
    phase = CombatPhase.enemyTurn;

    // Log enemy turn header
    combatLog.add('┌──────────────────────────────────────┐');
    combatLog.add('│  TURN $currentTurn - ENEMY TURN');
    combatLog.add('└──────────────────────────────────────┘');
    combatLog.add('');
  }

  /// Automatically ends the turn (when no actions/mana left).
  void autoEndTurn() {
    combatLog.add('⚠️  No more actions available.');
    endPlayerTurn();
  }

  /// Executes a single enemy's action at the given index.
  /// Returns the result for UI display, or null if invalid.
  /// This is called by the UI to sync damage display with HP bar updates.
  EnemyActionResult? executeEnemyActionAtIndex(int index) {
    final living = livingEnemies;
    if (index < 0 || index >= living.length) return null;

    final enemy = living[index];

    if (enemy.isDelayed) {
      combatLog.add('⏸️  ${enemy.name} is delayed and skips their turn.');
      combatLog.add('');
      return EnemyActionResult(
        enemy: enemy,
        actionType: EnemyActionType.skipped,
        damage: 0,
        wasDelayed: true,
      );
    }

    combatLog.add('► ${enemy.name}\'s action:');
    final result = _executeEnemyActionWithResult(enemy);
    combatLog.add('');

    return result;
  }

  /// Finishes the enemy phase after all enemy actions have been executed.
  /// Resolves status effects and prepares for new player turn.
  void finishEnemyPhase() {
    if (!mage.isAlive) {
      _endCombat(playerWon: false);
      return;
    }

    _resolveStatusEffects();
  }

  /// Executes a single enemy's action based on intent (returns result for UI).
  EnemyActionResult _executeEnemyActionWithResult(Enemy enemy) {
    EnemyActionResult result;

    switch (enemy.intent) {
      case EnemyIntent.attack:
        final damage = enemy.getEffectiveDamage();
        final actualDamage = mage.takeDamage(damage);
        combatLog.add('  ⚔️  Attacks ${mage.name} for $actualDamage damage!');
        combatLog.add('  → ${mage.name} HP: ${mage.currentHP}/${mage.maxHP}');
        result = EnemyActionResult(
          enemy: enemy,
          actionType: EnemyActionType.attack,
          damage: actualDamage,
        );
        break;

      case EnemyIntent.defend:
        enemy.applyStatusEffect(
          Effect(type: EffectType.armor, value: enemy.armorGain, duration: 2),
        );
        combatLog.add('  🛡️  Defends, gaining ${enemy.armorGain} armor.');
        result = EnemyActionResult(
          enemy: enemy,
          actionType: EnemyActionType.defend,
          damage: 0,
          armorGained: enemy.armorGain,
        );
        break;

      case EnemyIntent.debuff:
        mage.applyStatusEffect(
          Effect(type: EffectType.weaken, value: 15, duration: 2),
        );
        combatLog.add('  💀 Weakens ${mage.name}! (-15% damage for 2 turns)');
        result = EnemyActionResult(
          enemy: enemy,
          actionType: EnemyActionType.debuff,
          damage: 0,
        );
        break;
    }

    // Choose next intent
    enemy.chooseNextIntent();
    return result;
  }

  /// Resolves status effects at turn boundary (end of enemy turn).
  /// Phase 7.2: Burn now triggers at the START of each character's turn.
  /// This method only handles end-of-turn cleanup for enemies.
  void _resolveStatusEffects() {
    // Process enemy status effect duration/expiration only
    // Burn damage for enemies was already processed before their action
    for (final enemy in enemies.where((e) => e.isAlive)) {
      // Tick duration for old status effects (non-burn)
      for (final effect in List.from(enemy.statusEffects)) {
        if (effect.type != EffectType.burn) {
          if (!effect.tick()) {
            enemy.statusEffects.remove(effect);
            combatLog.add(
              '${effect.type.displayName} wore off from ${enemy.name}',
            );
          }
        }
      }

      // Reset delay flag
      if (enemy.isDelayed) {
        enemy.isDelayed = false;
      }
    }

    // Check for victory
    if (livingEnemies.isEmpty) {
      _endCombat(playerWon: true);
      return;
    }

    // Start new turn
    _startNewTurn();
  }

  /// Processes a single enemy's status effects at the start of their action.
  /// C1 Spec: Burn triggers at start of affected character's turn.
  List<String> processEnemyTurnStartEffects(Enemy enemy) {
    final logs = <String>[];

    if (enemy.statusEffects.isEmpty && !enemy.statusManager.hasActiveEffects) {
      return logs;
    }

    // Process new status effects (Phase 7.2)
    final turnStartResults = enemy.statusManager.processTurnStart();
    for (final result in turnStartResults) {
      if (result.damage > 0) {
        final actualDamage = enemy.takeBurnDamage(result.damage);
        logs.add('🔥 ${enemy.name} takes $actualDamage burn damage!');
      }
      if (result.healing > 0) {
        enemy.currentHP = (enemy.currentHP + result.healing).clamp(
          0,
          enemy.maxHP,
        );
        logs.add('💚 ${enemy.name} regenerates ${result.healing} HP!');
      }
    }

    // Process turn end (tick duration, expire) for new system
    final expiredMessages = enemy.statusManager.processTurnEnd();
    logs.addAll(expiredMessages);

    // Legacy: Process old burn status effects
    for (final effect in List.from(enemy.statusEffects)) {
      if (effect.type == EffectType.burn) {
        final damage = enemy.takeBurnDamage(effect.value);
        logs.add('🔥 ${enemy.name} takes $damage burn damage!');

        if (!effect.tick()) {
          enemy.statusEffects.remove(effect);
          logs.add('${effect.type.displayName} wore off from ${enemy.name}');
        }
      }
    }

    return logs;
  }

  /// Starts a new player turn.
  void _startNewTurn() {
    currentTurn++;
    phase = CombatPhase.playerTurn;
    _playerTurnHeaderLogged = false;
    mage.resetActions();

    // Restore some mana each turn
    final manaRestored = mage.restoreMana(2);

    _logPlayerTurnHeader();

    if (manaRestored > 0) {
      combatLog.add('💧 ${mage.name} recovers $manaRestored mana.');
      combatLog.add('');
    }

    // Phase 7.2: Process PLAYER status effects at turn START
    _processPlayerTurnStartEffects();

    _logStatus();
  }

  /// Processes player status effects at the start of their turn.
  /// C1 Spec: Burn triggers at start of affected character's turn.
  void _processPlayerTurnStartEffects() {
    if (mage.statusEffects.isEmpty && !mage.statusManager.hasActiveEffects) {
      return;
    }

    combatLog.add('── ${mage.name}\'s Status Effects ──');

    // Process new status effects (Phase 7.2)
    final turnStartResults = mage.statusManager.processTurnStart();
    for (final result in turnStartResults) {
      if (result.damage > 0) {
        final actualDamage = mage.takeBurnDamage(result.damage);
        combatLog.add('  🔥 ${mage.name} takes $actualDamage burn damage!');
      }
      if (result.healing > 0) {
        final actualHeal = mage.heal(result.healing);
        combatLog.add('  💚 ${mage.name} regenerates $actualHeal HP!');
      }
    }

    // Process turn end (tick duration, expire)
    final expiredMessages = mage.statusManager.processTurnEnd();
    for (final msg in expiredMessages) {
      combatLog.add('  $msg');
    }

    // Legacy: Process old status effects
    for (final effect in List.from(mage.statusEffects)) {
      switch (effect.type) {
        case EffectType.burn:
          final damage = mage.takeBurnDamage(effect.value);
          combatLog.add('  🔥 ${mage.name} takes $damage burn damage!');
          break;
        default:
          break;
      }

      if (!effect.tick()) {
        mage.statusEffects.remove(effect);
        combatLog.add(
          '  ${effect.type.displayName} wore off from ${mage.name}',
        );
      }
    }

    combatLog.add('');
  }

  /// Ends combat with the given result.
  void _endCombat({required bool playerWon}) {
    phase = playerWon ? CombatPhase.victory : CombatPhase.defeat;

    combatLog.add('');
    combatLog.add('╔══════════════════════════════════════╗');
    if (playerWon) {
      combatLog.add('║         🎉 VICTORY! 🎉               ║');
      combatLog.add('╚══════════════════════════════════════╝');
      combatLog.add('');
      combatLog.add('${mage.name} is triumphant!');
    } else {
      combatLog.add('║         💀 DEFEAT 💀                 ║');
      combatLog.add('╚══════════════════════════════════════╝');
      combatLog.add('');
      combatLog.add('${mage.name} has fallen...');
    }
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
