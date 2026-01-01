import 'package:flutter/material.dart';

import '../game/spellforge_game.dart';
import '../game/game_state.dart';
import '../game/exploration/exploration_controller.dart';
import '../game/exploration/components/door_interactable.dart';
import '../nodes/nodes.dart';
import '../narrative/journey_log.dart';
import 'battle/battle.dart';
import 'exploration/exploration_screen_v2.dart';
import 'spell_selection_screen.dart';
import 'exploration/overlays/rest_overlay.dart';
import 'exploration/overlays/enhancement_shrine_overlay.dart';
import 'exploration/overlays/spell_shrine_overlay.dart';
import 'exploration/overlays/shop_overlay.dart';
import 'exploration/overlays/elite_reward_overlay.dart';
import 'exploration/overlays/random_event_overlay.dart';
import 'exploration/overlays/game_over_overlay.dart';
import 'exploration/overlays/main_menu_overlay.dart';

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
    // Show spell selection screen
    if (widget.game.gameState.currentScreen == GameScreen.spellSelect &&
        widget.game.gameState.spellChoices != null) {
      return SpellSelectionScreen(
        spellChoices: widget.game.gameState.spellChoices!,
        onSpellSelected: (spell) {
          widget.game.gameState.selectStartingSpell(spell);
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
                onUpgrade: (index) async {
                  await widget.game.gameLoop.upgradeSpell(index);
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
          if (widget.game.currentScreen == GameScreen.eliteReward &&
              widget.game.gameState.currentEliteRewards != null)
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
      );
    }

    // Main Menu
    if (widget.game.currentScreen == GameScreen.mainMenu) {
      return MainMenuOverlay(
        totalRuns: widget.game.progressionSystem.totalRuns,
        bestDepth: widget.game.progressionSystem.bestNodeReached,
        totalFragments: widget.game.progressionSystem.spellFragments,
        totalCrystals: widget.game.progressionSystem.spellCrystals,
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
      final nextNodes =
          gameState.nodeMapSystem.currentDepthLevel?.nodeChoices ?? [];

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
                  destinationType: e.value.type.name,
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
      runNumber: 1,
      onEngageEnemy: (enemy, isElite) {
        // Start combat using the new direct method
        gameState.startCombatDirectly([enemy], isElite: isElite);
        _onGameStateChanged();
      },
      onTravel: (direction, destinationId) {
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
      onInteractableTapped: (nodeType) {
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
}
