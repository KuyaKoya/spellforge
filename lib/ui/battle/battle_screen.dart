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
/// Architecture (LOCKED):
/// - Flame renders the world
/// - Flutter renders decisions and information
///
/// Stack order:
/// 1. FlameGameWidget (BattleScene)
/// 2. EnemyStatusBar (top-right)
/// 3. PlayerStatusBar (bottom-left)
/// 4. NodeBreadcrumbBar (top-center, reduced opacity)
/// 5. DirectorSubtitleOverlay (bottom-center)
/// 6. CombatLogPanel (bottom, toggle)
/// 7. SpellDetailOverlay (side, contextual)
/// 8. BattleActionMenu (bottom-right)
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
  bool _combatEnded = false; // Track when combat has ended

  // Combat Log
  final List<CombatLogEntry> _combatLogEntries = [];

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
        // Items not implemented in Act 1
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

    // Check if spell needs target selection
    final needsTarget = spell.effects.any(
      (e) => e.targetRule == TargetRule.single,
    );

    if (needsTarget && widget.combat.livingEnemies.length > 1) {
      setState(() {
        _pendingSpell = spell;
        _menuState = BattleMenuState.targetSelect;
      });
    } else {
      // Auto-target first enemy or cast AoE
      _executeSpell(spell, 0);
    }
  }

  void _handleTargetSelect(int enemyIndex) {
    if (_pendingSpell != null) {
      _executeSpell(_pendingSpell!, enemyIndex);
    }
  }

  void _executeSpell(Spell spell, int targetIndex) {
    // Find spell index in loadout
    final spellIndex = widget.mage.spellLoadout.indexOf(spell);
    if (spellIndex < 0) return;

    final enemyName = widget.combat.livingEnemies.isNotEmpty
        ? widget.combat.livingEnemies[targetIndex].name
        : 'enemy';

    // Log the cast
    _logCombat(
      CombatLogBuilder.spellCast(
        widget.mage.name,
        spell.name,
        spell.element.displayName,
      ),
    );

    // Execute through combat system
    widget.combat.castSpell(spellIndex, targetIndex: targetIndex);

    // Trigger animations
    _battleScene.playMageCast();

    // Show damage
    final damage = spell.baseDamage;
    _onDamageDealt(targetIndex, damage, false);
    _logCombat(CombatLogBuilder.damage(enemyName, damage));

    // Return to root menu
    setState(() {
      _menuState = BattleMenuState.root;
      _pendingSpell = null;
    });

    // Check if combat ended (all enemies dead)
    if (_checkCombatEnd()) return;

    // Auto-end turn if no more actions available
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

    // Enemy turns are handled by CombatSystem
    // Process the results
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

  /// Checks if combat should end. Returns true if combat ended.
  bool _checkCombatEnd() {
    // Check if all enemies are dead (direct check)
    final allEnemiesDead = widget.combat.livingEnemies.isEmpty;
    final playerDead = !widget.mage.isAlive;
    final combatOver = !widget.combat.isOngoing || allEnemiesDead || playerDead;

    if (combatOver) {
      setState(() => _combatEnded = true); // Disable action buttons
      
      final isVictory = allEnemiesDead && widget.mage.isAlive;
      if (isVictory) {
        _showDirectorMessage('"The pattern continues."');
        _logCombat(CombatLogBuilder.system('VICTORY'));
      } else {
        _showDirectorMessage('"Brief."');
        _logCombat(CombatLogBuilder.system('DEFEAT'));
      }

      // Delay then end combat
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
      // Hard cap at 50 entries
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0d1117),
      child: Stack(
        children: [
          // Layer 1: Flame battle scene (background, arena)
          Positioned.fill(child: GameWidget(game: _battleScene)),

          // Layer 2: Animated GIF enemy sprites overlay
          // NOTE: Removed Flame enemy sprites to avoid duplication
          // The EnemySpriteOverlay now handles all enemy rendering
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

          // Layer 3: Enemy status bar (top-right)
          Positioned(
            top: 16,
            right: 16,
            child: EnemyStatusBar(
              enemies: widget.combat.livingEnemies,
              selectedIndex: _selectedEnemyIndex,
            ),
          ),

          // Layer 3: Player status bar (bottom-left, above bottom bar)
          Positioned(
            bottom: 130, // Above the 120px bottom bar
            left: 16,
            child: PlayerStatusBar(mage: widget.mage),
          ),

          // Layer 4: Breadcrumbs (top-center, reduced opacity)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.5, // Reduced during combat
              child: NodeBreadcrumbs(
                nodeMapSystem: widget.nodeMapSystem,
                currentDepth: widget.currentDepth,
                totalDepths: widget.totalDepths,
                runNumber: widget.runNumber,
              ),
            ),
          ),

          // Layer 5: Director subtitle overlay (above bottom bar)
          if (_directorMessage != null)
            Positioned(
              bottom: 140, // Above the 120px bottom bar
              left: 0,
              right: 0,
              child: DirectorSubtitleOverlay(message: _directorMessage!),
            ),

          // Layer 6 & 9 COMBINED: Bottom bar with Action Menu (left 3/4) and Combat Log (right 1/4)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFF161b22),
                border: Border(
                  top: BorderSide(color: Color(0xFF30363d), width: 1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left side (3/4): Action buttons
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: !_combatEnded
                          ? BattleActionMenu(
                              state: _menuState,
                              mage: widget.mage,
                              enemies: widget.combat.livingEnemies,
                              onAction: _handleMenuAction,
                              onSpellSelect: _handleSpellSelect,
                              onSpellLongPress: _showSpellInspection,
                              onSpellLongPressEnd: _hideSpellInspection,
                              onTargetSelect: _handleTargetSelect,
                            )
                          : Center(
                              child: Text(
                                _combatLogEntries.isNotEmpty && 
                                    _combatLogEntries.last.message.contains('VICTORY')
                                    ? '✨ VICTORY ✨'
                                    : '💀 DEFEAT 💀',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _combatLogEntries.isNotEmpty && 
                                      _combatLogEntries.last.message.contains('VICTORY')
                                      ? const Color(0xFF3fb950)
                                      : const Color(0xFFf85149),
                                ),
                              ),
                            ),
                    ),
                  ),
                  // Divider
                  Container(
                    width: 1,
                    color: const Color(0xFF30363d),
                  ),
                  // Right side (1/4): Combat log
                  Expanded(
                    flex: 1,
                    child: CombatLogPanel(
                      entries: _combatLogEntries,
                      isExpanded: true, // Always expanded in this layout
                      onToggle: () {}, // No toggle needed
                      compact: true, // Use compact mode
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Layer 7: Spell detail overlay (side, contextual)
          if (_inspectedSpell != null)
            Positioned(
              right: 200,
              top: 100,
              child: SpellInspectionPanel(spell: _inspectedSpell!),
            ),

          // Layer 8: Floating damage numbers
          ..._damageController.buildWidgets(),
        ],
      ),
    );
  }
}

/// Enum for battle menu states.
enum BattleMenuState { root, spellSelect, targetSelect, inspect }

/// Enum for battle menu actions.
enum BattleMenuAction { spells, inspect, items, retreat, back, endTurn }
