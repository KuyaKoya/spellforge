import '../data/mage_definitions.dart';
import '../data/spell_definitions.dart';
import '../domain/enemy.dart';
import '../domain/mage.dart';
import '../domain/spell.dart';
import '../domain/effect.dart';
import '../domain/element.dart';
import '../systems/combat_system.dart';
import '../systems/telemetry_service.dart';
import '../nodes/nodes.dart';
import '../systems/node_resolver.dart';
import '../systems/progression_system.dart';
import '../systems/shop_system.dart';

/// The current screen/mode of the game.
enum GameScreen {
  mainMenu,
  spellSelect, // NEW: Spell selection instead of mage selection
  mageSelect,
  nodeMap,
  nodeChoice,
  exploration, // NEW: Spatial exploration room before combat
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

  GameState({required this.progression, NodeMapSystem? nodeMapSystem})
    : nodeMapSystem = nodeMapSystem ?? NodeMapSystem(),
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
    currentEnemies = null;
    isEliteCombat = false;
    nodeInteractionCompleted = false;

    // Generate the run with the new node map system
    nodeMapSystem.generateRun(maxDepth: 10);
    progression.startNewRun();

    // A5: Start telemetry tracking for this run
    TelemetryService.instance.startRun(
      mageId: mage!.id,
      startingElement: mage!.primaryElement.name,
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
  }

  /// Shows spell selection screen with one spell from each element.
  void showSpellSelection() {
    currentScreen = GameScreen.spellSelect;

    // Get one common spell from each element
    spellChoices = [
      SpellDefinitions.getByElement(
        Element.fire,
      ).where((s) => s.rarity == SpellRarity.common).first,
      SpellDefinitions.getByElement(
        Element.water,
      ).where((s) => s.rarity == SpellRarity.common).first,
      SpellDefinitions.getByElement(
        Element.earth,
      ).where((s) => s.rarity == SpellRarity.common).first,
      SpellDefinitions.getByElement(
        Element.air,
      ).where((s) => s.rarity == SpellRarity.common).first,
    ];
  }

  /// Selects a starting spell and creates a default mage based on its element.
  void selectStartingSpell(Spell selectedSpell) {
    // Create a default mage based on spell element
    final elementalMage = _createMageForElement(selectedSpell.element);

    // Give the mage the selected spell
    mage = elementalMage;
    mage!.learnSpell(selectedSpell);

    // Start the run
    combatsWon = 0;
    elitesDefeated = 0;
    spellsLearned = 0;
    spellsUpgraded = 0;
    temporaryBuffs.clear();
    currentEnemies = null;
    isEliteCombat = false;
    nodeInteractionCompleted = false;

    nodeMapSystem.generateRun(maxDepth: 10);
    progression.startNewRun();
    // Go to exploration mode
    currentScreen = GameScreen.exploration;
  }

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
    // Generate enemy for exploration room
    currentEnemies = NodeResolver.generateCombatEncounter(depth).cast<Enemy>();
    print('DEBUG: Generated ${currentEnemies?.length} enemies');
    isEliteCombat = false;

    // Enter exploration screen - player taps enemy to engage
    currentScreen = GameScreen.exploration;
  }

  /// Starts combat directly (used by exploration screen callback).
  void startCombatDirectly(List<Enemy> enemies, {bool isElite = false}) {
    currentEnemies = enemies;
    isEliteCombat = isElite;

    currentCombat = CombatSystem(mage: mage!, enemies: currentEnemies!);
    currentCombat!.startCombat();
    currentScreen = GameScreen.combat;
  }

  void _setupEliteCombat(int depth) {
    // Generate elite enemy for exploration room
    final elites = NodeResolver.generateEliteEncounter(depth);
    currentEnemies = elites.cast<Enemy>();
    isEliteCombat = true;

    // Enter exploration screen - player taps elite to engage
    currentScreen = GameScreen.exploration;
  }

  /// Starts the elite combat after confirmation.
  void confirmEliteCombat() {
    currentCombat = CombatSystem(mage: mage!, enemies: currentEnemies!);
    currentCombat!.startCombat();
    currentScreen = GameScreen.combat;
  }

  /// Retreats from elite (skips node without reward).
  void retreatFromElite() {
    isEliteCombat = false;
    completeNode();
  }

  void _setupBossCombat(int depth) {
    // Generate boss enemies for exploration room
    currentEnemies = NodeResolver.generateBossEncounter(depth).cast<Enemy>();
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
  void showEliteRewards() {
    currentEliteRewards = NodeResolver.generateEliteRewards(currentDepth);
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
  void endRun({required bool victory, String? deathCause}) {
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

    // A5: End telemetry tracking for this run
    TelemetryService.instance.endRun(
      victory: victory,
      depth: currentDepth,
      deathCause: deathCause,
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
  }

  /// Gets available mage choices.
  List<Mage> getAvailableMages() {
    return MageDefinitions.allMages;
  }
}
