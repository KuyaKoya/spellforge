import '../data/mage_definitions.dart';
import '../data/spell_definitions.dart';
import '../domain/enemy.dart';
import '../domain/mage.dart';
import '../domain/spell.dart';
import '../domain/effect.dart';
import '../systems/combat_system.dart';
import '../systems/node_system.dart';
import '../systems/progression_system.dart';

/// The current screen/mode of the game.
enum GameScreen {
  mainMenu,
  mageSelect,
  nodeMap,
  combat,
  targetSelect,
  spellLearn,
  enhancementShrine,
  rest,
  randomEvent,
  runEnd,
}

/// Represents the complete state of a game run.
class GameState {
  // Systems
  final ProgressionSystem progression;
  final NodeSystem nodeSystem;

  // Current screen
  GameScreen currentScreen;

  // Player state
  Mage? mage;
  CombatSystem? currentCombat;

  // Node-specific state
  List<Spell>? spellChoices;
  List<Enemy>? currentEnemies;

  // Target selection state
  int? pendingSpellIndex;

  // Random event state
  Map<String, dynamic>? currentRandomEvent;

  // Combat log sync tracking
  int _combatLogSyncIndex = 0;

  // Text log for display
  final List<String> textLog;

  // Run statistics
  int combatsWon = 0;
  int spellsLearned = 0;
  int spellsUpgraded = 0;

  GameState({required this.progression, NodeSystem? nodeSystem})
    : nodeSystem = nodeSystem ?? NodeSystem(),
      currentScreen = GameScreen.mainMenu,
      textLog = [];

  /// Whether the player is alive.
  bool get isPlayerAlive => mage?.isAlive ?? false;

  /// Whether a run is in progress.
  bool get isRunInProgress =>
      mage != null && currentScreen != GameScreen.mainMenu;

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

  /// Starts a new run with the given mage.
  void startRun(Mage selectedMage) {
    mage = selectedMage.freshCopy();
    currentScreen = GameScreen.nodeMap;
    combatsWon = 0;
    spellsLearned = 0;
    spellsUpgraded = 0;

    // Generate the run
    nodeSystem.generateRun(nodeCount: 10);
    progression.startNewRun();

    // Give starting spell based on element
    final startingSpells = SpellDefinitions.getByElement(
      mage!.primaryElement,
    ).where((s) => s.rarity == SpellRarity.common).toList();
    if (startingSpells.isNotEmpty) {
      mage!.learnSpell(startingSpells.first);
    }

    clearLog();
    log('=== NEW RUN STARTED ===');
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
  }

  /// Enters the current node.
  void enterCurrentNode() {
    final node = nodeSystem.currentNode;
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
        _setupCombat(node.index);
        break;
      case NodeType.spellLearn:
        _setupSpellLearn(node.index);
        break;
      case NodeType.enhancementShrine:
        _setupEnhancementShrine();
        break;
      case NodeType.rest:
        _setupRest();
        break;
      case NodeType.randomEvent:
        _setupRandomEvent(node.index);
        break;
      case NodeType.bossCombat:
        _setupBossCombat(node.index);
        break;
    }
  }

  void _setupCombat(int nodeIndex) {
    currentEnemies = NodeResolver.generateCombatEncounter(
      nodeIndex,
    ).cast<Enemy>();

    currentCombat = CombatSystem(mage: mage!, enemies: currentEnemies!);
    currentCombat!.startCombat();
    currentScreen = GameScreen.combat;

    // Transfer combat log and set sync index
    textLog.addAll(currentCombat!.combatLog);
    _combatLogSyncIndex = currentCombat!.combatLog.length;
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

  void _setupSpellLearn(int nodeIndex) {
    spellChoices = NodeResolver.generateSpellChoices(mage!, nodeIndex);
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

  void _setupRest() {
    currentScreen = GameScreen.rest;

    final healAmount = NodeResolver.getRestHealAmount(mage!);
    log('You find a peaceful place to rest.');
    log('');
    log('[R] Rest and recover $healAmount HP');
    log('[S] Skip rest');
  }

  void _setupRandomEvent(int nodeIndex) {
    currentRandomEvent = NodeResolver.generateRandomEvent(mage!, nodeIndex);
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

  void _setupBossCombat(int nodeIndex) {
    currentEnemies = NodeResolver.generateBossEncounter(
      nodeIndex,
    ).cast<Enemy>();

    currentCombat = CombatSystem(mage: mage!, enemies: currentEnemies!);
    currentCombat!.startCombat();
    currentScreen = GameScreen.combat;

    // Transfer combat log and set sync index
    textLog.addAll(currentCombat!.combatLog);
    _combatLogSyncIndex = currentCombat!.combatLog.length;
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
    nodeSystem.completeCurrentNode();
    progression.advanceNode();

    if (nodeSystem.isRunComplete) {
      endRun(victory: true);
    } else {
      currentScreen = GameScreen.nodeMap;
      log('');
      log('Node complete! Moving to the next area...');
    }
  }

  /// Ends the current run.
  void endRun({required bool victory}) {
    currentScreen = GameScreen.runEnd;

    // Calculate rewards
    final nodesCompleted = nodeSystem.currentNodeIndex;
    final fragmentsEarned = combatsWon * 15 + nodesCompleted * 5;
    final crystalsEarned = victory ? 10 : 0;

    progression.endRun(
      nodesCompleted: nodesCompleted,
      victory: victory,
      fragmentsEarned: fragmentsEarned,
      crystalsEarned: crystalsEarned,
    );

    log('');
    log('=== RUN END ===');
    log('');
    if (victory) {
      log('🎉 VICTORY! You have completed the run!');
    } else {
      log('💀 DEFEAT! ${mage!.name} has fallen...');
    }
    log('');
    log('--- Run Statistics ---');
    log('Nodes Completed: $nodesCompleted / ${nodeSystem.totalNodes}');
    log('Combats Won: $combatsWon');
    log('Spells Learned: $spellsLearned');
    log('Spells Upgraded: $spellsUpgraded');
    log('');
    log('--- Rewards ---');
    log('Fragments Earned: $fragmentsEarned');
    if (crystalsEarned > 0) {
      log('Crystals Earned: $crystalsEarned');
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
    pendingSpellIndex = null;
    nodeSystem.reset();
    currentScreen = GameScreen.mainMenu;
    clearLog();
  }

  /// Gets available mage choices.
  List<Mage> getAvailableMages() {
    return MageDefinitions.allMages;
  }
}
