import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../../systems/combat_system.dart';
import '../../domain/mage.dart';
import '../../domain/enemy.dart';
import '../../domain/spell.dart';
import '../../domain/effect.dart';
import '../../narrative/journey_log.dart';
import '../../nodes/node_map_system.dart';
import '../components/components.dart';
import 'battle_scene.dart';
import 'status_bars.dart';
import 'battle_action_menu.dart';
import 'director_subtitle_overlay.dart';
import 'floating_damage.dart';
import 'sprite_overlay.dart';

/// Main battle screen widget implementing Pokémon-inspired UI.
///
/// LAYOUT (PORTRAIT - Pokémon-style zones):
/// ┌─────────────────────────────────┐
/// │ ZONE 1 - ENEMY AREA (35%)       │
/// │   Enemy Status Panel (top-left) │
/// │   Enemy Sprite (centered)       │
/// ├─────────────────────────────────┤
/// │ ZONE 2 - BATTLEFIELD (30%)      │
/// │   Player Sprite (bottom-left)   │
/// │   Visual breathing room         │
/// ├─────────────────────────────────┤
/// │ ZONE 3 - PLAYER STATUS (15%)    │
/// │   Player Status Panel           │
/// ├─────────────────────────────────┤
/// │ ZONE 4 - ACTION PANEL (20%)     │
/// │   Action Box System             │
/// └─────────────────────────────────┘
///
/// Architecture (LOCKED):
/// - Flame renders the world (background, player sprite)
/// - Flutter renders decisions and information (overlays)
class BattleScreen extends StatefulWidget {
  final CombatSystem combat;
  final Mage mage;
  final List<Enemy> enemies;
  final NodeMapSystem nodeMapSystem;
  final JourneyLog journeyLog;
  final int currentDepth;
  final int totalDepths;
  final int runNumber;
  final VoidCallback? onCombatEnd;
  final VoidCallback? onRetreat;
  final void Function(String)? onInput;

  const BattleScreen({
    super.key,
    required this.combat,
    required this.mage,
    required this.enemies,
    required this.nodeMapSystem,
    required this.journeyLog,
    required this.currentDepth,
    required this.totalDepths,
    this.runNumber = 1,
    this.onCombatEnd,
    this.onRetreat,
    this.onInput,
  });

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late BattleScene _battleScene;

  // UI State
  BattleMenuState _menuState = BattleMenuState.root;
  Spell? _inspectedSpell;
  String? _directorMessage;
  int? _selectedEnemyIndex;
  Spell? _pendingSpell;
  bool _combatEnded = false;

  // Combat Log
  final List<CombatLogEntry> _combatLogEntries = [];
  bool _showCombatLog = false;

  // Floating damage controller
  final FloatingDamageController _damageController = FloatingDamageController();

  @override
  void initState() {
    super.initState();
    _battleScene = BattleScene(
      mage: widget.mage,
      enemies: widget.enemies,
      onDamageDealt: _onDamageDealt,
      onStatusApplied: _onStatusApplied,
    );
  }

  void _onDamageDealt(int index, int damage, bool isPlayer) {
    _damageController.showDamage(
      targetIndex: index,
      damage: damage,
      isPlayer: isPlayer,
    );
  }

  void _onStatusApplied(int index, String status, bool isPlayer) {
    _damageController.showStatus(
      targetIndex: index,
      status: status,
      isPlayer: isPlayer,
    );
  }

  void _showDirectorMessage(String message) {
    setState(() => _directorMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _directorMessage = null);
      }
    });
  }

  void _handleMenuAction(BattleMenuAction action) {
    switch (action) {
      case BattleMenuAction.spells:
        setState(() => _menuState = BattleMenuState.spellSelect);
        break;
      case BattleMenuAction.inspect:
        setState(() => _menuState = BattleMenuState.inspect);
        break;
      case BattleMenuAction.items:
        _logCombat(CombatLogBuilder.system('No items available'));
        break;
      case BattleMenuAction.retreat:
        _handleRetreat();
        break;
      case BattleMenuAction.back:
        setState(() {
          _menuState = BattleMenuState.root;
          _pendingSpell = null;
        });
        break;
      case BattleMenuAction.endTurn:
        _handleEndTurn();
        break;
    }
  }

  void _handleSpellSelect(Spell spell) {
    if (!widget.mage.canCast(spell)) {
      _logCombat(CombatLogBuilder.system('Not enough mana'));
      return;
    }

    final needsTarget = spell.effects.any(
      (e) => e.targetRule == TargetRule.single,
    );

    if (needsTarget && widget.combat.livingEnemies.length > 1) {
      setState(() {
        _pendingSpell = spell;
        _menuState = BattleMenuState.targetSelect;
      });
    } else {
      _executeSpell(spell, 0);
    }
  }

  void _handleTargetSelect(int enemyIndex) {
    if (_pendingSpell != null) {
      _executeSpell(_pendingSpell!, enemyIndex);
    }
  }

  void _executeSpell(Spell spell, int targetIndex) {
    final spellIndex = widget.mage.spellLoadout.indexOf(spell);
    if (spellIndex < 0) return;

    final enemyName = widget.combat.livingEnemies.isNotEmpty
        ? widget.combat.livingEnemies[targetIndex].name
        : 'enemy';

    _logCombat(
      CombatLogBuilder.spellCast(
        widget.mage.name,
        spell.name,
        spell.element.displayName,
      ),
    );

    final result = widget.combat.castSpell(
      spellIndex,
      targetIndex: targetIndex,
    );
    _battleScene.playMageCast();

    if (result != null && result.success && result.totalDamage > 0) {
      final damage = result.totalDamage;
      _onDamageDealt(targetIndex, damage, false);
      _logCombat(CombatLogBuilder.damage(enemyName, damage));
    }

    setState(() {
      _menuState = BattleMenuState.root;
      _pendingSpell = null;
    });

    if (_checkCombatEnd()) return;

    if (!widget.combat.canPlayerAct) {
      _logCombat(CombatLogBuilder.system('No more actions - ending turn'));
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _handleEndTurn();
      });
    }
  }

  void _handleEndTurn() {
    widget.combat.endPlayerTurn();
    _logCombat(CombatLogBuilder.turnMarker(widget.combat.currentTurn));
    setState(() => _menuState = BattleMenuState.root);
    _checkCombatEnd();
  }

  void _handleRetreat() {
    _showDirectorMessage('"Retreat is not failure. It is recognition."');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        if (widget.onRetreat != null) {
          widget.onRetreat!();
        } else {
          widget.onCombatEnd?.call();
        }
      }
    });
  }

  bool _checkCombatEnd() {
    final allEnemiesDead = widget.combat.livingEnemies.isEmpty;
    final playerDead = !widget.mage.isAlive;
    final combatOver = !widget.combat.isOngoing || allEnemiesDead || playerDead;

    if (combatOver) {
      setState(() => _combatEnded = true);

      final isVictory = allEnemiesDead && widget.mage.isAlive;
      if (isVictory) {
        _showDirectorMessage('"The pattern continues."');
        _logCombat(CombatLogBuilder.system('VICTORY'));
      } else {
        _showDirectorMessage('"Brief."');
        _logCombat(CombatLogBuilder.system('DEFEAT'));
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          widget.onCombatEnd?.call();
        }
      });
      return true;
    }
    return false;
  }

  void _logCombat(CombatLogEntry entry) {
    setState(() {
      _combatLogEntries.add(entry);
      if (_combatLogEntries.length > 50) {
        _combatLogEntries.removeAt(0);
      }
    });
  }

  void _showSpellInspection(Spell spell) {
    setState(() => _inspectedSpell = spell);
  }

  void _hideSpellInspection() {
    setState(() => _inspectedSpell = null);
  }

  void _toggleCombatLog() {
    setState(() => _showCombatLog = !_showCombatLog);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0d1117),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;

            // Zone heights (Pokémon-style distribution)
            final zone1Height = screenHeight * 0.35; // Enemy area
            final zone2Height = screenHeight * 0.25; // Battlefield (Reduced)
            final zone3Height = screenHeight * 0.15; // Player status
            final zone4Height = screenHeight * 0.25; // Action panel (Increased)

            return Stack(
              children: [
                // ═══════════════════════════════════════════════════════
                // LAYER 1: Flame battle scene (background + player sprite)
                // ═══════════════════════════════════════════════════════
                Positioned.fill(child: GameWidget(game: _battleScene)),

                // ═══════════════════════════════════════════════════════
                // ZONE 1: ENEMY AREA (Top 35%)
                // ═══════════════════════════════════════════════════════
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height:
                      zone1Height +
                      zone2Height * 0.3, // Extend into battlefield
                  child: _buildEnemyZone(screenWidth),
                ),

                // ═══════════════════════════════════════════════════════
                // ZONE 2: BATTLEFIELD implied by gap (player sprite in Flame)
                // Ground plane / shadow handled by BattleScene
                // ═══════════════════════════════════════════════════════

                // ═══════════════════════════════════════════════════════
                // ZONE 3: PLAYER STATUS (Lower 15%)
                // ═══════════════════════════════════════════════════════
                Positioned(
                  bottom: zone4Height + 8,
                  right: 16,
                  child: PokemonPlayerStatusPanel(mage: widget.mage),
                ),

                // ═══════════════════════════════════════════════════════
                // ZONE 4: ACTION PANEL (Bottom 20%)
                // ═══════════════════════════════════════════════════════
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: zone4Height,
                  child: _buildActionPanel(zone4Height),
                ),

                // ═══════════════════════════════════════════════════════
                // OVERLAY: Director subtitle (above action panel)
                // ═══════════════════════════════════════════════════════
                if (_directorMessage != null)
                  Positioned(
                    bottom: zone4Height + zone3Height / 2,
                    left: 0,
                    right: 0,
                    child: DirectorSubtitleOverlay(message: _directorMessage!),
                  ),

                // ═══════════════════════════════════════════════════════
                // OVERLAY: Spell detail (contextual, non-fullscreen)
                // ═══════════════════════════════════════════════════════
                if (_inspectedSpell != null)
                  Positioned.fill(child: _buildSpellInspectionOverlay()),

                // ═══════════════════════════════════════════════════════
                // OVERLAY: Combat log (collapsible panel)
                // ═══════════════════════════════════════════════════════
                if (_showCombatLog)
                  Positioned(
                    bottom: zone4Height,
                    left: 0,
                    right: 0,
                    child: _buildCombatLogOverlay(),
                  ),

                // ═══════════════════════════════════════════════════════
                // OVERLAY: Floating damage numbers
                // ═══════════════════════════════════════════════════════
                ..._damageController.buildWidgets(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// ZONE 1: Enemy area with status panel and sprites
  Widget _buildEnemyZone(double screenWidth) {
    return Stack(
      children: [
        // Enemy sprites (centered, elevated)
        Positioned.fill(
          child: EnemySpriteOverlay(
            enemies: widget.combat.livingEnemies,
            highlightedIndex: _menuState == BattleMenuState.targetSelect
                ? _selectedEnemyIndex
                : null,
            onTap: (_menuState == BattleMenuState.targetSelect && !_combatEnded)
                ? (index) => _handleTargetSelect(index)
                : null,
          ),
        ),

        // Enemy status panel (top-left, Pokémon-style)
        Positioned(
          top: 80,
          left: 16,
          child: PokemonEnemyStatusPanel(
            enemies: widget.combat.livingEnemies,
            selectedIndex: _selectedEnemyIndex,
          ),
        ),
      ],
    );
  }

  /// ZONE 4: Action panel with Pokémon-style action box
  Widget _buildActionPanel(double panelHeight) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF21262d),
        border: Border(top: BorderSide(color: Color(0xFF484f58), width: 2)),
      ),
      child: Column(
        children: [
          // Header row with log toggle button
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF161b22),
              border: Border(
                bottom: BorderSide(color: Color(0xFF30363d), width: 1),
              ),
            ),
            child: Row(
              children: [
                // Menu state indicator
                Text(
                  _getMenuTitle(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFc9d1d9),
                  ),
                ),
                const Spacer(),
                // Combat log toggle
                GestureDetector(
                  onTap: _toggleCombatLog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _showCombatLog
                          ? const Color(0xFF30363d)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF484f58),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showCombatLog
                              ? Icons.expand_more
                              : Icons.expand_less,
                          size: 12,
                          color: const Color(0xFF8b949e),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LOG',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9,
                            color: _showCombatLog
                                ? const Color(0xFFc9d1d9)
                                : const Color(0xFF8b949e),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _combatEnded
                  ? _buildCombatEndDisplay()
                  : PokemonActionBox(
                      state: _menuState,
                      mage: widget.mage,
                      enemies: widget.combat.livingEnemies,
                      onAction: _handleMenuAction,
                      onSpellSelect: _handleSpellSelect,
                      onSpellLongPress: _showSpellInspection,
                      onSpellLongPressEnd: _hideSpellInspection,
                      onTargetSelect: _handleTargetSelect,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMenuTitle() {
    switch (_menuState) {
      case BattleMenuState.root:
        return 'What will you do?';
      case BattleMenuState.spellSelect:
        return 'Choose a spell';
      case BattleMenuState.targetSelect:
        return 'Select target';
      case BattleMenuState.inspect:
        return 'Battle info';
    }
  }

  Widget _buildCombatEndDisplay() {
    final isVictory =
        _combatLogEntries.isNotEmpty &&
        _combatLogEntries.last.message.contains('VICTORY');

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isVictory
                ? [const Color(0xFF238636), const Color(0xFF2ea043)]
                : [const Color(0xFFb62324), const Color(0xFFda3633)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color:
                  (isVictory
                          ? const Color(0xFF3fb950)
                          : const Color(0xFFf85149))
                      .withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          isVictory ? '✨ VICTORY ✨' : '💀 DEFEAT 💀',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildSpellInspectionOverlay() {
    return GestureDetector(
      onTap: _hideSpellInspection,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent tap-through
            child: SpellDetailCard(spell: _inspectedSpell!),
          ),
        ),
      ),
    );
  }

  Widget _buildCombatLogOverlay() {
    return Container(
      height: 160,
      decoration: const BoxDecoration(
        color: Color(0xFF0d1117),
        border: Border(
          top: BorderSide(color: Color(0xFF30363d), width: 1),
          bottom: BorderSide(color: Color(0xFF30363d), width: 1),
        ),
      ),
      child: CombatLogPanel(
        entries: _combatLogEntries,
        isExpanded: true,
        onToggle: _toggleCombatLog,
        compact: false,
      ),
    );
  }
}

/// Enum for battle menu states.
enum BattleMenuState { root, spellSelect, targetSelect, inspect }

/// Enum for battle menu actions.
enum BattleMenuAction { spells, inspect, items, retreat, back, endTurn }
