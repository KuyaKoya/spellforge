import '../data/mage_definitions.dart';
import '../data/spell_definitions.dart';
import '../domain/enemy.dart';
import '../domain/mage.dart';
import '../domain/spell.dart';
import '../domain/effect.dart';
import '../domain/element.dart';
import '../systems/combat_system.dart';
import '../nodes/nodes.dart';
import '../systems/node_resolver.dart';
import '../systems/progression_system.dart';
import '../systems/shop_system.dart';
import '../director/director_system.dart';
import '../systems/audio_manager.dart';

/// The current screen/mode of the game.
enum GameScreen {
  mainMenu,
  elementSelect, // Phase 7.6.1: Choose starting element type
  mageSelect, // Legacy - kept for compatibility
  nodeMap,
  nodeChoice,
  exploration, // Spatial exploration room before combat
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
  final DirectorSystem director;

  /// Callback for UI updates
  Future<void> Function()? onStateChanged;

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

  // Track if the main interaction of the current node has been completed
  // Used for single-use nodes like Rest/Shrines to persist the screen until user leaves
  bool nodeInteractionCompleted = false;

  // Target selection state
  int? pendingSpellIndex;

  // Random event state
  Map<String, dynamic>? currentRandomEvent;

  // Elite reward state
  Map<String, dynamic>? currentEliteRewards;
  int? selectedRewardIndex;

  // Run statistics
  int combatsWon = 0;
  int elitesDefeated = 0;
  int spellsLearned = 0;
  int spellsUpgraded = 0;

  // Narrative tracking (Phase 7.7)
  // Track which elite dialogues have been shown this run
  final Set<String> _shownEliteDialogues = {};

  GameState({
    required this.progression,
    NodeMapSystem? nodeMapSystem,
    DirectorSystem? director,
  }) : nodeMapSystem = nodeMapSystem ?? NodeMapSystem(),
       director = director ?? DirectorSystem(),
       currentScreen = GameScreen.mainMenu;

  /// Whether the player is alive.
  bool get isPlayerAlive => mage?.isAlive ?? false;

  /// Whether a run is in progress.
  bool get isRunInProgress =>
      mage != null && currentScreen != GameScreen.mainMenu;

  /// Current depth in the run (1-indexed).
  int get currentDepth => nodeMapSystem.currentDepth;

  /// Applies temporary buffs damage multiplier.
  double get temporaryBuffMultiplier {
    double multiplier = 1.0;
    for (final buff in temporaryBuffs.where((b) => b.isActive)) {
      multiplier += buff.value / 100.0;
    }
    return multiplier;
  }

  // ==================== NARRATIVE METHODS (Phase 7.7) ====================

  /// Checks if we should show dialogue for an elite enemy.
  /// Returns true if this elite hasn't had their dialogue shown this run.
  bool shouldShowEliteDialogue(String eliteName) {
    return !_shownEliteDialogues.contains(eliteName);
  }

  /// Marks an elite's dialogue as shown for this run.
  void markEliteDialogueShown(String eliteName) {
    _shownEliteDialogues.add(eliteName);
  }

  /// Ticks temporary buffs (called after each node).
  void tickTemporaryBuffs() {
    for (final buff in temporaryBuffs) {
      buff.tick();
    }
    temporaryBuffs.removeWhere((b) => !b.isActive);
  }

  /// Starts a new run with the given mage.
  /// Goes directly to exploration room with doors for first node choice.
  void startRun(Mage selectedMage) {
    mage = selectedMage.freshCopy();
    combatsWon = 0;
    elitesDefeated = 0;
    spellsLearned = 0;
    spellsUpgraded = 0;
    temporaryBuffs.clear();
    _shownEliteDialogues.clear(); // Phase 7.7
    currentEnemies = null;
    isEliteCombat = false;
    nodeInteractionCompleted = false;

    // Generate the run with the new node map system
    nodeMapSystem.generateRun(maxDepth: 10);
    progression.startNewRun();
    director.initialize(
      seed: DateTime.now().millisecondsSinceEpoch,
      ascensionLevel: 0,
      startingElement: mage!.primaryElement,
    );

    // Give starting spell based on element
    final startingSpells = SpellDefinitions.getByElement(
      mage!.primaryElement,
    ).where((s) => s.rarity == SpellRarity.common).toList();
    if (startingSpells.isNotEmpty) {
      mage!.learnSpell(startingSpells.first);
    }
    // Go directly to exploration mode
    // First room is empty - just doors to choose first node
    currentScreen = GameScreen.exploration;
    AudioManager.instance.transitionToMusicState(MusicState.exploration);
  }

  /// Shows element selection screen (Phase 7.6.1).
  /// Player chooses a starting element type instead of a specific spell.
  void showElementSelection() {
    currentScreen = GameScreen.elementSelect;
    // No spell choices needed - element selection is UI-driven
    spellChoices = null;

    // Ensure music is playing (in case we came from somewhere else)
    AudioManager.instance.transitionToMusicState(MusicState.exploration);
  }

  /// Selects a starting element type (Phase 7.6.1).
  /// Creates a mage of that element and gives them the basic spell.
  void selectStartingElement(Element element) {
    // Create a mage for the chosen element
    final elementalMage = _createMageForElement(element);
    mage = elementalMage;

    // Phase 7.8: Apply max HP modifier from elemental progression
    final modifiers = progression.getActiveModifiers();
    if (modifiers.isNotEmpty) {
      // Import is already there via progression_system.dart
      final hpMultiplier = _getMaxHPMultiplier(modifiers);
      if (hpMultiplier != 1.0) {
        final originalMaxHP = mage!.maxHP;
        mage!.maxHP = (mage!.maxHP * hpMultiplier).round();
        mage!.currentHP = mage!.maxHP; // Start at full HP
        // Log adjustment (negative values are tradeoffs)
        if (hpMultiplier < 1.0) {
          final reduction = originalMaxHP - mage!.maxHP;
          print('Phase 7.8: Max HP reduced by $reduction (tradeoff)');
        } else {
          final bonus = mage!.maxHP - originalMaxHP;
          print('Phase 7.8: Max HP increased by $bonus (bonus)');
        }
      }
    }

    // Phase 7.8: Apply mana cost modifiers from elemental progression
    _applyManaCostModifiers(modifiers);

    // Phase 7.8: Apply speed modifier (extra actions per turn)
    _applySpeedModifier(modifiers);

    // Give the mage the basic spell of their element
    final startingSpells = SpellDefinitions.getByElement(
      element,
    ).where((s) => s.rarity == SpellRarity.common).toList();
    if (startingSpells.isNotEmpty) {
      mage!.learnSpell(startingSpells.first);
    }

    // Record starting element for Director influence
    _startingElement = element;

    // Start the run
    combatsWon = 0;
    elitesDefeated = 0;
    spellsLearned = 0;
    spellsUpgraded = 0;
    temporaryBuffs.clear();
    _shownEliteDialogues.clear(); // Phase 7.7
    currentEnemies = null;
    isEliteCombat = false;
    nodeInteractionCompleted = false;

    nodeMapSystem.generateRun(maxDepth: 10);
    progression.startNewRun();
    director.initialize(
      seed: DateTime.now().millisecondsSinceEpoch,
      ascensionLevel: 0,
      startingElement: _startingElement,
    );
    // Go to exploration mode
    currentScreen = GameScreen.exploration;
    AudioManager.instance.transitionToMusicState(MusicState.exploration);
  }

  /// Phase 7.8: Calculate max HP multiplier from modifiers.
  double _getMaxHPMultiplier(List<dynamic> modifiers) {
    double multiplier = 1.0;
    for (final mod in modifiers) {
      if (mod.type.toString().contains('maxHPPercent')) {
        multiplier += (mod.isPositive ? mod.value : -mod.value) / 100.0;
      }
    }
    return multiplier.clamp(0.5, 2.0);
  }

  /// Phase 7.8: Apply mana cost modifiers for each element.
  void _applyManaCostModifiers(List<dynamic> modifiers) {
    if (mage == null) return;

    // Clear existing modifiers
    mage!.manaCostModifiers.clear();

    for (final mod in modifiers) {
      if (mod.type.toString().contains('manaCostFlat')) {
        final element = mod.targetElement as Element?;
        final value = mod.isPositive
            ? -mod.value
            : mod.value; // Positive modifier = cheaper

        if (element != null) {
          mage!.manaCostModifiers[element] =
              ((mage!.manaCostModifiers[element] ?? 0) + value).toInt();
        } else {
          // Apply to all elements
          for (final e in Element.values) {
            mage!.manaCostModifiers[e] =
                ((mage!.manaCostModifiers[e] ?? 0) + value).toInt();
          }
        }
      }
    }
  }

  /// Phase 7.8: Apply speed modifier (extra actions per turn).
  void _applySpeedModifier(List<dynamic> modifiers) {
    if (mage == null) return;

    double speedMultiplier = 1.0;
    for (final mod in modifiers) {
      if (mod.type.toString().contains('speedPercent')) {
        speedMultiplier += (mod.isPositive ? mod.value : -mod.value) / 100.0;
      }
    }

    // Convert speed multiplier to extra actions (10% = 0.1 extra, so 100% = 1 extra action)
    if (speedMultiplier > 1.0) {
      final extraActions = ((speedMultiplier - 1.0) * 2)
          .round(); // 50% speed = 1 extra action
      if (extraActions > 0) {
        mage!.actionsPerTurn += extraActions;
        print('Phase 7.8: +$extraActions actions per turn from speed bonus');
      }
    }
  }

  /// The starting element chosen by the player (Phase 7.6.1).
  /// Used for Director influence on spell/enemy generation.
  Element? _startingElement;
  Element? get startingElement => _startingElement;

  /// Creates a mage for the given element.
  Mage _createMageForElement(Element element) {
    switch (element) {
      case Element.fire:
        return MageDefinitions.pyromancer().freshCopy();
      case Element.water:
        return MageDefinitions.hydromancer().freshCopy();
      case Element.earth:
        return MageDefinitions.geomancer().freshCopy();
      case Element.air:
        return MageDefinitions.aeromancer().freshCopy();
    }
  }

  /// Shows the node map with available choices.
  void showNodeMap() {
    currentScreen = GameScreen.nodeMap;

    final depthLevel = nodeMapSystem.currentDepthLevel;
    if (depthLevel == null) {
      endRun(victory: true);
      return;
    }
    if (depthLevel.hasChoice) {
      currentScreen = GameScreen.nodeChoice;
      for (int i = 0; i < depthLevel.nodeChoices.length; i++) {
        final node = depthLevel.nodeChoices[i];
        // Show risk/reward info for elite nodes
        if (node.type == NodeType.elite) {}
      }
    } else {
      // Single path - show node info
      final node = depthLevel.nodeChoices.first;
      // Auto-select the only option
      nodeMapSystem.selectNode(0);
    }
  }

  /// Selects a node from the available choices.
  void selectNodeChoice(int choiceIndex) {
    print('DEBUG: selectNodeChoice($choiceIndex)');
    final depthLevel = nodeMapSystem.currentDepthLevel;
    if (depthLevel == null) {
      print('DEBUG: Depth level is null');
      return;
    }

    if (choiceIndex < 0 || choiceIndex >= depthLevel.nodeChoices.length) {
      print('DEBUG: Invalid choice index');
      return;
    }

    nodeMapSystem.selectNode(choiceIndex);
    enterCurrentNode();
  }

  /// Enters the current node.
  void enterCurrentNode() {
    final node = nodeMapSystem.currentNode;
    if (node == null) {
      print('DEBUG: Current node is null');
      // Run complete
      endRun(victory: true);
      return;
    }

    print('DEBUG: Entering node type: ${node.type}');
    nodeInteractionCompleted = false;

    // ALL node types go through exploration screen first
    // Combat nodes: show enemy
    // Non-combat nodes: show interactable object (merchant, altar, campfire, etc.)
    switch (node.type) {
      case NodeType.combat:
        _setupCombat(currentDepth);
        break;
      case NodeType.elite:
        _setupEliteCombat(currentDepth);
        break;
      case NodeType.bossCombat:
        _setupBossCombat(currentDepth);
        break;
      case NodeType.spellLearn:
      case NodeType.enhancementShrine:
      case NodeType.shop:
      case NodeType.rest:
      case NodeType.randomEvent:
        // Non-combat: show exploration room with interactable
        // Player taps interactable to open the actual screen
        currentScreen = GameScreen.exploration;
        break;
    }
  }

  /// Opens a non-combat node screen (called when player taps interactable)
  void openNonCombatScreen(NodeType nodeType) {
    switch (nodeType) {
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
      case NodeType.randomEvent:
        _setupRandomEvent(currentDepth);
        break;
      default:
        break;
    }
  }

  void _setupCombat(int depth) {
    print('DEBUG: Setting up combat for depth $depth');
    // Phase 7.9: Generate enemy with meta difficulty scaling
    currentEnemies = NodeResolver.generateCombatEncounter(
      depth,
      startingElement: _startingElement,
      metaMods: progression.metaDifficultyModifiers,
    ).cast<Enemy>();
    print(
      'DEBUG: Generated ${currentEnemies?.length} enemies (Meta Tier ${progression.metaDifficultyTier})',
    );
    isEliteCombat = false;

    // Enter exploration screen - player taps enemy to engage
    currentScreen = GameScreen.exploration;
  }

  /// Starts combat directly (used by exploration screen callback).
  void startCombatDirectly(List<Enemy> enemies, {bool isElite = false}) {
    currentEnemies = enemies;
    isEliteCombat = isElite;

    // Transition to appropriate combat music
    final isBoss = nodeMapSystem.currentNode?.type == NodeType.bossCombat;
    if (isBoss) {
      AudioManager.instance.transitionToMusicState(MusicState.bossCombat);
    } else if (isElite) {
      AudioManager.instance.transitionToMusicState(MusicState.eliteCombat);
    } else {
      AudioManager.instance.transitionToMusicState(MusicState.normalCombat);
    }

    currentCombat = CombatSystem(
      mage: mage!,
      enemies: currentEnemies!,
      damageMultiplier: temporaryBuffMultiplier,
      onStateChanged: onStateChanged,
      elementalModifiers: progression.getActiveModifiers(),
    );
    currentCombat!.startCombat();
    currentScreen = GameScreen.combat;
  }

  void _setupEliteCombat(int depth) {
    // Phase 7.9: Generate elite enemy with meta difficulty scaling
    final elites = NodeResolver.generateEliteEncounter(
      depth,
      startingElement: _startingElement,
      metaMods: progression.metaDifficultyModifiers,
    );
    currentEnemies = elites.cast<Enemy>();
    isEliteCombat = true;

    // Enter exploration screen - player taps elite to engage
    currentScreen = GameScreen.exploration;
  }

  /// Starts the elite combat after confirmation.
  void confirmEliteCombat() {
    currentCombat = CombatSystem(
      mage: mage!,
      enemies: currentEnemies!,
      damageMultiplier: temporaryBuffMultiplier,
      onStateChanged: onStateChanged,
      elementalModifiers: progression.getActiveModifiers(),
    );
    currentCombat!.startCombat();
    currentScreen = GameScreen.combat;
  }

  /// Retreats from elite (skips node without reward).
  void retreatFromElite() {
    isEliteCombat = false;
    completeNode();
  }

  void _setupBossCombat(int depth) {
    // Phase 7.9: Generate boss enemies with meta difficulty scaling
    currentEnemies = NodeResolver.generateBossEncounter(
      depth,
      metaMods: progression.metaDifficultyModifiers,
    ).cast<Enemy>();
    isEliteCombat = false;

    // Enter exploration screen - player taps bosses to engage
    currentScreen = GameScreen.exploration;
  }

  void _setupSpellLearn(int depth) {
    spellChoices = NodeResolver.generateSpellChoices(mage!, depth);
    currentScreen = GameScreen.spellLearn;
  }

  void _setupEnhancementShrine() {
    currentScreen = GameScreen.enhancementShrine;
  }

  void _setupShop() {
    currentShop = NodeResolver.generateShop(mage!, currentDepth);
    currentScreen = GameScreen.shop;
  }

  void _setupRest() {
    currentScreen = GameScreen.rest;
  }

  void _setupRandomEvent(int depth) {
    currentRandomEvent = NodeResolver.generateRandomEvent(mage!, depth);
    currentScreen = GameScreen.randomEvent;
  }

  /// Shows elite reward selection.
  /// Phase 7.6.5: Passes starting element for guaranteed element-matched spell.
  void showEliteRewards() {
    currentEliteRewards = NodeResolver.generateEliteRewards(
      currentDepth,
      startingElement: _startingElement,
    );
    currentScreen = GameScreen.eliteReward;
  }

  /// Enters target selection mode for a spell.
  void enterTargetSelection(int spellIndex) {
    if (currentCombat == null || mage == null) return;

    pendingSpellIndex = spellIndex;
    currentScreen = GameScreen.targetSelect;
  }

  /// Cancels target selection and returns to combat.
  void cancelTargetSelection() {
    pendingSpellIndex = null;
    currentScreen = GameScreen.combat;
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

    // Reset interaction state
    nodeInteractionCompleted = false;

    // Clear combat state
    currentCombat = null;
    currentEnemies = null;
    isEliteCombat = false;

    // Resume exploration music
    AudioManager.instance.transitionToMusicState(MusicState.exploration);

    if (nodeMapSystem.isRunComplete) {
      endRun(victory: true);
    } else {
      // Go to exploration mode to choose next room
      currentScreen = GameScreen.exploration;
    }
  }

  /// Ends the current run.
  /// For Act 1: Defeating the Gatekeepers does not end the loop.
  /// Player returns to the beginning. Fragments and crystals persist.
  /// Narrative certainty does not.
  void endRun({required bool victory}) {
    currentScreen = GameScreen.runEnd;

    // Could play different music for victory/defeat screen here
    // For now, keep exploration/ambient or silence?
    // Let's stick to exploration as "neutral"
    AudioManager.instance.transitionToMusicState(MusicState.exploration);

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
    if (victory) {
      // Act 1 Victory - calm, incomplete, slightly unsettling
    } else {
      // Act 1 Defeat - calm, inevitable
      if (nodesCompleted <= 3) {
      } else {}
    }
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
    nodeInteractionCompleted = false;
    temporaryBuffs.clear();
    nodeMapSystem.reset();
    currentScreen = GameScreen.mainMenu;

    // Ensure menu music plays
    AudioManager.instance.transitionToMusicState(MusicState.exploration);
  }

  /// Gets available mage choices.
  List<Mage> getAvailableMages() {
    return MageDefinitions.allMages;
  }
}
