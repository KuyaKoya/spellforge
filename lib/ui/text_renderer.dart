import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/spellforge_game.dart';
import '../game/game_state.dart';

/// A text-based UI renderer for the game.
/// Displays the game log and handles keyboard input.
class TextGameWidget extends StatefulWidget {
  final SpellforgeGame game;

  const TextGameWidget({super.key, required this.game});

  @override
  State<TextGameWidget> createState() => _TextGameWidgetState();
}

class _TextGameWidgetState extends State<TextGameWidget> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

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

      // Map key to input string
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
      }

      if (input != null) {
        widget.game.handleInput(input);
      }
    }
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
          color: const Color(0xFF1a1a2e),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildLogDisplay()),
                _buildActionBar(),
              ],
            ),
          ),
        ),
      ),
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
          // Title
          Text(
            'SPELLFORGE',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade400,
              letterSpacing: 4,
            ),
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
              'Node ${widget.game.gameState.nodeSystem.currentNodeIndex + 1}/${widget.game.gameState.nodeSystem.totalNodes}',
              Colors.green.shade400,
            ),
          ],

          const SizedBox(width: 16),

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
          Text(
            '⚡ SPELLFORGE ⚡',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade400,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'A Text-Based Roguelike',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              color: Colors.grey.shade400,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Press [N] to start a new run',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              color: Colors.green.shade400,
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
            'PERSISTENT RESOURCES',
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
              _buildResourceItem(
                '🏆',
                '${progression.bestNodeReached}',
                'Best Node',
              ),
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

    // Style based on content
    if (line.startsWith('===')) {
      color = Colors.amber.shade400;
      weight = FontWeight.bold;
    } else if (line.startsWith('---')) {
      color = Colors.grey.shade500;
    } else if (line.contains('VICTORY')) {
      color = Colors.green.shade400;
      weight = FontWeight.bold;
    } else if (line.contains('DEFEAT') || line.contains('fallen')) {
      color = Colors.red.shade400;
      weight = FontWeight.bold;
    } else if (line.contains('Damage:')) {
      color = Colors.orange.shade400;
    } else if (line.contains('Strong effectiveness')) {
      color = Colors.green.shade400;
    } else if (line.contains('Weak effectiveness')) {
      color = Colors.red.shade400;
    } else if (line.startsWith('[')) {
      color = Colors.cyan.shade400;
    } else if (line.contains('★')) {
      color = Colors.yellow.shade400;
    } else if (line.contains('applied') ||
        line.contains('Burn') ||
        line.contains('Slow')) {
      color = Colors.purple.shade300;
    } else if (line.contains('fragments') || line.contains('Earned')) {
      color = Colors.teal.shade400;
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
          children: [_buildButton('N', 'New Run', Colors.green)],
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
          children: [_buildButton('E', 'Enter Node', Colors.green)],
        );

      case GameScreen.combat:
        final mage = widget.game.gameState.mage;
        if (mage == null) return const SizedBox.shrink();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...mage.spellLoadout.asMap().entries.map((e) {
                final canCast = mage.canCast(e.value);
                return _buildButton(
                  '${e.key + 1}',
                  e.value.name,
                  canCast ? Colors.blue : Colors.grey,
                  enabled: canCast,
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

      case GameScreen.rest:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildButton('R', 'Rest', Colors.green),
            _buildButton('S', 'Skip', Colors.grey),
          ],
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

      case GameScreen.runEnd:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_buildButton('M', 'Main Menu', Colors.amber)],
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
      case GameScreen.combat:
        return Colors.red;
      case GameScreen.targetSelect:
        return Colors.orange;
      case GameScreen.spellLearn:
        return Colors.blue;
      case GameScreen.enhancementShrine:
        return Colors.amber;
      case GameScreen.rest:
        return Colors.teal;
      case GameScreen.randomEvent:
        return Colors.purple;
      case GameScreen.runEnd:
        return Colors.orange;
    }
  }

  String _getScreenName(GameScreen screen) {
    switch (screen) {
      case GameScreen.mainMenu:
        return 'MENU';
      case GameScreen.mageSelect:
        return 'SELECT MAGE';
      case GameScreen.nodeMap:
        return 'NODE MAP';
      case GameScreen.combat:
        return 'COMBAT';
      case GameScreen.targetSelect:
        return 'SELECT TARGET';
      case GameScreen.spellLearn:
        return 'LEARN SPELL';
      case GameScreen.enhancementShrine:
        return 'ENHANCE';
      case GameScreen.rest:
        return 'REST';
      case GameScreen.randomEvent:
        return 'RANDOM EVENT';
      case GameScreen.runEnd:
        return 'RUN END';
    }
  }
}
