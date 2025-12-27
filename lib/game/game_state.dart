import '../data/mage_definitions.dart';
import '../data/spell_definitions.dart';
import '../domain/enemy.dart';
import '../domain/mage.dart';
import '../domain/spell.dart';
import '../domain/effect.dart';
import '../systems/combat_system.dart';
import '../nodes/nodes.dart';
import '../systems/node_resolver.dart';
import '../systems/progression_system.dart';
import '../systems/shop_system.dart';

/// The current screen/mode of the game.
enum GameScreen {
  mainMenu,
  mageSelect,
  nodeMap,
  nodeChoice,
  combat,
  targetSelect,
  spellLearn,
  enhancementShrine,
  shop,
  rest,
  elite,
  eliteReward,
  randomEvent,
  runEnd,
}

/// Represents the complete state of a game run.
class GameState {
  // Systems
  final ProgressionSystem progression;
  final NodeMapSystem nodeMapSystem;

  // Current screen
  GameScreen currentScreen;

  // Player state
  Mage? mage;
  CombatSystem? currentCombat;
  List<TemporaryBuff> temporaryBuffs = [];

  // Node-specific state
  List<Spell>? spellChoices;
  List<Enemy>? currentEnemies;
  ShopSystem? currentShop;
  bool isEliteCombat = false;

  // Target selection state
  int? pendingSpellIndex;

  // Random event state
  Map<String, dynamic>? currentRandomEvent;

  // Elite reward state
  Map<String, dynamic>? currentEliteRewards;
  int? selectedRewardIndex;

  // Combat log sync tracking
  int _combatLogSyncIndex = 0;

  // Text log for display
  final List<String> textLog;

  // Run statistics
  int combatsWon = 0;
  int elitesDefeated = 0;
  int spellsLearned = 0;
  int spellsUpgraded = 0;

  GameState({required this.progression, NodeMapSystem? nodeMapSystem})
    : nodeMapSystem = nodeMapSystem ?? NodeMapSystem(),
      currentScreen = GameScreen.mainMenu,
      textLog = [];

  /// Whether the player is alive.
  bool get isPlayerAlive => mage?.isAlive ?? false;

  /// Whether a run is in progress.
  bool get isRunInProgress =>
      mage != null && currentScreen != GameScreen.mainMenu;

  /// Current depth in the run (1-indexed).
  int get currentDepth => nodeMapSystem.currentDepth;

  /// Adds a message to the log.
  void log(String message) {
    textLog.add(message);
  }

  /// Clears the log.
  void clearLog() {
    textLog.clear();
  }

  /// Gets the last N log entries.
  List<String> getRecentLog({int count = 20}) {
    final start = (textLog.length - count).clamp(0, textLog.length);
    return textLog.sublist(start);
  }

  /// Applies temporary buffs damage multiplier.
  double get temporaryBuffMultiplier {
    double multiplier = 1.0;
    for (final buff in temporaryBuffs.where((b) => b.isActive)) {
      multiplier += buff.value / 100.0;
    }
    return multiplier;
  }

  /// Ticks temporary buffs (called after each node).
  void tickTemporaryBuffs() {
    for (final buff in temporaryBuffs) {
      buff.tick();
    }
    temporaryBuffs.removeWhere((b) => !b.isActive);
  }

  /// Starts a new run with the given mage.
  void startRun(Mage selectedMage) {
    mage = selectedMage.freshCopy();
    currentScreen = GameScreen.nodeMap;
    combatsWon = 0;
    elitesDefeated = 0;
    spellsLearned = 0;
    spellsUpgraded = 0;
    temporaryBuffs.clear();

    // Generate the run with the new node map system
    nodeMapSystem.generateRun(maxDepth: 10);
    progression.startNewRun();

    // Give starting spell based on element
    final startingSpells = SpellDefinitions.getByElement(
      mage!.primaryElement,
    ).where((s) => s.rarity == SpellRarity.common).toList();
    if (startingSpells.isNotEmpty) {
      mage!.learnSpell(startingSpells.first);
    }

    clearLog();
    log('╔══════════════════════════════════════╗');
    log('║         ⚡ NEW RUN STARTED ⚡         ║');
    log('╚══════════════════════════════════════╝');
    log('');
    log('${mage!.name} embarks on their journey.');
    log('Passive: ${mage!.passiveDescription}');
    log('');
    log(mage!.hpDisplay);
    log(mage!.manaDisplay);
    log('');
    log(
      'Starting spell: ${mage!.spellLoadout.isNotEmpty ? mage!.spellLoadout.first.displayName : 'None'}',
    );
    log('');

    // Show the node map and initialize the first node selection
    showNodeMap();
  }

  /// Shows the node map with available choices.
  void showNodeMap() {
    currentScreen = GameScreen.nodeMap;

    final depthLevel = nodeMapSystem.currentDepthLevel;
    if (depthLevel == null) {
      endRun(victory: true);
      return;
    }

    log('');
    log('┌──────────────────────────────────────┐');
    log(
      '│  🗺️  NODE MAP - Depth ${depthLevel.depth}/${nodeMapSystem.totalDepths}',
    );
    log('└──────────────────────────────────────┘');
    log('');

    if (depthLevel.hasChoice) {
      currentScreen = GameScreen.nodeChoice;
      log('Choose your path:');
      log('');

      for (int i = 0; i < depthLevel.nodeChoices.length; i++) {
        final node = depthLevel.nodeChoices[i];
        log('[${i + 1}] ${node.displayText}');
        log('    ${node.type.description}');

        // Show risk/reward info for elite nodes
        if (node.type == NodeType.elite) {
          log('    ⚠️  WARNING: Failure = Run ends!');
          log('    🏆 REWARD: Guaranteed rare reward');
        }
        log('');
      }
    } else {
      // Single path - show node info
      final node = depthLevel.nodeChoices.first;
      log('Next: ${node.displayText}');
      log(node.type.description);
      log('');
      log('[E] Enter node');

      // Auto-select the only option
      nodeMapSystem.selectNode(0);
    }
  }

  /// Selects a node from the available choices.
  void selectNodeChoice(int choiceIndex) {
    final depthLevel = nodeMapSystem.currentDepthLevel;
    if (depthLevel == null) return;

    if (choiceIndex < 0 || choiceIndex >= depthLevel.nodeChoices.length) return;

    nodeMapSystem.selectNode(choiceIndex);
    enterCurrentNode();
  }

  /// Enters the current node.
  void enterCurrentNode() {
    final node = nodeMapSystem.currentNode;
    if (node == null) {
      // Run complete
      endRun(victory: true);
      return;
    }

    log('');
    log('=== ${node.displayText} ===');
    log(node.type.description);
    log('');

    switch (node.type) {
      case NodeType.combat:
        _setupCombat(currentDepth);
        break;
      case NodeType.spellLearn:
        _setupSpellLearn(currentDepth);
        break;
      case NodeType.enhancementShrine:
        _setupEnhancementShrine();
        break;
      case NodeType.shop:
        _setupShop();
        break;
      case NodeType.rest:
        _setupRest();
        break;
      case NodeType.elite:
        _setupEliteCombat(currentDepth);
        break;
      case NodeType.randomEvent:
        _setupRandomEvent(currentDepth);
        break;
      case NodeType.bossCombat:
        _setupBossCombat(currentDepth);
        break;
    }
  }

  void _setupCombat(int depth) {
    currentEnemies = NodeResolver.generateCombatEncounter(depth).cast<Enemy>();
    isEliteCombat = false;

    currentCombat = CombatSystem(mage: mage!, enemies: currentEnemies!);
    currentCombat!.startCombat();
    currentScreen = GameScreen.combat;

    // Transfer combat log and set sync index
    textLog.addAll(currentCombat!.combatLog);
    _combatLogSyncIndex = currentCombat!.combatLog.length;
  }

  void _setupEliteCombat(int depth) {
    log('┌──────────────────────────────────────┐');
    log('│  💀 ELITE ENCOUNTER                  │');
    log('└──────────────────────────────────────┘');
    log('');

    final elites = NodeResolver.generateEliteEncounter(depth);
    currentEnemies = elites.cast<Enemy>();
    isEliteCombat = true;

    // Show elite info
    for (final elite in elites) {
      log('${elite.element.displayName} ${elite.name}');
      log('  ❤️  HP: ${elite.maxHP}');
      for (final modifier in elite.modifierDescriptions) {
        log('  $modifier');
      }
      log('');
    }

    log('⚠️  WARNING: Defeat means the run ends!');
    log('🏆 REWARD: Guaranteed rare reward on victory');
    log('');
    log('Proceed? [Y] Yes / [N] No (retreat)');

    currentScreen = GameScreen.elite;
  }

  /// Starts the elite combat after confirmation.
  void confirmEliteCombat() {
    currentCombat = CombatSystem(mage: mage!, enemies: currentEnemies!);
    currentCombat!.startCombat();
    currentScreen = GameScreen.combat;

    textLog.addAll(currentCombat!.combatLog);
    _combatLogSyncIndex = currentCombat!.combatLog.length;
  }

  /// Retreats from elite (skips node without reward).
  void retreatFromElite() {
    log('');
    log('You wisely retreat from the elite encounter.');
    log('No rewards gained, but you live to fight another day.');
    isEliteCombat = false;
    completeNode();
  }

  void _setupBossCombat(int depth) {
    log('┌──────────────────────────────────────┐');
    log('│  👹 BOSS BATTLE                      │');
    log('└──────────────────────────────────────┘');
    log('');

    currentEnemies = NodeResolver.generateBossEncounter(depth).cast<Enemy>();
    isEliteCombat = false;

    currentCombat = CombatSystem(mage: mage!, enemies: currentEnemies!);
    currentCombat!.startCombat();
    currentScreen = GameScreen.combat;

    textLog.addAll(currentCombat!.combatLog);
    _combatLogSyncIndex = currentCombat!.combatLog.length;
  }

  void _setupSpellLearn(int depth) {
    spellChoices = NodeResolver.generateSpellChoices(mage!, depth);
    currentScreen = GameScreen.spellLearn;

    log('┌──────────────────────────────────────┐');
    log('│  📖 SPELL SHRINE                     │');
    log('└──────────────────────────────────────┘');
    log('');
    log('Choose a spell to learn:');
    log('');

    for (int i = 0; i < spellChoices!.length; i++) {
      final spell = spellChoices![i];
      log(
        '[${i + 1}] ${spell.elementIcon} ${spell.displayName} ${spell.rarity.icon}',
      );
      log('    ${spell.rarity.displayName} • ${spell.element.displayName}');
      log('    💧 Cost: ${spell.manaCost} mana');
      log('    ${spell.targetingInfo}');
      log('    ─────────────────────');
      for (final effect in spell.effects) {
        log('    ${spell.getEffectLine(effect)}');
      }
      log('');
    }
    log('[S] Skip - learn no spell');
  }

  void _setupEnhancementShrine() {
    currentScreen = GameScreen.enhancementShrine;

    log('┌──────────────────────────────────────┐');
    log('│  ⭐ ENHANCEMENT SHRINE               │');
    log('└──────────────────────────────────────┘');
    log('');
    log('💎 Fragments: ${progression.spellFragments}');
    log('');

    if (mage!.spellLoadout.isEmpty) {
      log('You have no spells to upgrade!');
      log('[C] Continue');
      return;
    }

    log('Choose an action:');
    log('');

    log('Your spells:');
    log('');

    for (int i = 0; i < mage!.spellLoadout.length; i++) {
      final spell = mage!.spellLoadout[i];
      log('[${i + 1}] ${spell.elementIcon} ${spell.displayName}');
      log('    ${spell.compactSummary}');

      if (spell.starLevel < 3) {
        final cost = NodeResolver.getUpgradeCost(spell);
        final upgraded = spell.upgrade();
        final canAfford = progression.spellFragments >= cost;
        final affordIcon = canAfford ? '✅' : '❌';
        log('    ─────────────────────');
        log(
          '    $affordIcon Upgrade: ${spell.starsDisplay} → ${upgraded.starsDisplay}',
        );
        log('    💎 Cost: $cost fragments');
        log('    📈 ${upgraded.compactSummary}');
      } else {
        log('    ⭐ MAX LEVEL');
      }
      log('');
    }
    log('[S] Skip - upgrade nothing');
  }

  void _setupShop() {
    currentShop = NodeResolver.generateShop(mage!, currentDepth);
    currentScreen = GameScreen.shop;

    log('┌──────────────────────────────────────┐');
    log('│  🏪 SHOP                             │');
    log('└──────────────────────────────────────┘');
    log('');
    log('💎 Your Fragments: ${progression.spellFragments}');
    log('');
    log('Available items:');
    log('');

    final items = currentShop!.availableItems;
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final canAfford = progression.spellFragments >= item.cost;
      final affordIcon = canAfford ? '✅' : '❌';
      log('[$affordIcon ${i + 1}] ${item.displayText}');
      log('    ${item.type.description}');
      log('    ${item.costText}');
      log('');
    }
    log('[L] Leave shop');
  }

  void _setupRest() {
    currentScreen = GameScreen.rest;

    log('┌──────────────────────────────────────┐');
    log('│  🛏️ REST SITE                        │');
    log('└──────────────────────────────────────┘');
    log('');
    log('You find a peaceful place to rest.');
    log('');

    final healAmount = NodeResolver.getRestHealAmount(mage!);
    log('Choose an option:');
    log('');
    log('[R] Rest and recover $healAmount HP');
    log('[M] Remove one spell modifier (clears upgrades)');
    log('[B] Gain temporary buff (+25% damage for 3 nodes)');
    log('[S] Skip rest');
    log('');
    log('⚠️ Note: Rest nodes offer opportunity cost.');
    log('Choose wisely!');
  }

  void _setupRandomEvent(int depth) {
    currentRandomEvent = NodeResolver.generateRandomEvent(mage!, depth);
    currentScreen = GameScreen.randomEvent;

    log('┌──────────────────────────────────────┐');
    log('│  ${currentRandomEvent!['title']}');
    log('└──────────────────────────────────────┘');
    log('');
    log(currentRandomEvent!['description'] as String);
    log('');

    final choices = currentRandomEvent!['choices'] as List;
    for (final choice in choices) {
      log('[${choice['key']}] ${choice['text']}');
    }
  }

  /// Shows elite reward selection.
  void showEliteRewards() {
    currentEliteRewards = NodeResolver.generateEliteRewards(currentDepth);
    currentScreen = GameScreen.eliteReward;

    log('');
    log('┌──────────────────────────────────────┐');
    log('│  🏆 ELITE VICTORY REWARDS            │');
    log('└──────────────────────────────────────┘');
    log('');
    log('Choose ONE reward:');
    log('');

    final rewards = currentEliteRewards!['rewards'] as List;
    for (int i = 0; i < rewards.length; i++) {
      final reward = rewards[i];
      log('[${i + 1}] ${reward['icon']} ${reward['name']}');
      log('    ${reward['description']}');
      log('');
    }
  }

  /// Syncs new combat log entries to the main text log.
  void syncCombatLog() {
    if (currentCombat == null) return;

    final combatLog = currentCombat!.combatLog;
    for (int i = _combatLogSyncIndex; i < combatLog.length; i++) {
      textLog.add(combatLog[i]);
    }
    _combatLogSyncIndex = combatLog.length;
  }

  /// Enters target selection mode for a spell.
  void enterTargetSelection(int spellIndex) {
    if (currentCombat == null || mage == null) return;

    final spell = mage!.spellLoadout[spellIndex];
    pendingSpellIndex = spellIndex;
    currentScreen = GameScreen.targetSelect;

    log('');
    log('┌──────────────────────────────────────┐');
    log('│  🎯 SELECT TARGET: ${spell.displayName}');
    log('└──────────────────────────────────────┘');
    log('');

    final livingEnemies = currentCombat!.livingEnemies;
    for (int i = 0; i < livingEnemies.length; i++) {
      final enemy = livingEnemies[i];
      final multiplier = spell.element.getMultiplierAgainst(enemy.element);
      String effectivenessIcon;
      if (multiplier > 1.0) {
        effectivenessIcon = '✅ Strong';
      } else if (multiplier < 1.0) {
        effectivenessIcon = '❌ Weak';
      } else {
        effectivenessIcon = '➖ Neutral';
      }
      log('[${i + 1}] ${enemy.name} [${enemy.element.displayName}]');
      log('    ❤️  ${enemy.hpDisplay} | $effectivenessIcon ($multiplier×)');
    }
    log('');
    log('[C] Cancel');
  }

  /// Cancels target selection and returns to combat.
  void cancelTargetSelection() {
    pendingSpellIndex = null;
    currentScreen = GameScreen.combat;
    log('');
    log('Spell cancelled.');
  }

  /// Checks if the pending spell targets all enemies.
  bool doesPendingSpellTargetAll() {
    if (pendingSpellIndex == null || mage == null) return false;
    final spell = mage!.spellLoadout[pendingSpellIndex!];
    return spell.effects.any((e) => e.targetRule == TargetRule.all);
  }

  /// Completes the current node and advances.
  void completeNode() {
    nodeMapSystem.completeCurrentNode();
    progression.advanceNode();
    tickTemporaryBuffs();

    if (nodeMapSystem.isRunComplete) {
      endRun(victory: true);
    } else {
      showNodeMap();
    }
  }

  /// Ends the current run.
  void endRun({required bool victory}) {
    currentScreen = GameScreen.runEnd;

    // Calculate rewards
    final nodesCompleted = currentDepth - 1;
    final fragmentsEarned =
        combatsWon * 15 + elitesDefeated * 30 + nodesCompleted * 5;
    final crystalsEarned = victory ? 10 : (elitesDefeated * 2);

    progression.endRun(
      nodesCompleted: nodesCompleted,
      victory: victory,
      fragmentsEarned: fragmentsEarned,
      crystalsEarned: crystalsEarned,
    );

    log('');
    log('╔══════════════════════════════════════╗');
    if (victory) {
      log('║         🎉 VICTORY! 🎉               ║');
    } else {
      log('║         💀 DEFEAT 💀                 ║');
    }
    log('╚══════════════════════════════════════╝');
    log('');
    if (victory) {
      log('Congratulations! You have completed the run!');
    } else {
      log('${mage!.name} has fallen...');
    }
    log('');
    log('--- Run Statistics ---');
    log('Depth Reached: $nodesCompleted / ${nodeMapSystem.totalDepths}');
    log('Combats Won: $combatsWon');
    log('Elites Defeated: $elitesDefeated');
    log('Spells Learned: $spellsLearned');
    log('Spells Upgraded: $spellsUpgraded');
    log('');
    log('--- Rewards ---');
    log('💎 Fragments Earned: $fragmentsEarned');
    if (crystalsEarned > 0) {
      log('✨ Crystals Earned: $crystalsEarned');
    }
    log('');
    log(progression.getProgressSummary());
  }

  /// Resets to main menu.
  void returnToMainMenu() {
    mage = null;
    currentCombat = null;
    currentEnemies = null;
    spellChoices = null;
    currentShop = null;
    currentRandomEvent = null;
    currentEliteRewards = null;
    pendingSpellIndex = null;
    isEliteCombat = false;
    temporaryBuffs.clear();
    nodeMapSystem.reset();
    currentScreen = GameScreen.mainMenu;
    clearLog();
  }

  /// Gets available mage choices.
  List<Mage> getAvailableMages() {
    return MageDefinitions.allMages;
  }
}
