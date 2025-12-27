import '../domain/spell.dart';
import '../domain/effect.dart';
import '../systems/node_system.dart';
import 'game_state.dart';

/// Handles game logic for player actions.
class GameLoop {
  final GameState state;

  GameLoop(this.state);

  /// Selects a mage and starts a new run.
  void selectMage(int index) {
    final mages = state.getAvailableMages();
    if (index >= 0 && index < mages.length) {
      state.currentScreen = GameScreen.mageSelect;
      state.startRun(mages[index]);
    }
  }

  /// Enters the current node from the map.
  void enterNode() {
    if (state.currentScreen == GameScreen.nodeMap) {
      state.enterCurrentNode();
    }
  }

  // ==================== COMBAT ACTIONS ====================

  /// Initiates spell casting - checks if target selection is needed.
  void initiateSpellCast(int spellIndex) {
    if (state.currentScreen != GameScreen.combat) return;
    if (state.currentCombat == null || state.mage == null) return;
    if (spellIndex < 0 || spellIndex >= state.mage!.spellLoadout.length) return;

    final spell = state.mage!.spellLoadout[spellIndex];
    if (!state.mage!.canCast(spell)) return;

    final livingEnemies = state.currentCombat!.livingEnemies;

    // Check if spell targets all enemies
    final targetsAll = spell.effects.any((e) => e.targetRule == TargetRule.all);

    // If only one enemy or spell targets all, cast immediately
    if (livingEnemies.length <= 1 || targetsAll) {
      castSpell(spellIndex, targetIndex: 0);
    } else {
      // Multiple enemies and single-target spell: enter target selection
      state.enterTargetSelection(spellIndex);
    }
  }

  /// Casts a spell in combat at a specific target.
  bool castSpell(int spellIndex, {int targetIndex = 0}) {
    if (state.currentScreen != GameScreen.combat &&
        state.currentScreen != GameScreen.targetSelect) {
      return false;
    }
    if (state.currentCombat == null) return false;

    // Clear target selection state
    state.pendingSpellIndex = null;
    state.currentScreen = GameScreen.combat;

    final success = state.currentCombat!.castSpell(
      spellIndex,
      targetIndex: targetIndex,
    );

    // Sync logs
    _syncCombatLog();

    // Check for combat end
    if (!state.currentCombat!.isOngoing) {
      _handleCombatEnd();
      return success;
    }

    // Auto-end turn if no more actions available
    if (!state.currentCombat!.canPlayerAct) {
      state.currentCombat!.autoEndTurn();
      _syncCombatLog();

      if (!state.currentCombat!.isOngoing) {
        _handleCombatEnd();
      }
    }

    return success;
  }

  /// Casts the pending spell at the selected target.
  void confirmTarget(int targetIndex) {
    if (state.currentScreen != GameScreen.targetSelect) return;
    if (state.pendingSpellIndex == null) return;

    castSpell(state.pendingSpellIndex!, targetIndex: targetIndex);
  }

  /// Cancels target selection.
  void cancelTargetSelection() {
    state.cancelTargetSelection();
  }

  /// Ends the player's turn in combat.
  void endTurn() {
    if (state.currentScreen != GameScreen.combat) return;
    if (state.currentCombat == null) return;

    state.currentCombat!.endPlayerTurn();
    _syncCombatLog();

    if (!state.currentCombat!.isOngoing) {
      _handleCombatEnd();
    }
  }

  void _syncCombatLog() {
    state.syncCombatLog();
  }

  void _handleCombatEnd() {
    final result = state.currentCombat!.getResult();
    if (result == null) return;

    if (result.playerWon) {
      state.combatsWon++;

      // Award combat rewards (fragments)
      final fragmentReward = state.progression.calculateCombatReward(
        state.nodeSystem.currentNodeIndex,
        state.currentEnemies?.length ?? 1,
      );
      state.progression.addFragments(fragmentReward);
      state.log('');
      state.log('Earned $fragmentReward spell fragments!');

      // Award experience
      final expReward = _calculateExpReward(
        state.nodeSystem.currentNodeIndex,
        state.currentEnemies?.length ?? 1,
      );
      if (state.mage != null) {
        final levelLogs = state.mage!.gainExp(expReward);
        for (final log in levelLogs) {
          state.log(log);
        }
      }

      state.completeNode();
    } else {
      state.endRun(victory: false);
    }
  }

  /// Calculates experience reward based on node and enemies.
  int _calculateExpReward(int nodeIndex, int enemiesDefeated) {
    // Base EXP: 5 per enemy + 2 per node depth
    final baseExp = enemiesDefeated * 5;
    final nodeBonus = nodeIndex * 2;
    return baseExp + nodeBonus;
  }

  // ==================== SPELL LEARN ACTIONS ====================

  /// Learns a spell from the choices.
  void learnSpell(int choiceIndex) {
    if (state.currentScreen != GameScreen.spellLearn) return;
    if (state.spellChoices == null) return;
    if (choiceIndex < 0 || choiceIndex >= state.spellChoices!.length) return;

    final spell = state.spellChoices![choiceIndex];
    final mage = state.mage!;

    if (mage.isLoadoutFull) {
      // Need to replace
      state.log('');
      state.log('Loadout is full! Choose a spell to replace:');
      for (int i = 0; i < mage.spellLoadout.length; i++) {
        state.log('[${i + 1}] ${mage.spellLoadout[i].displayName}');
      }
      state.log('[C] Cancel');

      // Store the pending spell for replacement
      // (Would need additional state for this flow - simplified for prototype)
      return;
    }

    mage.learnSpell(spell);
    state.spellsLearned++;
    state.log('');
    state.log('Learned ${spell.displayName}!');
    state.completeNode();
  }

  /// Replaces a spell when loadout is full.
  void replaceSpell(int loadoutIndex, Spell newSpell) {
    if (state.mage == null) return;
    if (loadoutIndex < 0 || loadoutIndex >= state.mage!.spellLoadout.length) {
      return;
    }

    final oldSpell = state.mage!.spellLoadout[loadoutIndex];
    state.mage!.replaceSpell(loadoutIndex, newSpell);
    state.spellsLearned++;

    state.log('');
    state.log('Replaced ${oldSpell.displayName} with ${newSpell.displayName}!');
    state.completeNode();
  }

  /// Skips spell learning.
  void skipSpellLearn() {
    if (state.currentScreen != GameScreen.spellLearn) return;

    state.log('');
    state.log('Chose not to learn any spells.');
    state.completeNode();
  }

  // ==================== ENHANCEMENT ACTIONS ====================

  /// Upgrades a spell at the enhancement shrine.
  Future<bool> upgradeSpell(int loadoutIndex) async {
    if (state.currentScreen != GameScreen.enhancementShrine) return false;
    if (state.mage == null) return false;
    if (loadoutIndex < 0 || loadoutIndex >= state.mage!.spellLoadout.length) {
      return false;
    }

    final spell = state.mage!.spellLoadout[loadoutIndex];
    if (spell.starLevel >= 3) {
      state.log('That spell is already at maximum level!');
      return false;
    }

    final cost = NodeResolver.getUpgradeCost(spell);
    if (state.progression.spellFragments < cost) {
      state.log(
        'Not enough fragments! Need $cost, have ${state.progression.spellFragments}.',
      );
      return false;
    }

    await state.progression.spendFragments(cost);
    state.mage!.upgradeSpell(loadoutIndex);
    state.spellsUpgraded++;

    final upgraded = state.mage!.spellLoadout[loadoutIndex];
    state.log('');
    state.log('Upgraded ${spell.displayName} → ${upgraded.displayName}!');
    state.log('Spent $cost fragments.');
    state.completeNode();
    return true;
  }

  /// Skips enhancement.
  void skipEnhancement() {
    if (state.currentScreen != GameScreen.enhancementShrine) return;

    state.log('');
    state.log('Left the shrine without upgrading.');
    state.completeNode();
  }

  // ==================== REST ACTIONS ====================

  /// Rests and recovers HP.
  void rest() {
    if (state.currentScreen != GameScreen.rest) return;
    if (state.mage == null) return;

    final healAmount = NodeResolver.getRestHealAmount(state.mage!);
    final actualHeal = state.mage!.heal(healAmount);

    state.log('');
    state.log('Rested and recovered $actualHeal HP.');
    state.log(state.mage!.hpDisplay);
    state.completeNode();
  }

  /// Skips resting.
  void skipRest() {
    if (state.currentScreen != GameScreen.rest) return;

    state.log('');
    state.log('Pressed on without resting.');
    state.completeNode();
  }

  // ==================== RANDOM EVENT ACTIONS ====================

  /// Handles a random event choice.
  void handleRandomEventChoice(String choice) {
    if (state.currentScreen != GameScreen.randomEvent) return;
    if (state.currentRandomEvent == null) return;

    final event = state.currentRandomEvent!;
    final choices = event['choices'] as List;

    // Find matching choice
    Map<String, dynamic>? selectedChoice;
    for (final c in choices) {
      if (c['key'].toString().toUpperCase() == choice.toUpperCase()) {
        selectedChoice = c as Map<String, dynamic>;
        break;
      }
    }

    if (selectedChoice == null) return;

    final action = selectedChoice['action'] as String;
    state.log('');

    switch (action) {
      case 'take':
      case 'heal':
        if (selectedChoice.containsKey('reward')) {
          final reward = selectedChoice['reward'] as int;
          state.progression.addFragments(reward);
          state.log('💎 Gained $reward spell fragments!');
        }
        if (selectedChoice.containsKey('healAmount')) {
          final heal = selectedChoice['healAmount'] as int;
          final actual = state.mage!.heal(heal);
          state.log('❤️  Recovered $actual HP!');
        }
        break;

      case 'accept':
        if (selectedChoice.containsKey('hpCost')) {
          final cost = selectedChoice['hpCost'] as int;
          state.mage!.takeDamage(cost);
          state.log('💔 Lost $cost HP.');
        }
        if (selectedChoice.containsKey('reward')) {
          final reward = selectedChoice['reward'] as int;
          state.progression.addFragments(reward);
          state.log('💎 Gained $reward spell fragments!');
        }
        break;

      case 'buy_spell':
        final cost = selectedChoice['cost'] as int;
        if (state.progression.spellFragments >= cost) {
          state.progression.spendFragments(cost);
          // Give a random spell
          final spells = NodeResolver.generateSpellChoices(
            state.mage!,
            state.nodeSystem.currentNodeIndex,
          );
          if (spells.isNotEmpty && state.mage!.learnSpell(spells.first)) {
            state.log('📖 Learned ${spells.first.displayName}!');
          } else {
            state.log('❌ Loadout full! Lost fragments.');
          }
        } else {
          state.log('❌ Not enough fragments!');
        }
        break;

      case 'decline':
      case 'leave':
        state.log('You continue on your way.');
        break;
    }

    state.currentRandomEvent = null;
    state.completeNode();
  }

  // ==================== MENU ACTIONS ====================

  /// Returns to main menu.
  void returnToMenu() {
    state.returnToMainMenu();
  }

  /// Gets the current screen's available actions as text.
  List<String> getCurrentActions() {
    switch (state.currentScreen) {
      case GameScreen.mainMenu:
        return ['[N] New Run', '[Q] Quit'];

      case GameScreen.mageSelect:
        final mages = state.getAvailableMages();
        return [
          'Choose your mage:',
          ...mages.asMap().entries.map(
            (e) =>
                '[${e.key + 1}] ${e.value.name} (${e.value.primaryElement.displayName})',
          ),
        ];

      case GameScreen.nodeMap:
        final node = state.nodeSystem.currentNode;
        if (node != null) {
          return ['Current: ${node.displayText}', '', '[E] Enter node'];
        }
        return ['Run complete!'];

      case GameScreen.combat:
        if (state.currentCombat != null) {
          return state.currentCombat!.getAvailableActions();
        }
        return [];

      case GameScreen.targetSelect:
        final enemies = state.currentCombat?.livingEnemies ?? [];
        return [
          ...enemies.asMap().entries.map(
            (e) => '[${e.key + 1}] ${e.value.name} (${e.value.hpDisplay})',
          ),
          '[C] Cancel',
        ];

      case GameScreen.spellLearn:
        final choices = state.spellChoices ?? [];
        return [
          ...choices.asMap().entries.map(
            (e) => '[${e.key + 1}] Learn ${e.value.displayName}',
          ),
          '[S] Skip',
        ];

      case GameScreen.enhancementShrine:
        final loadout = state.mage?.spellLoadout ?? [];
        return [
          ...loadout.asMap().entries.map((e) {
            if (e.value.starLevel < 3) {
              final cost = NodeResolver.getUpgradeCost(e.value);
              return '[${e.key + 1}] Upgrade ${e.value.displayName} ($cost fragments)';
            }
            return '[${e.key + 1}] ${e.value.displayName} (MAX)';
          }),
          '[S] Skip',
        ];

      case GameScreen.rest:
        return ['[R] Rest', '[S] Skip'];

      case GameScreen.randomEvent:
        final event = state.currentRandomEvent;
        if (event != null) {
          final choices = event['choices'] as List;
          return choices
              .map((c) => '[${c['key']}] ${c['text']}')
              .toList()
              .cast<String>();
        }
        return ['[1] Continue'];

      case GameScreen.runEnd:
        return ['[M] Main Menu'];
    }
  }
}
