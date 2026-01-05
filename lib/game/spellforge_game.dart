import 'package:flame/game.dart';

import 'game_state.dart';
import 'game_loop.dart';
import '../systems/progression_system.dart';
import '../systems/audio_system.dart';

/// The main Flame game class that hosts the game loop.
/// Uses Flame primarily for the game loop, not for rendering.
class SpellforgeGame extends FlameGame {
  late GameState gameState;
  late GameLoop gameLoop;
  late ProgressionSystem progressionSystem;

  bool _initialized = false;

  /// Callback for when the game state changes (for UI updates).
  void Function()? onStateChanged;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    progressionSystem = ProgressionSystem();
    await progressionSystem.initialize();

    // Initialize Audio System
    await AudioSystem.initialize();

    // Start background music
    AudioSystem.playMusic('main_bg');

    gameState = GameState(progression: progressionSystem);
    // Wire up sync callback
    gameState.onStateChanged = () async {
      onStateChanged?.call();
    };

    gameLoop = GameLoop(gameState);

    _initialized = true;

    // Notify that game is ready
    onStateChanged?.call();
  }

  /// Whether the game is initialized and ready.
  bool get isReady => _initialized;

  /// Gets the current screen.
  GameScreen get currentScreen => gameState.currentScreen;

  /// Gets available actions for the current screen.
  List<String> get availableActions => gameLoop.getCurrentActions();

  // ==================== INPUT HANDLING ====================

  /// Handles a key/button input.
  void handleInput(String input) {
    final upper = input.toUpperCase();

    switch (gameState.currentScreen) {
      case GameScreen.mainMenu:
        _handleMainMenuInput(upper);
        break;
      case GameScreen.elementSelect:
        // Element selection is handled by ElementSelectionScreen widget
        break;
      case GameScreen.mageSelect:
        _handleMageSelectInput(upper);
        break;
      case GameScreen.nodeMap:
        _handleNodeMapInput(upper);
        break;
      case GameScreen.nodeChoice:
        _handleNodeChoiceInput(upper);
        break;
      case GameScreen.exploration:
        // Exploration is handled by the ExplorationScreen widget
        // Keyboard movement is handled there
        break;
      case GameScreen.combat:
        _handleCombatInput(upper);
        break;
      case GameScreen.targetSelect:
        _handleTargetSelectInput(upper);
        break;
      case GameScreen.spellLearn:
        _handleSpellLearnInput(upper);
        break;
      case GameScreen.enhancementShrine:
        _handleEnhancementInput(upper);
        break;
      case GameScreen.shop:
        _handleShopInput(upper);
        break;
      case GameScreen.rest:
        _handleRestInput(upper);
        break;
      case GameScreen.elite:
        _handleEliteInput(upper);
        break;
      case GameScreen.eliteReward:
        _handleEliteRewardInput(upper);
        break;
      case GameScreen.randomEvent:
        _handleRandomEventInput(upper);
        break;
      case GameScreen.runEnd:
        _handleRunEndInput(upper);
        break;
    }

    onStateChanged?.call();
  }

  void _handleMainMenuInput(String input) {
    if (input == 'N') {
      gameState.showElementSelection();
    }
  }

  void _handleMageSelectInput(String input) {
    final index = int.tryParse(input);
    if (index != null && index >= 1 && index <= 4) {
      gameLoop.selectMage(index - 1);
    }
  }

  void _handleNodeMapInput(String input) {
    if (input == 'E') {
      gameLoop.enterNode();
    }
  }

  void _handleNodeChoiceInput(String input) {
    final index = int.tryParse(input);
    if (index != null && index >= 1 && index <= 2) {
      gameLoop.selectNode(index - 1);
    }
  }

  void _handleCombatInput(String input) {
    if (input == 'E') {
      gameLoop.endTurn();
    } else {
      final index = int.tryParse(input);
      if (index != null && index >= 1) {
        // Use initiateSpellCast which handles target selection if needed
        gameLoop.initiateSpellCast(index - 1);
      }
    }
  }

  void _handleTargetSelectInput(String input) {
    if (input == 'C') {
      gameLoop.cancelTargetSelection();
    } else {
      final index = int.tryParse(input);
      if (index != null && index >= 1) {
        final livingEnemies = gameState.currentCombat?.livingEnemies ?? [];
        if (index <= livingEnemies.length) {
          gameLoop.confirmTarget(index - 1);
        }
      }
    }
  }

  void _handleSpellLearnInput(String input) {
    if (input == 'S') {
      gameLoop.skipSpellLearn();
    } else {
      final index = int.tryParse(input);
      if (index != null && index >= 1 && index <= 3) {
        gameLoop.learnSpell(index - 1);
      }
    }
  }

  void _handleEnhancementInput(String input) {
    if (input == 'S' || input == 'C') {
      gameLoop.skipEnhancement();
    } else {
      final index = int.tryParse(input);
      if (index != null && index >= 1 && index <= 4) {
        gameLoop.upgradeSpell(index - 1);
      }
    }
  }

  void _handleShopInput(String input) {
    if (input == 'L') {
      gameLoop.leaveShop();
    } else {
      final index = int.tryParse(input);
      if (index != null && index >= 1) {
        gameLoop.purchaseShopItem(index - 1);
      }
    }
  }

  void _handleRestInput(String input) {
    if (input == 'R') {
      gameLoop.rest();
    } else if (input == 'S') {
      gameLoop.skipRest();
    } else if (input == 'M') {
      gameLoop.removeSpellModifier();
    } else if (input == 'B') {
      gameLoop.gainTempBuff();
    }
  }

  void _handleEliteInput(String input) {
    if (input == 'Y') {
      gameLoop.confirmEliteCombat();
    } else if (input == 'N') {
      gameLoop.retreatFromElite();
    }
  }

  void _handleEliteRewardInput(String input) {
    final index = int.tryParse(input);
    if (index != null && index >= 1 && index <= 3) {
      gameLoop.selectEliteReward(index - 1);
    }
  }

  void _handleRandomEventInput(String input) {
    gameLoop.handleRandomEventChoice(input);
  }

  void _handleRunEndInput(String input) {
    if (input == 'M') {
      gameLoop.returnToMenu();
    } else if (input == 'N') {
      // Play Again - go directly to spell selection
      gameState.showElementSelection();
    }
  }
}
