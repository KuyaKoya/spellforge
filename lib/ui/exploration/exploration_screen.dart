import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/mage.dart';
import '../../domain/enemy.dart';
import '../../nodes/node_map_system.dart';
import '../components/node_breadcrumbs.dart';
import '../battle/director_subtitle_overlay.dart';
import 'exploration_room_world.dart';
import 'room_components.dart';

/// Exploration screen with spatial room navigation.
///
/// This is a full scene that renders:
/// - Flame world (ExplorationRoomWorld)
/// - Movement controls overlay
/// - Enemy preview on approach
/// - Door confirmation on approach
/// - Breadcrumb navigation (top)
/// - Director commentary
class ExplorationScreen extends StatefulWidget {
  final RoomLayout roomLayout;
  final Mage mage;
  final NodeMapSystem nodeMapSystem;
  final int currentDepth;
  final int totalDepths;
  final int runNumber;
  final void Function(DoorPosition door)? onDoorEnter;
  final void Function(Enemy enemy)? onEngageEnemy;

  const ExplorationScreen({
    super.key,
    required this.roomLayout,
    required this.mage,
    required this.nodeMapSystem,
    required this.currentDepth,
    required this.totalDepths,
    this.runNumber = 1,
    this.onDoorEnter,
    this.onEngageEnemy,
  });

  @override
  State<ExplorationScreen> createState() => _ExplorationScreenState();
}

class _ExplorationScreenState extends State<ExplorationScreen> {
  late ExplorationRoomWorld _world;
  final FocusNode _focusNode = FocusNode();

  // UI State
  bool _showEnemyPreview = false;
  DoorPosition? _nearDoor;
  String? _directorMessage;
  bool _isMoving = false;

  // Movement state
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  @override
  void initState() {
    super.initState();
    _initWorld();
  }

  void _initWorld() {
    _world = ExplorationRoomWorld(
      roomConfig: widget.roomLayout.toRoomConfig(),
      playerElement: widget.mage.primaryElement.name,
      onEnemyApproach: _onEnemyApproach,
      onDoorApproach: _onDoorApproach,
      onDoorEnter: _onDoorEnter,
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onEnemyApproach() {
    setState(() {
      _showEnemyPreview = true;
      _nearDoor = null;
    });
    _showDirectorMessage('"They sense your presence."');
  }

  void _onDoorApproach(DoorPosition door) {
    if (widget.roomLayout.isDoorBlocked(door)) {
      _showDirectorMessage('"The path remains sealed while threats linger."');
    }
    setState(() {
      _nearDoor = door;
      _showEnemyPreview = false;
    });
  }

  void _onDoorEnter(DoorPosition door) {
    if (!widget.roomLayout.isDoorBlocked(door)) {
      widget.onDoorEnter?.call(door);
    }
  }

  void _onEngageEnemy() {
    if (widget.roomLayout.enemy != null) {
      widget.onEngageEnemy?.call(widget.roomLayout.enemy!);
    }
  }

  void _showDirectorMessage(String message) {
    setState(() => _directorMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _directorMessage = null);
      }
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }

    _updateMovement();
  }

  void _updateMovement() {
    var direction = Vector2.zero();

    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      direction.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      direction.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      direction.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      direction.x += 1;
    }

    if (direction.length > 0) {
      direction.normalize();
      _world.movePlayer(direction);
      if (!_isMoving) {
        setState(() => _isMoving = true);
      }
    } else {
      if (_isMoving) {
        setState(() => _isMoving = false);
      }
    }
  }

  void _moveInDirection(Vector2 direction) {
    _world.movePlayer(direction);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        color: const Color(0xFF0d1117),
        child: Stack(
          children: [
            // Layer 1: Flame exploration world
            Positioned.fill(child: GameWidget(game: _world)),

            // Layer 2: Breadcrumbs (top-center)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: NodeBreadcrumbs(
                nodeMapSystem: widget.nodeMapSystem,
                currentDepth: widget.currentDepth,
                totalDepths: widget.totalDepths,
                runNumber: widget.runNumber,
              ),
            ),

            // Layer 3: Room title
            if (widget.roomLayout.roomTitle != null)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161b22).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.roomLayout.roomTitle!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFc9d1d9),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),

            // Layer 4: Enemy preview (center)
            if (_showEnemyPreview && widget.roomLayout.enemy != null)
              Center(
                child: EnemyPreviewPanel(
                  enemy: widget.roomLayout.enemy!,
                  onEngage: _onEngageEnemy,
                  onRetreat: () => setState(() => _showEnemyPreview = false),
                ),
              ),

            // Layer 5: Door confirmation
            if (_nearDoor != null && !_showEnemyPreview)
              Positioned(
                bottom: 140,
                left: 0,
                right: 0,
                child: Center(
                  child: DoorConfirmation(
                    door: widget.roomLayout.getDoor(_nearDoor!) ?? DoorData(
                      position: _nearDoor!,
                      destinationNodeId: '',
                    ),
                    isBlocked: widget.roomLayout.isDoorBlocked(_nearDoor!),
                    blockedReason: widget.roomLayout.isDoorBlocked(_nearDoor!)
                        ? 'Defeat the enemy first'
                        : null,
                    onEnter: () => _onDoorEnter(_nearDoor!),
                    onCancel: () => setState(() => _nearDoor = null),
                  ),
                ),
              ),

            // Layer 6: Director subtitle
            if (_directorMessage != null)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: DirectorSubtitleOverlay(message: _directorMessage!),
              ),

            // Layer 7: Movement controls (bottom)
            Positioned(
              bottom: 16,
              left: 16,
              child: _MovementControls(
                onMove: _moveInDirection,
              ),
            ),

            // Layer 8: Controls hint
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF161b22).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'WASD / Arrow Keys to move',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),

            // Layer 9: Player status (bottom-left above controls)
            Positioned(
              bottom: 100,
              left: 16,
              child: _PlayerMiniStatus(mage: widget.mage),
            ),
          ],
        ),
      ),
    );
  }
}

/// Movement controls for touch/click
class _MovementControls extends StatelessWidget {
  final void Function(Vector2 direction) onMove;

  const _MovementControls({required this.onMove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF161b22).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Up
          Positioned(
            top: 4,
            left: 34,
            child: _DirectionButton(
              icon: Icons.arrow_drop_up,
              onTap: () => onMove(Vector2(0, -1)),
            ),
          ),
          // Down
          Positioned(
            bottom: 4,
            left: 34,
            child: _DirectionButton(
              icon: Icons.arrow_drop_down,
              onTap: () => onMove(Vector2(0, 1)),
            ),
          ),
          // Left
          Positioned(
            left: 4,
            top: 34,
            child: _DirectionButton(
              icon: Icons.arrow_left,
              onTap: () => onMove(Vector2(-1, 0)),
            ),
          ),
          // Right
          Positioned(
            right: 4,
            top: 34,
            child: _DirectionButton(
              icon: Icons.arrow_right,
              onTap: () => onMove(Vector2(1, 0)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _DirectionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (_) {
        // Continuous movement on long press
        _continuousMove();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF21262d),
          border: Border.all(color: const Color(0xFF30363d)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: const Color(0xFF8b949e), size: 24),
      ),
    );
  }

  void _continuousMove() {
    // This is a simplified version - could implement continuous movement
    onTap();
  }
}

/// Mini player status for exploration
class _PlayerMiniStatus extends StatelessWidget {
  final Mage mage;

  const _PlayerMiniStatus({required this.mage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22).withValues(alpha: 0.9),
        border: Border.all(color: const Color(0xFF30363d)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mage.name,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFFc9d1d9),
            ),
          ),
          const SizedBox(height: 4),
          _MiniBar(
            label: 'HP',
            current: mage.currentHP,
            max: mage.maxHP,
            color: const Color(0xFF3fb950),
          ),
          const SizedBox(height: 2),
          _MiniBar(
            label: 'MP',
            current: mage.mana,
            max: mage.maxMana,
            color: const Color(0xFF58a6ff),
          ),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final Color color;

  const _MiniBar({
    required this.label,
    required this.current,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF21262d),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
