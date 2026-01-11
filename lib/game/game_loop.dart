import '../domain/spell.dart';
import '../domain/effect.dart';
import '../systems/node_resolver.dart';
import '../systems/shop_system.dart';
import '../systems/modifier_service.dart';
import '../systems/audio_system.dart';
import '../data/item_definitions.dart'; // For ConsumableEffectType
import 'game_state.dart';
import '../progression/spell_pool_manager.dart';

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

  /// Shows the node map.
  void showNodeMap() {
    state.showNodeMap();
  }

  /// Selects a node from the available choices.
  void selectNode(int choiceIndex) {
    state.selectNodeChoice(choiceIndex);
  }

  /// Enters the current node from the map.
  void enterNode() {
    if (state.currentScreen == GameScreen.nodeMap) {
      state.enterCurrentNode();
    }
  }

  /// Explicitly leave the current node (after interaction is done).
  void leaveCurrentNode() {
    state.finishNodeInteraction();
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

    final result = state.currentCombat!.castSpell(
      spellIndex,
      targetIndex: targetIndex,
    );

    final success = result?.success ?? false;

    // Sync logs
    // Check for combat end
    if (!state.currentCombat!.isOngoing) {
      _handleCombatEnd();
      return success;
    }

    // Auto-end turn if no more actions available
    if (!state.currentCombat!.canPlayerAct) {
      state.currentCombat!.autoEndTurn();
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

  // ==================== INVENTORY ACTIONS ====================

  /// Uses a consumable item from inventory.
  /// Returns a description of the effect.
  String useConsumable(String itemId) {
    if (state.currentScreen != GameScreen.combat)
      return 'Can only use items in combat';
    if (state.mage == null) return 'No active mage';

    final effect = state.inventory.useConsumable(itemId);
    if (effect == null) return 'Failed to use item';

    switch (effect.type) {
      case ConsumableEffectType.heal:
        // Phase 7.8: Apply healing multiplier
        final healingMultiplier = ModifierService.getHealingMultiplier(
          state.progression.getActiveModifiers(),
        );
        final healAmount = (effect.value * healingMultiplier).round();
        final actual = state.mage!.heal(healAmount);
        return 'Healed $actual HP';

      case ConsumableEffectType.restoreMana:
        state.mage!.restoreMana(effect.value);
        return 'Restored ${effect.value} Mana';

      case ConsumableEffectType.buffDamage:
        state.temporaryBuffs.add(
          TemporaryBuff(
            name: 'Item Buff',
            value: effect.value,
            remainingNodes: effect.durationNodes,
          ),
        );
        return 'Damage +${effect.value}% applied';

      case ConsumableEffectType.buffDefense:
        state.temporaryBuffs.add(
          TemporaryBuff(
            name: 'Item Defense',
            value: effect.value,
            remainingNodes: effect.durationNodes,
          ),
        );
        return 'Defense +${effect.value} for ${effect.durationNodes} rooms';
    }
  }

  /// Ends the player's turn in combat.
  Future<void> endTurn() async {
    if (state.currentScreen != GameScreen.combat) return;
    if (state.currentCombat == null) return;

    await state.currentCombat!.endPlayerTurn();
    if (!state.currentCombat!.isOngoing) {
      _handleCombatEnd();
    }
  }

  /// Public method to handle combat end - called from BattleScreen.
  void handleCombatEnd() {
    if (state.currentCombat == null) {
      state.completeNode();
      return;
    }

    // If combat system hasn't ended yet, check if we should end it
    if (state.currentCombat!.isOngoing) {
      final allEnemiesDead = state.currentCombat!.livingEnemies.isEmpty;
      final playerDead = !state.mage!.isAlive;

      if (allEnemiesDead || playerDead) {
        // Force the combat to end
        _handleCombatEndManual(playerWon: allEnemiesDead && !playerDead);
        return;
      }
    }

    _handleCombatEnd();
  }

  /// Handle combat end when BattleScreen determined the result.
  void _handleCombatEndManual({required bool playerWon}) {
    if (playerWon) {
      state.combatsWon++;

      // Award combat rewards
      final rewards = NodeResolver.calculateCombatReward(
        depth: state.currentDepth,
        enemiesDefeated: state.currentEnemies?.length ?? 1,
        isElite: state.isEliteCombat,
      );

      state.progression.addFragments(rewards['fragments']!);
      if (state.mage != null && rewards.containsKey('experience')) {
        final exp = rewards['experience']!;
        final logs = state.mage!.gainExp(exp);

        bool leveledUp = false;
        for (final log in logs) {
          if (log.contains('LEVEL UP')) {
            leveledUp = true;
          }
        }

        if (leveledUp) {
          AudioSystem.playLevelUp();
        }
      }

      if (state.isEliteCombat) {
        state.elitesDefeated++;
        state.showEliteRewards();
        return;
      }

      if (NodeResolver.shouldDropSpellCrystal(state.currentDepth)) {
        state.progression.addCrystals(1);
      }

      // Phase 7.9.3: Save at post-combat resolution
      state.triggerSavePoint();

      state.completeNode();
    } else {
      state.endRun(victory: false);
    }
  }

  void _handleCombatEnd() {
    final result = state.currentCombat!.getResult();
    if (result == null) {
      // Fall back to manual handling based on current state
      final allEnemiesDead = state.currentCombat!.livingEnemies.isEmpty;
      _handleCombatEndManual(playerWon: allEnemiesDead);
      return;
    }

    if (result.playerWon) {
      state.combatsWon++;

      // Award combat rewards (fragments & EXP)
      final rewards = NodeResolver.calculateCombatReward(
        depth: state.currentDepth,
        enemiesDefeated: state.currentEnemies?.length ?? 1,
        isElite: state.isEliteCombat,
      );

      state.progression.addFragments(rewards['fragments']!);

      // Award experience
      if (state.mage != null && rewards.containsKey('experience')) {
        final exp = rewards['experience']!;
        final logs = state.mage!.gainExp(exp);

        bool leveledUp = false;
        for (final log in logs) {
          if (log.contains('LEVEL UP')) {
            leveledUp = true;
          }
        }

        if (leveledUp) {
          AudioSystem.playLevelUp();
        }
      }

      // Check if this was an elite combat
      if (state.isEliteCombat) {
        state.elitesDefeated++;
        // Show elite rewards
        state.showEliteRewards();
        return;
      }

      // Check for bonus spell crystal drop (after depth 4)
      if (NodeResolver.shouldDropSpellCrystal(state.currentDepth)) {
        state.progression.addCrystals(1);
      }

      // Phase 7.9.3: Save at post-combat resolution
      state.triggerSavePoint();

      state.completeNode();
    } else {
      state.endRun(victory: false);
    }
  }

  // ==================== ELITE ACTIONS ====================

  /// Confirms entering the elite combat.
  void confirmEliteCombat() {
    if (state.currentScreen != GameScreen.elite) return;
    state.confirmEliteCombat();
  }

  /// Retreats from elite combat.
  void retreatFromElite() {
    if (state.currentScreen != GameScreen.elite) return;
    state.retreatFromElite();
  }

  /// Selects an elite reward.
  void selectEliteReward(int rewardIndex) {
    if (state.currentScreen != GameScreen.eliteReward) return;
    if (state.currentEliteRewards == null) return;

    final rewards = state.currentEliteRewards!['rewards'] as List;
    if (rewardIndex < 0 || rewardIndex >= rewards.length) return;

    final reward = rewards[rewardIndex] as Map<String, dynamic>;
    switch (reward['type']) {
      case 'crystal':
        final value = reward['value'] as int;
        state.progression.addCrystals(value);
        break;

      case 'spell':
        final spell = reward['spell'] as Spell;
        if (state.mage!.learnSpell(spell)) {
          SpellPoolManager.instance.markSpellDiscovered(spell.id);
          state.spellsLearned++;
        } else {
          state.progression.addFragments(50);
        }
        break;

      case 'fragments':
        final value = reward['value'] as int;
        state.progression.addFragments(value);
        break;

      case 'upgrade':
        if (state.mage!.spellLoadout.isNotEmpty) {
          // Show upgrade selection
          for (int i = 0; i < state.mage!.spellLoadout.length; i++) {
            final spell = state.mage!.spellLoadout[i];
            if (spell.starLevel < 3) {}
          }
          // For simplicity, auto-upgrade first upgradeable spell
          for (int i = 0; i < state.mage!.spellLoadout.length; i++) {
            if (state.mage!.spellLoadout[i].starLevel < 3) {
              state.mage!.upgradeSpell(i);
              state.spellsUpgraded++;
              break;
            }
          }
        } else {
          state.progression.addFragments(50);
        }
        break;
    }

    state.currentEliteRewards = null;
    state.isEliteCombat = false;

    // Phase 7.9.3: Save after elite reward selection
    state.triggerSavePoint();

    state.completeNode();
  }

  // ==================== SPELL LEARN ACTIONS ====================

  /// Learns a spell from the choices.
  void learnSpell(int choiceIndex) {
    if (state.currentScreen != GameScreen.spellLearn) return;
    // Don't allow multiple learnings
    if (state.nodeInteractionCompleted) return;
    if (state.spellChoices == null) return;
    if (choiceIndex < 0 || choiceIndex >= state.spellChoices!.length) return;

    final spell = state.spellChoices![choiceIndex];
    final mage = state.mage!;

    if (mage.isLoadoutFull) {
      // Need to replace
      for (int i = 0; i < mage.spellLoadout.length; i++) {}
      // Store the pending spell for replacement
      // (Would need additional state for this flow - simplified for prototype)
      return;
    }

    mage.learnSpell(spell);
    SpellPoolManager.instance.markSpellDiscovered(spell.id);
    state.spellsLearned++;
    // Mark as completed but don't leave yet
    state.nodeInteractionCompleted = true;
  }

  /// Replaces a spell when loadout is full.
  void replaceSpell(int loadoutIndex, Spell newSpell) {
    if (state.mage == null) return;
    // Don't allow multiple learnings
    if (state.nodeInteractionCompleted) return;
    if (loadoutIndex < 0 || loadoutIndex >= state.mage!.spellLoadout.length) {
      return;
    }

    final oldSpell = state.mage!.spellLoadout[loadoutIndex];
    state.mage!.replaceSpell(loadoutIndex, newSpell);
    state.spellsLearned++;
    // Mark as completed but don't leave yet
    state.nodeInteractionCompleted = true;
  }

  /// Skips spell learning.
  void skipSpellLearn() {
    if (state.currentScreen != GameScreen.spellLearn) return;
    state.finishNodeInteraction();
  }

  // ==================== ENHANCEMENT ACTIONS ====================

  /// Upgrades a spell at the enhancement shrine.
  /// Players can upgrade multiple spells as long as they have enough fragments.
  Future<bool> upgradeSpell(int loadoutIndex, [String? upgradePath]) async {
    if (state.currentScreen != GameScreen.enhancementShrine) return false;
    if (state.mage == null) return false;
    if (loadoutIndex < 0 || loadoutIndex >= state.mage!.spellLoadout.length) {
      return false;
    }

    final spell = state.mage!.spellLoadout[loadoutIndex];
    if (spell.starLevel >= 3) {
      return false;
    }

    final cost = NodeResolver.getUpgradeCost(spell);
    if (state.progression.spellFragments < cost) {
      return false;
    }

    await state.progression.spendFragments(cost);
    state.mage!.upgradeSpell(loadoutIndex, upgradePath);
    state.spellsUpgraded++;

    // Mark that at least one upgrade occurred (for tracking purposes)
    // but allow additional upgrades as long as fragments permit
    state.nodeInteractionCompleted = true;
    return true;
  }

  /// Skips enhancement.
  void skipEnhancement() {
    if (state.currentScreen != GameScreen.enhancementShrine) return;
    state.finishNodeInteraction();
  }

  // ==================== SHOP ACTIONS ====================

  /// Purchases an item from the shop.
  Future<bool> purchaseShopItem(int itemIndex) async {
    if (state.currentScreen != GameScreen.shop) return false;
    if (state.currentShop == null) return false;

    final availableItems = state.currentShop!.availableItems;
    if (itemIndex < 0 || itemIndex >= availableItems.length) return false;

    final item = availableItems[itemIndex];

    if (!state.currentShop!.canPurchase(
      item,
      state.progression.spellFragments,
    )) {
      return false;
    }

    // Make the purchase
    await state.progression.spendFragments(item.cost);
    state.currentShop!.purchaseItem(item);
    // Apply the item effect
    // Apply the item effect using ShopSystem logic
    ShopSystem.performPurchaseEffect(
      item: item,
      mage: state.mage!,
      progression: state.progression,
      onSpellLearned: () => state.spellsLearned++,
      onBuffAdded: (buff) => state.temporaryBuffs.add(buff),
    );

    // Show remaining items
    if (state.currentShop!.availableItems.isNotEmpty) {
    } else {}
    return true;
  }

  /// Leaves the shop.
  void leaveShop() {
    if (state.currentScreen != GameScreen.shop) return;
    state.finishNodeInteraction();
  }

  // ==================== REST ACTIONS ====================

  /// Rests and recovers HP.
  void rest() {
    if (state.currentScreen != GameScreen.rest) return;
    // Don't allow multiple rests
    if (state.nodeInteractionCompleted) return;
    if (state.mage == null) return;

    final baseHealAmount = NodeResolver.getRestHealAmount(state.mage!);
    // Phase 7.8: Apply healing multiplier from elemental modifiers
    final healingMultiplier = ModifierService.getHealingMultiplier(
      state.progression.getActiveModifiers(),
    );
    final healAmount = (baseHealAmount * healingMultiplier).round();
    final actualHeal = state.mage!.heal(healAmount);
    // Mark as completed but don't leave yet
    state.nodeInteractionCompleted = true;
  }

  /// Removes a modifier from a spell.
  void removeSpellModifier() {
    if (state.currentScreen != GameScreen.rest) return;
    // Don't allow multiple rests
    if (state.nodeInteractionCompleted) return;
    if (state.mage == null || state.mage!.spellLoadout.isEmpty) {
      return;
    }

    // For simplicity, just reset first spell with upgrades
    for (int i = 0; i < state.mage!.spellLoadout.length; i++) {
      if (state.mage!.spellLoadout[i].starLevel > 1) {
        final spell = state.mage!.spellLoadout[i];
        // Reset to base (this is simplified - full implementation would track modifiers)
        // Mark as completed but don't leave yet
        state.nodeInteractionCompleted = true;
        return;
      }
    }
  }

  /// Gains a temporary buff.
  void gainTempBuff() {
    if (state.currentScreen != GameScreen.rest) return;
    // Don't allow multiple rests
    if (state.nodeInteractionCompleted) return;
    if (state.mage == null) return;

    state.temporaryBuffs.add(
      TemporaryBuff(name: 'Rest Vigor', value: 25, remainingNodes: 3),
    );
    // Mark as completed but don't leave yet
    state.nodeInteractionCompleted = true;
  }

  /// Skips resting.
  void skipRest() {
    if (state.currentScreen != GameScreen.rest) return;
    state.finishNodeInteraction();
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
    switch (action) {
      case 'take':
      case 'heal':
        if (selectedChoice.containsKey('reward')) {
          final reward = selectedChoice['reward'] as int;
          state.progression.addFragments(reward);
        }
        if (selectedChoice.containsKey('healAmount')) {
          final baseHeal = selectedChoice['healAmount'] as int;
          // Phase 7.8: Apply healing multiplier from elemental modifiers
          final healingMultiplier = ModifierService.getHealingMultiplier(
            state.progression.getActiveModifiers(),
          );
          final heal = (baseHeal * healingMultiplier).round();
          final actual = state.mage!.heal(heal);
        }
        break;

      case 'accept':
        if (selectedChoice.containsKey('hpCost')) {
          final cost = selectedChoice['hpCost'] as int;
          state.mage!.takeDamage(cost);
        }
        if (selectedChoice.containsKey('reward')) {
          final reward = selectedChoice['reward'] as int;
          state.progression.addFragments(reward);
        }
        break;

      case 'buy_spell':
        final cost = selectedChoice['cost'] as int;
        if (state.progression.spellFragments >= cost) {
          state.progression.spendFragments(cost);
          // Give a random spell
          final spells = NodeResolver.generateSpellChoices(
            state.mage!,
            state.currentDepth,
          );
          if (spells.isNotEmpty && state.mage!.learnSpell(spells.first)) {
            SpellPoolManager.instance.markSpellDiscovered(spells.first.id);
            state.spellsLearned++;
          } else {}
        } else {}
        break;

      case 'decline':
      case 'leave':
        break;
    }

    state.currentRandomEvent = null;
    state.completeNode();
  }

  /// Completes the elite reward phase (New API).
  void completeEliteReward(Spell? selectedSpell) {
    if (state.currentRewardResult == null) return;

    final result = state.currentRewardResult!;

    // Apply currency
    if (result.fragments > 0) {
      state.progression.addFragments(result.fragments);
    }
    if (result.crystals > 0) {
      state.progression.addCrystals(result.crystals);
    }

    // Apply healing
    if (result.healPercent > 0) {
      final healAmount = (state.mage!.maxHP * result.healPercent).round();
      state.mage!.heal(healAmount);
    }

    // Apply spell selection
    if (selectedSpell != null) {
      state.mage!.learnSpell(selectedSpell);
      SpellPoolManager.instance.markSpellDiscovered(selectedSpell.id);
      state.spellsLearned++;
    }

    state.currentRewardResult = null;
    state.currentEliteRewards = null;
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
        final node = state.nodeMapSystem.currentNode;
        if (node != null) {
          return ['Current: ${node.displayText}', '', '[E] Enter node'];
        }
        return ['Run complete!'];

      case GameScreen.nodeChoice:
        final depth = state.nodeMapSystem.currentDepthLevel;
        if (depth != null && depth.hasChoice) {
          return [
            'Choose your path:',
            ...depth.nodeChoices.asMap().entries.map(
              (e) => '[${e.key + 1}] ${e.value.shortDisplay}',
            ),
          ];
        }
        return [];

      case GameScreen.exploration:
        return [
          'WASD to move',
          'Approach enemy to preview',
          'Approach door to proceed',
        ];

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

      case GameScreen.shop:
        final items = state.currentShop?.availableItems ?? [];
        return [
          ...items.asMap().entries.map(
            (e) =>
                '[${e.key + 1}] ${e.value.displayText} (${e.value.cost} frags)',
          ),
          '[L] Leave shop',
        ];

      case GameScreen.rest:
        return ['[R] Rest', '[M] Remove Modifier', '[B] Temp Buff', '[S] Skip'];

      case GameScreen.elite:
        return ['[Y] Yes, fight!', '[N] No, retreat'];

      case GameScreen.eliteReward:
        final rewards = state.currentEliteRewards?['rewards'] as List? ?? [];
        return [
          ...rewards.asMap().entries.map(
            (e) => '[${e.key + 1}] ${(e.value as Map)['name']}',
          ),
        ];

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

      case GameScreen.elementSelect:
        return ['Choose your starting element'];

      case GameScreen.runEnd:
        return ['[M] Main Menu'];
    }
  }
}
