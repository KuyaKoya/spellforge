import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/spellforge_game.dart';
import '../game/game_state.dart';
import '../nodes/nodes.dart';
import '../narrative/narrative.dart';
import 'components/components.dart';

/// Enhanced text-based UI renderer for Act 1 Demo (Phase 5).
/// Includes breadcrumbs, journey log panel, and narrative overlay.
class Act1TextGameWidget extends StatefulWidget {
  final SpellforgeGame game;
  final JourneyLog journeyLog;
  final int runNumber;

  const Act1TextGameWidget({
    super.key,
    required this.game,
    required this.journeyLog,
    this.runNumber = 1,
  });

  @override
  State<Act1TextGameWidget> createState() => _Act1TextGameWidgetState();
}

class _Act1TextGameWidgetState extends State<Act1TextGameWidget> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // UI state
  bool _showJourneyLog = false;
  bool _combatLogExpanded = false;
  NarrativeBlock? _currentNarrative;

  // Combat log entries
  final List<CombatLogEntry> _combatLogEntries = [];

  @override
  void initState() {
    super.initState();
    widget.game.onStateChanged = _onGameStateChanged;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    widget.game.onStateChanged = null;
    super.dispose();
  }

  void _onGameStateChanged() {
    setState(() {});

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      // Journey log toggle (J key) - LOCKED: Pause menu only, NOT during combat
      if (key == LogicalKeyboardKey.keyJ && !_isInCombat) {
        setState(() => _showJourneyLog = !_showJourneyLog);
        return;
      }

      // ESC to access pause / toggle journey log in pause
      if (key == LogicalKeyboardKey.escape) {
        if (_showJourneyLog) {
          setState(() => _showJourneyLog = false);
        } else if (!_isInCombat) {
          setState(() => _showJourneyLog = !_showJourneyLog);
        }
        return;
      }

      // Dismiss narrative on any key
      if (_currentNarrative != null) {
        setState(() => _currentNarrative = null);
        return;
      }

      String? input;

      if (key == LogicalKeyboardKey.digit1 ||
          key == LogicalKeyboardKey.numpad1) {
        input = '1';
      } else if (key == LogicalKeyboardKey.digit2 ||
          key == LogicalKeyboardKey.numpad2) {
        input = '2';
      } else if (key == LogicalKeyboardKey.digit3 ||
          key == LogicalKeyboardKey.numpad3) {
        input = '3';
      } else if (key == LogicalKeyboardKey.digit4 ||
          key == LogicalKeyboardKey.numpad4) {
        input = '4';
      } else if (key == LogicalKeyboardKey.keyN) {
        input = 'N';
      } else if (key == LogicalKeyboardKey.keyE) {
        input = 'E';
      } else if (key == LogicalKeyboardKey.keyS) {
        input = 'S';
      } else if (key == LogicalKeyboardKey.keyR) {
        input = 'R';
      } else if (key == LogicalKeyboardKey.keyM) {
        input = 'M';
      } else if (key == LogicalKeyboardKey.keyC) {
        input = 'C';
      } else if (key == LogicalKeyboardKey.keyQ) {
        input = 'Q';
      } else if (key == LogicalKeyboardKey.keyY) {
        input = 'Y';
      } else if (key == LogicalKeyboardKey.keyL) {
        input = 'L';
      } else if (key == LogicalKeyboardKey.keyB) {
        input = 'B';
      }

      if (input != null) {
        widget.game.handleInput(input);
      }
    }
  }

  /// Shows a narrative overlay.
  void showNarrative(NarrativeBlock narrative) {
    setState(() => _currentNarrative = narrative);
  }

  /// Dismisses the current narrative overlay.
  void dismissNarrative() {
    setState(() => _currentNarrative = null);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyPress,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Container(
          // LOCKED: Dark background matching breadcrumb specs
          color: const Color(0xFF0d1117),
          child: SafeArea(
            child: Stack(
              children: [
                // Main content
                Row(
                  children: [
                    // Main game area
                    Expanded(
                      child: Column(
                        children: [
                          _buildHeader(),
                          if (_isInRun) _buildBreadcrumbs(),
                          Expanded(child: _buildLogDisplay()),
                          if (_isInCombat) _buildCombatLog(),
                          _buildActionBar(),
                        ],
                      ),
                    ),

                    // Journey log side panel
                    // LOCKED: Only accessible non-combat (left-edge swipe option)
                    if (_showJourneyLog && !_isInCombat)
                      JourneyLogPanel(
                        journeyLog: widget.journeyLog,
                        onClose: () => setState(() => _showJourneyLog = false),
                      ),
                  ],
                ),

                // Narrative overlay
                if (_currentNarrative != null)
                  NarrativeOverlay(
                    narrative: _currentNarrative!,
                    onDismiss: dismissNarrative,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _isInRun =>
      widget.game.gameState.mage != null &&
      widget.game.currentScreen != GameScreen.mainMenu;

  bool get _isInCombat =>
      widget.game.currentScreen == GameScreen.combat ||
      widget.game.currentScreen == GameScreen.targetSelect;

  Widget _buildBreadcrumbs() {
    return NodeBreadcrumbs(
      nodeMapSystem: widget.game.gameState.nodeMapSystem,
      currentDepth: widget.game.gameState.currentDepth,
      totalDepths: widget.game.gameState.nodeMapSystem.totalDepths,
      runNumber: widget.runNumber,
    );
  }

  Widget _buildCombatLog() {
    return CombatLogPanel(
      entries: _combatLogEntries,
      isExpanded: _combatLogExpanded,
      onToggle: () => setState(() => _combatLogExpanded = !_combatLogExpanded),
    );
  }

  Widget _buildHeader() {
    if (!widget.game.isReady) {
      return const SizedBox.shrink();
    }

    final screen = widget.game.currentScreen;
    final mage = widget.game.gameState.mage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF16213e),
        border: Border(bottom: BorderSide(color: Color(0xFF0f3460), width: 2)),
      ),
      child: Row(
        children: [
          // Logo with Act indicator
          Row(
            children: [
              Image.asset(
                'assets/spellforge_logo.png',
                height: 36,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(width: 12),
              Text(
                'ACT I',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Status
          if (mage != null) ...[
            _buildStatusChip('Lv.${mage.level}', Colors.purple.shade400),
            const SizedBox(width: 8),
            _buildStatusChip(mage.hpDisplay, Colors.red.shade400),
            const SizedBox(width: 8),
            _buildStatusChip(mage.manaDisplay, Colors.blue.shade400),
            const SizedBox(width: 8),
            _buildStatusChip(
              'Depth ${widget.game.gameState.currentDepth}/${widget.game.gameState.nodeMapSystem.totalDepths}',
              Colors.green.shade400,
            ),
            const SizedBox(width: 8),
            _buildStatusChip(
              '💎 ${widget.game.progressionSystem.spellFragments}',
              Colors.teal.shade400,
            ),
          ],

          const SizedBox(width: 16),

          // Journey log toggle - LOCKED: Only accessible non-combat
          if (!_isInCombat)
            GestureDetector(
              onTap: () => setState(() => _showJourneyLog = !_showJourneyLog),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _showJourneyLog
                      ? const Color(0xFF21262d)
                      : Colors.transparent,
                  border: Border.all(color: const Color(0xFF30363d)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'J',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: _showJourneyLog
                        ? Colors.grey.shade300
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),

          const SizedBox(width: 8),

          // Screen indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getScreenColor(screen),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getScreenName(screen),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: color),
      ),
    );
  }

  Widget _buildLogDisplay() {
    if (!widget.game.isReady) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.amber),
      );
    }

    final logs = widget.game.textLog;

    if (logs.isEmpty) {
      return _buildWelcomeScreen();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        return _buildLogLine(logs[index]);
      },
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Image.asset(
            'assets/spellforge_logo.png',
            height: 120,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 24),
          Text(
            'ACT I: THE THRESHOLD',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              color: Colors.grey.shade500,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A roguelike of loops and persistence',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 13,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF30363d)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Press [N] to enter the Threshold',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildResourceDisplay(),
        ],
      ),
    );
  }

  Widget _buildResourceDisplay() {
    if (!widget.game.isReady) return const SizedBox.shrink();

    final progression = widget.game.progressionSystem;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'PERSISTENT ECHOES',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.grey.shade500,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildResourceItem(
                '💎',
                '${progression.spellFragments}',
                'Fragments',
              ),
              const SizedBox(width: 24),
              _buildResourceItem(
                '✨',
                '${progression.spellCrystals}',
                'Crystals',
              ),
              const SizedBox(width: 24),
              _buildResourceItem('🔄', '${progression.totalRuns}', 'Loops'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourceItem(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildLogLine(String line) {
    Color color = Colors.grey.shade300;
    FontWeight weight = FontWeight.normal;
    FontStyle fontStyle = FontStyle.normal;

    // Director lines (purple, italic)
    if (line.startsWith('"') && line.endsWith('"')) {
      color = Colors.purple.shade300;
      fontStyle = FontStyle.italic;
    }
    // Style based on content
    else if (line.startsWith('===') ||
        line.startsWith('╔') ||
        line.startsWith('║') ||
        line.startsWith('╚')) {
      color = Colors.amber.shade400;
      weight = FontWeight.bold;
    } else if (line.startsWith('---') ||
        line.startsWith('───') ||
        line.startsWith('┌') ||
        line.startsWith('└') ||
        line.startsWith('│')) {
      color = Colors.grey.shade400;
    } else if (line.contains('VICTORY')) {
      color = Colors.green.shade400;
      weight = FontWeight.bold;
    } else if (line.contains('DEFEAT') || line.contains('fallen')) {
      color = Colors.red.shade400;
      weight = FontWeight.bold;
    } else if (line.contains('GATEKEEPER') || line.contains('👹')) {
      color = Colors.orange.shade300;
      weight = FontWeight.bold;
    } else if (line.contains('ELITE') || line.contains('💀')) {
      color = Colors.purple.shade300;
      weight = FontWeight.bold;
    } else if (line.contains('⚠️') || line.contains('WARNING')) {
      color = Colors.orange.shade400;
    } else if (line.contains('Damage:')) {
      color = Colors.orange.shade400;
    } else if (line.contains('Strong effectiveness') || line.contains('✅')) {
      color = Colors.green.shade400;
    } else if (line.contains('Weak effectiveness') || line.contains('❌')) {
      color = Colors.red.shade400;
    } else if (line.startsWith('[')) {
      color = Colors.cyan.shade400;
    } else if (line.contains('★')) {
      color = Colors.yellow.shade400;
    } else if (line.contains('applied') ||
        line.contains('Burn') ||
        line.contains('Slow')) {
      color = Colors.purple.shade300;
    } else if (line.contains('fragments') ||
        line.contains('Earned') ||
        line.contains('💎')) {
      color = Colors.teal.shade400;
    } else if (line.contains('✨') || line.contains('Crystal')) {
      color = Colors.cyan.shade300;
    } else if (line.contains('📖') || line.contains('Learned')) {
      color = Colors.blue.shade400;
    } else if (line.contains('🏆') || line.contains('REWARD')) {
      color = Colors.amber.shade300;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        line,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: color,
          fontWeight: weight,
          fontStyle: fontStyle,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    if (!widget.game.isReady) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF16213e),
        border: Border(top: BorderSide(color: Color(0xFF0f3460), width: 2)),
      ),
      child: _buildActionButtons(),
    );
  }

  Widget _buildActionButtons() {
    final screen = widget.game.currentScreen;

    switch (screen) {
      case GameScreen.mainMenu:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_buildButton('N', 'Enter the Threshold', Colors.amber)],
        );

      case GameScreen.mageSelect:
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildButton('1', 'Pyromancer', Colors.red),
              _buildButton('2', 'Hydromancer', Colors.blue),
              _buildButton('3', 'Geomancer', Colors.brown),
              _buildButton('4', 'Aeromancer', Colors.cyan),
            ],
          ),
        );

      case GameScreen.nodeMap:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_buildButton('E', 'Proceed', Colors.green)],
        );

      case GameScreen.nodeChoice:
        final depth = widget.game.gameState.nodeMapSystem.currentDepthLevel;
        if (depth != null) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...depth.nodeChoices.asMap().entries.map((e) {
                  Color color = Colors.blue;
                  if (e.value.type.isCombat) color = Colors.red;
                  if (e.value.type == NodeType.elite) color = Colors.purple;
                  if (e.value.type == NodeType.shop) color = Colors.green;
                  if (e.value.type == NodeType.rest) color = Colors.teal;
                  if (e.value.type == NodeType.bossCombat) {
                    color = Colors.orange;
                  }
                  return _buildButton(
                    '${e.key + 1}',
                    e.value.type.displayName,
                    color,
                  );
                }),
              ],
            ),
          );
        }
        return const SizedBox.shrink();

      case GameScreen.exploration:
        return const SizedBox.shrink(); // Handled by ExplorationScreen

      case GameScreen.combat:
        final mage = widget.game.gameState.mage;
        if (mage == null) return const SizedBox.shrink();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...mage.spellLoadout.asMap().entries.map((e) {
                final canCast = mage.canCast(e.value);
                return SpellInspectionWrapper(
                  spell: e.value,
                  enabled: true,
                  child: _buildButton(
                    '${e.key + 1}',
                    e.value.name,
                    canCast ? Colors.blue : Colors.grey,
                    enabled: canCast,
                  ),
                );
              }),
              _buildButton('E', 'End Turn', Colors.orange),
            ],
          ),
        );

      case GameScreen.targetSelect:
        final enemies =
            widget.game.gameState.currentCombat?.livingEnemies ?? [];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...enemies.asMap().entries.map((e) {
                return _buildButton(
                  '${e.key + 1}',
                  '${e.value.name} (${e.value.hpDisplay})',
                  Colors.red,
                );
              }),
              _buildButton('C', 'Cancel', Colors.grey),
            ],
          ),
        );

      case GameScreen.spellLearn:
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildButton('1', 'Option 1', Colors.blue),
              _buildButton('2', 'Option 2', Colors.blue),
              _buildButton('3', 'Option 3', Colors.blue),
              _buildButton('S', 'Skip', Colors.grey),
            ],
          ),
        );

      case GameScreen.enhancementShrine:
        final mage = widget.game.gameState.mage;
        if (mage == null) return const SizedBox.shrink();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...mage.spellLoadout.asMap().entries.map((e) {
                final canUpgrade = e.value.starLevel < 3;
                return _buildButton(
                  '${e.key + 1}',
                  'Upgrade ${e.value.name}',
                  canUpgrade ? Colors.amber : Colors.grey,
                  enabled: canUpgrade,
                );
              }),
              _buildButton('S', 'Skip', Colors.grey),
            ],
          ),
        );

      case GameScreen.shop:
        final items = widget.game.gameState.currentShop?.availableItems ?? [];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...items.asMap().entries.map((e) {
                final canAfford =
                    widget.game.progressionSystem.spellFragments >=
                    e.value.cost;
                return _buildButton(
                  '${e.key + 1}',
                  e.value.type.displayName,
                  canAfford ? Colors.green : Colors.grey,
                  enabled: canAfford,
                );
              }),
              _buildButton('L', 'Leave', Colors.grey),
            ],
          ),
        );

      case GameScreen.rest:
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildButton('R', 'Rest', Colors.green),
              _buildButton('M', 'Remove Mod', Colors.orange),
              _buildButton('B', 'Temp Buff', Colors.purple),
              _buildButton('S', 'Skip', Colors.grey),
            ],
          ),
        );

      case GameScreen.elite:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildButton('Y', 'Fight!', Colors.red),
            _buildButton('N', 'Retreat', Colors.grey),
          ],
        );

      case GameScreen.eliteReward:
        final rewards =
            widget.game.gameState.currentEliteRewards?['rewards'] as List? ??
            [];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: rewards.asMap().entries.map((e) {
              return _buildButton(
                '${e.key + 1}',
                (e.value as Map)['name'],
                Colors.amber,
              );
            }).toList(),
          ),
        );

      case GameScreen.randomEvent:
        final event = widget.game.gameState.currentRandomEvent;
        if (event != null) {
          final choices = event['choices'] as List;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: choices.map((c) {
                return _buildButton(
                  c['key'].toString(),
                  c['text'].toString().split('(').first.trim(),
                  Colors.purple,
                );
              }).toList(),
            ),
          );
        }
        return const SizedBox.shrink();

      case GameScreen.spellSelect:
        return const SizedBox.shrink();

      case GameScreen.runEnd:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_buildButton('M', 'Return to the Loop', Colors.amber)],
        );
    }
  }

  Widget _buildButton(
    String key,
    String label,
    Color color, {
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: enabled ? () => widget.game.handleInput(key) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: enabled
                ? color.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.1),
            border: Border.all(
              color: enabled ? color : Colors.grey.shade700,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: enabled ? color : Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  key,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: enabled ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScreenColor(GameScreen screen) {
    switch (screen) {
      case GameScreen.mainMenu:
        return Colors.grey.shade700;
      case GameScreen.mageSelect:
        return Colors.purple;
      case GameScreen.nodeMap:
        return Colors.green;
      case GameScreen.nodeChoice:
        return Colors.blue;
      case GameScreen.exploration:
        return Colors.indigo;
      case GameScreen.combat:
        return Colors.red;
      case GameScreen.targetSelect:
        return Colors.orange;
      case GameScreen.spellLearn:
        return Colors.blue;
      case GameScreen.enhancementShrine:
        return Colors.amber;
      case GameScreen.shop:
        return Colors.green;
      case GameScreen.rest:
        return Colors.teal;
      case GameScreen.elite:
        return Colors.purple;
      case GameScreen.eliteReward:
        return Colors.amber;
      case GameScreen.randomEvent:
        return Colors.purple;
      case GameScreen.spellSelect:
        return Colors.purple;
      case GameScreen.runEnd:
        return Colors.orange;
    }
  }

  String _getScreenName(GameScreen screen) {
    switch (screen) {
      case GameScreen.mainMenu:
        return 'THRESHOLD';
      case GameScreen.mageSelect:
        return 'SELECT PATH';
      case GameScreen.nodeMap:
        return 'NODE MAP';
      case GameScreen.nodeChoice:
        return 'CHOOSE PATH';
      case GameScreen.exploration:
        return 'EXPLORATION';
      case GameScreen.combat:
        return 'COMBAT';
      case GameScreen.targetSelect:
        return 'SELECT TARGET';
      case GameScreen.spellLearn:
        return 'SPELL SHRINE';
      case GameScreen.enhancementShrine:
        return 'ENHANCE';
      case GameScreen.shop:
        return 'SHOP';
      case GameScreen.rest:
        return 'REST';
      case GameScreen.elite:
        return 'ELITE';
      case GameScreen.eliteReward:
        return 'REWARD';
      case GameScreen.randomEvent:
        return 'EVENT';
      case GameScreen.spellSelect:
        return 'SPELL SELECT';
      case GameScreen.runEnd:
        return 'LOOP END';
    }
  }
}
