import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../systems/audio_manager.dart';

import '../game/spellforge_game.dart';
import '../game/game_state.dart';
import '../game/exploration/exploration_controller.dart';
import '../game/exploration/components/door_interactable.dart';
import '../nodes/nodes.dart';
import '../narrative/journey_log.dart';
import 'battle/battle.dart';
import 'exploration/exploration_screen_v2.dart';
import 'exploration/overlays/rest_overlay.dart';
import 'exploration/overlays/enhancement_shrine_overlay.dart';
import 'exploration/overlays/spell_shrine_overlay.dart';
import 'exploration/overlays/shop_overlay.dart';
import 'exploration/overlays/elite_reward_overlay.dart';
import 'exploration/overlays/random_event_overlay.dart';
import 'exploration/overlays/game_over_overlay.dart';
import 'exploration/overlays/main_menu_overlay.dart';
import 'exploration/overlays/element_selection_overlay.dart';
// Phase 7.7: Narrative system
import '../narrative/narrative.dart';
import 'narrative_overlay.dart';
import 'settings/settings_overlay.dart';

/// The main game UI renderer.
class TextGameWidget extends StatefulWidget {
  final SpellforgeGame game;

  const TextGameWidget({super.key, required this.game});

  @override
  State<TextGameWidget> createState() => _TextGameWidgetState();
}

class _TextGameWidgetState extends State<TextGameWidget> {
  final JourneyLog _journeyLog = JourneyLog();

  // Current room configuration for exploration
  RoomConfiguration? _currentRoomConfig;

  bool get _isInBattleMode {
    if (!widget.game.isReady) return false;
    final screen = widget.game.currentScreen;
    return screen == GameScreen.combat || screen == GameScreen.targetSelect;
  }

  bool get _shouldShowExplorationBackground {
    if (!widget.game.isReady) return false;
    final screen = widget.game.currentScreen;
    return screen == GameScreen.exploration ||
        screen == GameScreen.rest ||
        screen == GameScreen.enhancementShrine ||
        screen == GameScreen.spellLearn ||
        screen == GameScreen.shop ||
        screen == GameScreen.eliteReward ||
        screen == GameScreen.randomEvent;
  }

  @override
  void initState() {
    super.initState();
    widget.game.onStateChanged = _onGameStateChanged;
  }

  @override
  void dispose() {
    widget.game.onStateChanged = null;
    super.dispose();
  }

  void _onGameStateChanged() {
    // Reset room config if not in exploration-related mode
    // OR if we're still in exploration but our cached config is outdated
    if (!_shouldShowExplorationBackground) {
      _currentRoomConfig = null;
    } else if (_currentRoomConfig != null) {
      // Check if the current room is now stale (node completed, or config doesn't match gamestate)
      final gameState = widget.game.gameState;
      final currentNode = gameState.nodeMapSystem.currentNode;

      // Determine current room ID to compare
      String expectedRoomId;
      if (currentNode == null) {
        expectedRoomId = 'start_room_${gameState.currentDepth}';
      } else {
        expectedRoomId = 'node_${currentNode.depth}_${currentNode.pathIndex}';
      }

      // If room ID changed OR enemy state changed OR interaction state changed, reset config
      final configEnemyDefeated = _currentRoomConfig!.enemyDefeated;
      final hasLivingEnemy =
          gameState.currentEnemies?.isNotEmpty == true &&
          gameState.currentEnemies!.first.isAlive;

      // Check if interaction completed state is out of sync
      final configInteractionCompleted =
          _currentRoomConfig!.interactionCompleted;
      final stateInteractionCompleted = gameState.nodeInteractionCompleted;

      if (_currentRoomConfig!.roomId != expectedRoomId ||
          (configEnemyDefeated == false &&
              !hasLivingEnemy &&
              gameState.currentEnemies != null) ||
          (configInteractionCompleted != stateInteractionCompleted)) {
        _currentRoomConfig = null;
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: _handleBackPress,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Show element selection screen (Phase 7.6.1)
    if (widget.game.gameState.currentScreen == GameScreen.elementSelect) {
      return ElementSelectionOverlay(
        onElementSelected: (element) {
          widget.game.gameState.selectStartingElement(element);
          _onGameStateChanged();
        },
      );
    }

    // Show exploration screen (and overlays) during exploration-related modes
    if (_shouldShowExplorationBackground &&
        widget.game.gameState.mage != null) {
      return Stack(
        children: [
          // Base: Exploration Screen
          _buildExplorationScreen(),

          // Overlay: Rest Site
          if (widget.game.currentScreen == GameScreen.rest)
            Container(
              color: Colors.black54,
              child: RestOverlay(
                mage: widget.game.gameState.mage!,
                isActionCompleted:
                    widget.game.gameState.nodeInteractionCompleted,
                onRest: () {
                  widget.game.gameLoop.rest();
                  _onGameStateChanged();
                },
                onBuff: () {
                  widget.game.gameLoop.gainTempBuff();
                  _onGameStateChanged();
                },
                onRemoveModifier: () {
                  widget.game.gameLoop.removeSpellModifier();
                  _onGameStateChanged();
                },
                onLeave: () {
                  if (widget.game.gameState.nodeInteractionCompleted) {
                    widget.game.gameLoop.leaveCurrentNode();
                  } else {
                    widget.game.gameLoop.skipRest();
                  }
                  _onGameStateChanged();
                },
              ),
            ),

          // Overlay: Enhancement Shrine
          if (widget.game.currentScreen == GameScreen.enhancementShrine)
            Container(
              color: Colors.black54,
              child: EnhancementShrineOverlay(
                mage: widget.game.gameState.mage!,
                spellFragments: widget.game.progressionSystem.spellFragments,
                isActionCompleted:
                    widget.game.gameState.nodeInteractionCompleted,
                onUpgrade: (index, upgradePath) async {
                  await widget.game.gameLoop.upgradeSpell(index, upgradePath);
                  _onGameStateChanged();
                },
                onLeave: () {
                  if (widget.game.gameState.nodeInteractionCompleted) {
                    if (_currentRoomConfig != null) {
                      _currentRoomConfig = _currentRoomConfig!
                          .withInteractionCompleted();
                    }
                    widget.game.gameLoop.leaveCurrentNode();
                  } else {
                    widget.game.gameLoop.skipEnhancement();
                  }
                  _onGameStateChanged();
                },
              ),
            ),

          // Overlay: Spell Shrine
          if (widget.game.currentScreen == GameScreen.spellLearn &&
              widget.game.gameState.spellChoices != null)
            Container(
              color: Colors.black54,
              child: SpellShrineOverlay(
                spellChoices: widget.game.gameState.spellChoices!,
                mage: widget.game.gameState.mage!,
                isActionCompleted:
                    widget.game.gameState.nodeInteractionCompleted,
                onLearn: (choiceIndex) {
                  widget.game.gameLoop.learnSpell(choiceIndex);
                  _onGameStateChanged();
                },
                onReplace: (loadoutIndex, newSpell) {
                  widget.game.gameLoop.replaceSpell(loadoutIndex, newSpell);
                  _onGameStateChanged();
                },
                onSkip: () {
                  if (widget.game.gameState.nodeInteractionCompleted) {
                    if (_currentRoomConfig != null) {
                      _currentRoomConfig = _currentRoomConfig!
                          .withInteractionCompleted();
                    }
                    widget.game.gameLoop.leaveCurrentNode();
                  } else {
                    widget.game.gameLoop.skipSpellLearn();
                  }
                  _onGameStateChanged();
                },
              ),
            ),

          // Overlay: Shop
          if (widget.game.currentScreen == GameScreen.shop &&
              widget.game.gameState.currentShop != null)
            Container(
              color: Colors.black54,
              child: ShopOverlay(
                shop: widget.game.gameState.currentShop!,
                currentFragments: widget.game.progressionSystem.spellFragments,
                onPurchase: (index) async {
                  await widget.game.gameLoop.purchaseShopItem(index);
                  _onGameStateChanged();
                },
                onLeave: () {
                  // Shop is a bit special, usually we just leave.
                  // If we want it to disappear, we mark it completed.
                  // Assuming leaving the shop constitutes "completing" the interaction for the purpose of removing it.
                  if (_currentRoomConfig != null) {
                    _currentRoomConfig = _currentRoomConfig!
                        .withInteractionCompleted();
                  }
                  widget.game.gameLoop.leaveShop();
                  _onGameStateChanged();
                },
              ),
            ),

          // Overlay: Elite Reward
          if (widget.game.currentScreen == GameScreen.eliteReward)
            if (widget.game.gameState.currentRewardResult != null)
              Container(
                color: Colors.black54,
                child: EliteRewardOverlay(
                  rewardResult: widget.game.gameState.currentRewardResult,
                  currentHP: widget.game.gameState.mage?.currentHP ?? 0,
                  maxHP: widget.game.gameState.mage?.maxHP ?? 100,
                  onComplete: (spell) {
                    widget.game.gameLoop.completeEliteReward(spell);
                    _onGameStateChanged();
                  },
                ),
              )
            else if (widget.game.gameState.currentEliteRewards != null)
              Container(
                color: Colors.black54,
                child: EliteRewardOverlay(
                  rewards:
                      widget.game.gameState.currentEliteRewards!['rewards']
                          as List,
                  onSelect: (index) {
                    widget.game.gameLoop.selectEliteReward(index);
                    _onGameStateChanged();
                  },
                ),
              ),

          // Overlay: Random Event
          if (widget.game.currentScreen == GameScreen.randomEvent &&
              widget.game.gameState.currentRandomEvent != null)
            Container(
              color: Colors.black87,
              child: RandomEventOverlay(
                event: widget.game.gameState.currentRandomEvent!,
                onChoice: (key) {
                  widget.game.gameLoop.handleRandomEventChoice(key);
                  _onGameStateChanged();
                },
              ),
            ),
        ],
      );
    }

    // Show battle screen during combat
    if (_isInBattleMode &&
        widget.game.gameState.currentCombat != null &&
        widget.game.gameState.mage != null) {
      return BattleScreen(
        combat: widget.game.gameState.currentCombat!,
        mage: widget.game.gameState.mage!,
        enemies: widget.game.gameState.currentCombat!.enemies,
        nodeMapSystem: widget.game.gameState.nodeMapSystem,
        journeyLog: _journeyLog,
        currentDepth: widget.game.gameState.currentDepth,
        totalDepths: widget.game.gameState.nodeMapSystem.totalDepths,
        temporaryBuffs: widget.game.gameState.temporaryBuffs,
        runNumber: 1,
        onCombatEnd: () {
          widget.game.gameLoop.handleCombatEnd();
          _onGameStateChanged();
        },
        onRetreat: () {
          widget.game.gameState.endRun(victory: false);
          _onGameStateChanged();
        },
        onInput: (input) => widget.game.handleInput(input),
        gameLoop: widget.game.gameLoop,
      );
    }

    // Main Menu
    if (widget.game.currentScreen == GameScreen.mainMenu) {
      return MainMenuOverlay(
        totalRuns: widget.game.progressionSystem.totalRuns,
        bestDepth: widget.game.progressionSystem.bestNodeReached,
        totalFragments: widget.game.progressionSystem.spellFragments,
        totalCrystals: widget.game.progressionSystem.spellCrystals,
        lastRunElement: widget.game.progressionSystem.lastRunElement,
        progressionSystem: widget.game.progressionSystem, // Phase 7.7
        // Phase 7.9.3: Save resume support
        hasSavedRun: widget.game.gameState.hasSavedRun,
        onContinue: () async {
          final success = await widget.game.gameState.restoreFromSave();
          if (success) {
            _onGameStateChanged();
          }
        },
        onDiscard: () async {
          await widget.game.gameState.discardSave();
          _onGameStateChanged();
        },
        onNewGame: () {
          widget.game.handleInput('N');
          _onGameStateChanged();
        },
      );
    }

    // Game Over / Run End
    if (widget.game.currentScreen == GameScreen.runEnd) {
      final isVictory = widget.game.gameState.mage?.isAlive ?? false;

      return GameOverOverlay(
        isVictory: isVictory,
        depthReached: widget.game.gameState.currentDepth,
        totalDepths: widget.game.gameState.nodeMapSystem.totalDepths,
        fragmentsCollected: widget.game.progressionSystem.spellFragments,
        turnsTaken: 0,
        onRestart: () {
          widget.game.handleInput('N');
          _onGameStateChanged();
        },
        onMainMenu: () {
          widget.game.handleInput('M');
          _onGameStateChanged();
        },
      );
    }

    // Fallback Container
    return const SizedBox.shrink();
  }

  void _handleBackPress(bool didPop) {
    if (didPop) return;

    final gameState = widget.game.gameState;
    final screen = gameState.currentScreen;

    // Case: Main Menu -> Exit Game
    if (screen == GameScreen.mainMenu) {
      _showExitGameDialog();
      return;
    }

    // Case: Element Selection -> Return to Main Menu
    if (screen == GameScreen.elementSelect) {
      widget.game.gameState.returnToMainMenu();
      _onGameStateChanged();
      return;
    }

    // Case: Target Selection -> Cancel to Combat
    if (screen == GameScreen.targetSelect) {
      widget.game.gameState.cancelTargetSelection();
      _onGameStateChanged();
      return;
    }

    // Case: Run End -> Return to Main Menu
    if (screen == GameScreen.runEnd) {
      widget.game.handleInput('M');
      _onGameStateChanged();
      return;
    }

    // Case: Overlay screens -> Return to Exploration
    // These screens are on top of exploration, so back should close them
    if (screen == GameScreen.rest) {
      if (gameState.nodeInteractionCompleted) {
        widget.game.gameLoop.leaveCurrentNode();
      } else {
        widget.game.gameLoop.skipRest();
      }
      _onGameStateChanged();
      return;
    }

    if (screen == GameScreen.enhancementShrine) {
      if (gameState.nodeInteractionCompleted) {
        if (_currentRoomConfig != null) {
          _currentRoomConfig = _currentRoomConfig!.withInteractionCompleted();
        }
        widget.game.gameLoop.leaveCurrentNode();
      } else {
        widget.game.gameLoop.skipEnhancement();
      }
      _onGameStateChanged();
      return;
    }

    if (screen == GameScreen.spellLearn) {
      if (gameState.nodeInteractionCompleted) {
        if (_currentRoomConfig != null) {
          _currentRoomConfig = _currentRoomConfig!.withInteractionCompleted();
        }
        widget.game.gameLoop.leaveCurrentNode();
      } else {
        widget.game.gameLoop.skipSpellLearn();
      }
      _onGameStateChanged();
      return;
    }

    if (screen == GameScreen.shop) {
      if (_currentRoomConfig != null) {
        _currentRoomConfig = _currentRoomConfig!.withInteractionCompleted();
      }
      widget.game.gameLoop.leaveShop();
      _onGameStateChanged();
      return;
    }

    // Case: Exploration (home during run) or Combat -> Show Pause Menu
    // Elite Reward and Random Event cannot be exited via back (must complete)
    _showPauseMenu();
  }

  Future<void> _showPauseMenu() async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF161b22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade800),
        ),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PAUSED',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 32),

              // Resume
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    'RESUME',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Settings
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close pause menu
                    showDialog(
                      context: context,
                      builder: (context) => SettingsOverlay(
                        progressionSystem: widget.game.progressionSystem,
                        onReset: () {
                          // If reset happens, we should probably exit to main menu or reload
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                          widget.game.handleInput(
                            'M',
                          ); // Force return to main menu
                          _onGameStateChanged();
                        },
                      ),
                    ).then((_) {
                      // Re-open pause menu after settings closes?
                      // Or just let them be back in game.
                      // Standard behavior is back to game usually, or back to pause.
                      // Let's go back to pause menu for better UX.
                      _showPauseMenu();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade700),
                  ),
                  child: const Text(
                    'SETTINGS',
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Abandon
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showAbandonRunDialog();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  child: const Text(
                    'ABANDON RUN',
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAbandonRunDialog() async {
    final shouldAbandon = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161b22),
        title: const Text(
          'Abandon Run?',
          style: TextStyle(
            fontFamily: 'monospace',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Your current run progress will be lost. Are you sure?',
          style: TextStyle(fontFamily: 'monospace', color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'CONTINUE',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'ABANDON',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldAbandon == true) {
      // Clear save and return to main menu
      await widget.game.gameState.discardSave();
      widget.game.gameState.returnToMainMenu();
      _onGameStateChanged();
    }
  }

  Future<void> _showExitGameDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161b22),
        title: const Text(
          'Exit Game',
          style: TextStyle(
            fontFamily: 'monospace',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to exit?',
          style: TextStyle(fontFamily: 'monospace', color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'CANCEL',
              style: TextStyle(fontFamily: 'monospace', color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'EXIT',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  Widget _buildExplorationScreen() {
    final gameState = widget.game.gameState;
    final mage = gameState.mage!;

    // Get or create room configuration
    if (_currentRoomConfig == null) {
      final currentNode = gameState.nodeMapSystem.currentNode;
      final enemy = gameState.currentEnemies?.isNotEmpty == true
          ? gameState.currentEnemies!.first
          : null;
      final isElite = gameState.isEliteCombat;

      // Get next node choices for doors
      List<MapNode> nextNodes = <MapNode>[];
      if (currentNode != null) {
        // We are in a node (interaction finished but not left), peek ahead
        // NodeMapSystem is 0-indexed internally, currentDepth is 1-indexed getter
        // currentDepthIndex gives 0-based index.
        final nextDepthIndex = gameState.nodeMapSystem.currentDepthIndex + 1;
        final nextDepth = gameState.nodeMapSystem.getDepthAt(nextDepthIndex);
        nextNodes = nextDepth?.nodeChoices ?? <MapNode>[];
      } else {
        // We are between nodes, current level choices are for the upcoming rooms
        nextNodes =
            gameState.nodeMapSystem.currentDepthLevel?.nodeChoices ??
            <MapNode>[];
      }

      // Determine room title based on node type
      String roomTitle;
      if (currentNode == null && gameState.currentDepth <= 1) {
        roomTitle = 'The Threshold'; // Starting room
      } else if (currentNode != null) {
        // Use node type for title
        switch (currentNode.type) {
          case NodeType.combat:
            roomTitle = 'Combat Room';
            break;
          case NodeType.elite:
            roomTitle = '⚠️ Elite Encounter';
            break;
          case NodeType.shop:
            roomTitle = '🏪 Merchant\'s Stall';
            break;
          case NodeType.enhancementShrine:
            roomTitle = '✨ Enhancement Shrine';
            break;
          case NodeType.spellLearn:
            roomTitle = '📚 Spell Shrine';
            break;
          case NodeType.rest:
            roomTitle = '🔥 Rest Site';
            break;
          case NodeType.randomEvent:
            roomTitle = '❓ Mysterious Event';
            break;
          default:
            roomTitle = currentNode.type.displayName;
        }
      } else {
        roomTitle = 'Choose Your Path'; // Fallback
      }

      // Determine distinct room ID
      String roomId;
      if (currentNode == null) {
        roomId = 'start_room_${gameState.currentDepth}';
      } else {
        roomId = 'node_${currentNode.depth}_${currentNode.pathIndex}';
      }

      _currentRoomConfig = RoomConfiguration(
        roomId: roomId,
        title: roomTitle,
        enemy: enemy,
        isEliteEnemy: isElite,
        doors: nextNodes.isEmpty
            ? [
                DoorConfig(
                  direction: DoorDirection.north,
                  destinationId: 'choice_0',
                  destinationType: 'unknown',
                  state: DoorState.available,
                ),
              ]
            : nextNodes.asMap().entries.map((e) {
                final directions = [
                  DoorDirection.north,
                  DoorDirection.east,
                  DoorDirection.west,
                ];
                return DoorConfig(
                  direction: directions[e.key % directions.length],
                  // Use e.key (choice index) so selectNodeChoice works
                  destinationId: 'choice_${e.key}',
                  destinationType: e.value.type.toString().split('.').last,
                  state: DoorState.available,
                  label: e.value.type.displayName,
                );
              }).toList(),
        nodeType: currentNode?.type,
        // Respect the interaction completed state from gameState
        interactionCompleted: gameState.nodeInteractionCompleted,
        // Check if enemy was already defeated (no living enemies)
        enemyDefeated: enemy != null && !enemy.isAlive,
      );
    }

    return ExplorationScreenV2(
      roomConfig: _currentRoomConfig!,
      mage: mage,
      nodeMapSystem: gameState.nodeMapSystem,
      currentDepth: gameState.currentDepth,
      totalDepths: gameState.nodeMapSystem.totalDepths,
      temporaryBuffs: gameState.temporaryBuffs,
      characterProgress: widget.game.progressionSystem.characterProgress,
      inventory: gameState.inventory,
      runNumber: 1,
      onEngageEnemy: (enemy, isElite) async {
        // Phase 7.7: Check if we should show narrative dialogue
        final currentNode = gameState.nodeMapSystem.currentNode;
        final isBoss = currentNode?.type == NodeType.bossCombat;

        if (isBoss) {
          // Show boss pre-fight narrative
          _showBossNarrative(context, gameState, enemy);
        } else if (isElite) {
          // Check if we should show elite dialogue
          await _showEliteDialogue(context, gameState, enemy);
        } else {
          // Regular combat - start directly
          gameState.startCombatDirectly([enemy], isElite: false);
          _onGameStateChanged();
        }
      },
      onTravel: (direction, destinationId) async {
        // Sound already played when door was tapped (preview shown)
        // Don't play again here to avoid double sound

        // Parse destination to get choice index
        // destinationId format: 'choice_X'
        final parts = destinationId.split('_');
        if (parts.length >= 2) {
          final choiceIndex = int.tryParse(parts[1]) ?? 0;
          // Select the node and enter it
          gameState.selectNodeChoice(choiceIndex);
        } else {
          // Fallback: just select first available
          gameState.selectNodeChoice(0);
        }
        _currentRoomConfig = null; // Reset for next room
        _onGameStateChanged();
      },
      onInteractableTapped: (nodeType) async {
        // Play interaction sound based on type
        // Note: Enhancement shrines and spell shrines play their sounds
        // when their overlays open, not here
        switch (nodeType) {
          case NodeType.enhancementShrine:
          case NodeType.spellLearn:
            // Sound plays when overlay opens (in initState)
            break;
          default:
            await AudioManager.instance.playSfxAndWait(
              AudioManager.sfxBaseSelect,
            );
        }

        // Open the non-combat screen (shop, shrine, etc.)
        gameState.openNonCombatScreen(nodeType);
        _onGameStateChanged();
      },
      onEnemyDefeated: () {
        // Mark room as cleared
        if (_currentRoomConfig != null) {
          _currentRoomConfig = _currentRoomConfig!.withEnemyDefeated();
        }
        _onGameStateChanged();
      },
    );
  }

  // ==================== PHASE 7.7: NARRATIVE HELPERS ====================

  /// Shows elite dialogue if not already shown this run, then starts combat.
  Future<void> _showEliteDialogue(
    BuildContext context,
    GameState gameState,
    dynamic enemy,
  ) async {
    final eliteName = enemy.name as String;

    // Check if we should show dialogue
    if (gameState.shouldShowEliteDialogue(eliteName)) {
      final dialogue = EliteDialogue.getDialogueForElite(
        eliteName: eliteName,
        onComplete: () {
          gameState.markEliteDialogueShown(eliteName);
        },
      );

      if (dialogue != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => NarrativeOverlay(
            narrativeNode: dialogue,
            onComplete: () {
              Navigator.of(context).pop();
              // Start combat after dialogue
              gameState.startCombatDirectly([enemy], isElite: true);
              _onGameStateChanged();
            },
            showFadeIn: true,
          ),
        );
        return; // Exit early - combat will start after dialogue
      }
    }

    // No dialogue or already shown - start combat directly
    gameState.startCombatDirectly([enemy], isElite: true);
    _onGameStateChanged();
  }

  /// Shows boss narrative sequence, then starts combat.
  void _showBossNarrative(
    BuildContext context,
    GameState gameState,
    dynamic enemy,
  ) {
    final bossName = enemy.name as String;

    // Step 1: Show shared pre-fight narrative
    final preFightNode = BossNarrative.getPreFightNarrative(onComplete: () {});

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NarrativeOverlay(
        narrativeNode: preFightNode,
        onComplete: () {
          Navigator.of(context).pop();
          // Step 2: Show boss-specific dialogue
          _showBossSpecificDialogue(context, gameState, enemy, bossName);
        },
        showFadeIn: true,
      ),
    );
  }

  /// Shows boss-specific dialogue, then starts combat.
  Future<void> _showBossSpecificDialogue(
    BuildContext context,
    GameState gameState,
    dynamic enemy,
    String bossName,
  ) async {
    final bossDialogue = BossNarrative.getBossSpecificNarrative(
      bossName: bossName,
      onComplete: () {},
    );

    if (bossDialogue != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => NarrativeOverlay(
          narrativeNode: bossDialogue,
          onComplete: () {
            Navigator.of(context).pop();
            // Start boss combat
            gameState.startCombatDirectly([enemy], isElite: false);
            _onGameStateChanged();
          },
          showFadeIn: true,
        ),
      );
    } else {
      // No boss-specific dialogue - start combat
      gameState.startCombatDirectly([enemy], isElite: false);
      _onGameStateChanged();
    }
  }
}
