import 'package:flutter/material.dart';

import '../../domain/mage.dart';
import '../../domain/enemy.dart';
import '../../domain/element.dart' as game_element;
import '../../game/exploration/exploration_controller.dart';
import '../../game/exploration/components/components.dart';
import '../../nodes/nodes.dart';
import '../../nodes/node_map_system.dart';
import '../../systems/audio_manager.dart';
import '../../systems/shop_system.dart';
import '../components/node_breadcrumbs.dart';
import '../battle/director_subtitle_overlay.dart';
import 'exploration_hud.dart';
import 'preview_panels/preview_panels.dart';

/// Simplified tap-based exploration screen.
///
/// No movement controls - just tap on enemies, doors, or other
/// interactables to see preview and confirm interaction.
class ExplorationScreenV2 extends StatefulWidget {
  /// Current room configuration.
  final RoomConfiguration roomConfig;

  /// Player's mage.
  final Mage mage;

  /// Node map system for breadcrumbs.
  final NodeMapSystem nodeMapSystem;

  /// Current depth in the run.
  final int currentDepth;

  /// Total depths in the run.
  final int totalDepths;

  /// Run number (for Director context).
  final int runNumber;

  /// Temporary buffs active on the player.
  final List<TemporaryBuff>? temporaryBuffs;

  /// Callback when player engages an enemy.
  final void Function(Enemy enemy, bool isElite)? onEngageEnemy;

  /// Callback when player travels through a door.
  final void Function(DoorDirection direction, String destinationId)? onTravel;

  /// Callback when player taps a non-combat interactable (shop, shrine, etc.).
  final void Function(NodeType nodeType)? onInteractableTapped;

  /// Callback when player returns from combat (enemy defeated).
  final void Function()? onEnemyDefeated;

  /// Callback when player completes a non-combat interaction.
  final void Function()? onInteractionCompleted;

  const ExplorationScreenV2({
    super.key,
    required this.roomConfig,
    required this.mage,
    required this.nodeMapSystem,
    required this.currentDepth,
    required this.totalDepths,
    this.runNumber = 1,
    this.temporaryBuffs,
    this.onEngageEnemy,
    this.onTravel,
    this.onInteractableTapped,
    this.onEnemyDefeated,
    this.onInteractionCompleted,
  });

  @override
  State<ExplorationScreenV2> createState() => _ExplorationScreenV2State();
}

class _ExplorationScreenV2State extends State<ExplorationScreenV2>
    with SingleTickerProviderStateMixin {
  late ExplorationController _controller;

  // Currently selected interactable type
  InteractableType? _selectedType;

  // Phase 7.6.2: Fade animation for room entrance
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initController();
    _initFadeAnimation();
  }

  void _initFadeAnimation() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    // Start with full opacity (first room load)
    _fadeController.value = 1.0;
  }

  void _initController() {
    _controller = ExplorationController();
    _controller.loadRoom(config: widget.roomConfig, mage: widget.mage);
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(ExplorationScreenV2 oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If room changed completely, reload the controller
    if (widget.roomConfig.roomId != oldWidget.roomConfig.roomId) {
      // Phase 7.6.2: Play entering room sound and fade animation
      AudioManager.instance.playEnteringRoom();
      _triggerRoomFadeIn();
      _controller.loadRoom(config: widget.roomConfig, mage: widget.mage);
      _selectedType = null;
      return;
    }

    // Update controller if mage changed (e.g., after combat)
    if (widget.mage != oldWidget.mage) {
      _controller.updateMage(widget.mage);
    }

    // Check if enemy was defeated
    if (widget.roomConfig.enemyDefeated &&
        !oldWidget.roomConfig.enemyDefeated) {
      _controller.markEnemyDefeated();
    }

    // Check if interaction was completed
    if (widget.roomConfig.interactionCompleted &&
        !oldWidget.roomConfig.interactionCompleted) {
      _controller.markInteractionCompleted();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  /// Trigger fade-in animation for room entrance
  void _triggerRoomFadeIn() {
    _fadeController.reset();
    _fadeController.forward();
  }

  void _onControllerUpdate() {
    setState(() {});

    // Check for pending results
    final result = _controller.consumeResult();
    if (result != null) {
      _handleResult(result);
    }
  }

  void _handleResult(ExplorationResult result) {
    switch (result) {
      case EngageEnemyResult(:final enemy, :final isElite):
        widget.onEngageEnemy?.call(enemy, isElite);
        break;

      case TravelDoorResult(:final direction, :final destinationId):
        widget.onTravel?.call(direction, destinationId);
        break;

      case EnterShopResult():
        break;

      case EngageEventResult():
        break;

      case UseShrineResult():
        break;
    }
  }

  void _onEnemyTapped() {
    if (_controller.roomConfig?.enemy != null &&
        !_controller.roomConfig!.enemyDefeated) {
      // Phase 7.6.2: Play enemy select sound when showing preview
      AudioManager.instance.playEnemySelect();
      final interactable = EnemyInteractable(
        enemy: _controller.roomConfig!.enemy!,
        isElite: _controller.roomConfig!.isEliteEnemy,
      );
      _selectedType = InteractableType.enemy;
      _controller.onApproachInteractable(interactable);
    }
  }

  void _onDoorTapped(DoorConfig doorConfig) {
    if (_controller.areDoorsBlocked) {
      _controller.showDirectorMessage('"Defeat the enemy first."');
      return;
    }

    // Phase 7.6.2: Play room select sound when showing preview
    AudioManager.instance.playRoomSelect();
    final interactable = DoorInteractable(
      direction: doorConfig.direction,
      destinationId: doorConfig.destinationId,
      destinationType: doorConfig.destinationType,
      doorState: doorConfig.state,
    );
    _selectedType = InteractableType.door;
    _controller.onApproachInteractable(interactable);
  }

  void _onCancelPreview() {
    _controller.onCancelInteraction();
    _selectedType = null;
  }

  void _onConfirmInteraction() {
    _controller.onConfirmInteraction();
    _selectedType = null;
  }

  @override
  Widget build(BuildContext context) {
    // Phase 7.6.2: Wrap in FadeTransition for room entrance animation
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: const Color(0xFF0d1117),
        child: Stack(
          children: [
            // Layer 1: Room background
            Positioned.fill(child: _buildRoomBackground()),

            // Layer 2: Breadcrumbs (top)
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
            if (widget.roomConfig.title != null)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161b22).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.roomConfig.title!,
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

            // Layer 4: Interactive elements (enemy, doors)
            Positioned.fill(child: _buildInteractiveElements()),

            // Layer 5: Preview panel (center overlay)
            if (_controller.isPaused && _controller.activeInteractable != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _onCancelPreview, // Tap outside to cancel
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {}, // Prevent tap-through
                        child: _buildPreviewPanel(),
                      ),
                    ),
                  ),
                ),
              ),

            // Layer 6: Director subtitle
            if (_controller.directorMessage != null)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: DirectorSubtitleOverlay(
                  message: _controller.directorMessage!,
                ),
              ),

            // Layer 7: HUD (bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ExplorationHUD(
                mage: widget.mage,
                directorActive: _controller.directorMessage != null,
                temporaryBuffs: widget.temporaryBuffs,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0d1117)],
        ),
      ),
      child: CustomPaint(painter: _RoomGridPainter()),
    );
  }

  Widget _buildInteractiveElements() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        final centerY = constraints.maxHeight / 2;

        // Use controller's state for consistency
        final roomConfig = _controller.roomConfig ?? widget.roomConfig;
        final hasEnemy = _controller.hasLivingEnemy;
        final nodeType = roomConfig.nodeType;

        // Check if this is a non-combat interactable node
        final isNonCombatNode =
            nodeType != null &&
            !nodeType.isCombat &&
            nodeType != NodeType.bossCombat;

        return Stack(
          children: [
            // Doors
            ..._buildDoors(constraints),

            // Enemy (center-ish) - only for combat nodes
            if (hasEnemy)
              Positioned(
                left: centerX - 60,
                top: centerY - 80,
                child: _buildEnemyWidget(),
              ),

            // Non-combat interactable (merchant, altar, campfire, etc.)
            // Only show if interaction NOT completed
            if (isNonCombatNode &&
                !hasEnemy &&
                !roomConfig.interactionCompleted)
              Positioned(
                left: centerX - 60,
                top: centerY - 80,
                child: _buildInteractableWidget(nodeType),
              ),

            // "Used" indicator if interaction completed (optional, or just nothing)
            // User asked it to "disappear", so we leave empty or show subtle trace.
            // For now, let's just make it disappear as requested.

            // "Cleared" indicator if enemy was defeated
            if (roomConfig.enemy != null && !hasEnemy)
              Positioned(
                left: centerX - 50,
                top: centerY - 20,
                child: _buildClearedIndicator(),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _buildDoors(BoxConstraints constraints) {
    final doors = <Widget>[];
    final centerX = constraints.maxWidth / 2;
    final centerY = constraints.maxHeight / 2;

    for (final door in widget.roomConfig.doors) {
      double left, top;

      switch (door.direction) {
        case DoorDirection.north:
          left = centerX - 40;
          top = 100;
          break;
        case DoorDirection.south:
          left = centerX - 40;
          top = constraints.maxHeight - 180;
          break;
        case DoorDirection.east:
          left = constraints.maxWidth - 100;
          top = centerY - 40;
          break;
        case DoorDirection.west:
          left = 20;
          top = centerY - 40;
          break;
      }

      doors.add(
        Positioned(left: left, top: top, child: _buildDoorWidget(door)),
      );
    }

    return doors;
  }

  Widget _buildEnemyWidget() {
    final enemy = widget.roomConfig.enemy!;
    final isElite = widget.roomConfig.isEliteEnemy;
    final elementColor = _getElementColor(enemy.element);

    return GestureDetector(
      onTap: _onEnemyTapped,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF161b22),
          border: Border.all(color: elementColor, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: elementColor.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Elite badge
            if (isElite)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFffd700).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '👑 ELITE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFffd700),
                  ),
                ),
              ),

            // Element icon
            Text(
              _getElementIcon(enemy.element),
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),

            // Name
            Text(
              enemy.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFc9d1d9),
              ),
            ),
            const SizedBox(height: 8),

            // HP bar
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF21262d),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: enemy.currentHP / enemy.maxHP,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3fb950),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),

            Text(
              '${enemy.currentHP}/${enemy.maxHP} HP',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),

            // Tap hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: elementColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'TAP TO ENGAGE',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFc9d1d9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an interactable widget for non-combat nodes (merchant, altar, etc.).
  Widget _buildInteractableWidget(NodeType nodeType) {
    // Get icon and name based on node type
    String icon;
    String name;
    Color accentColor;

    switch (nodeType) {
      case NodeType.shop:
        icon = '🏪';
        name = 'Merchant';
        accentColor = const Color(0xFF3fb950);
        break;
      case NodeType.enhancementShrine:
        icon = '✨';
        name = 'Shrine';
        accentColor = const Color(0xFFe3b341);
        break;
      case NodeType.spellLearn:
        icon = '📚';
        name = 'Spell Tome';
        accentColor = const Color(0xFF58a6ff);
        break;
      case NodeType.rest:
        icon = '🔥';
        name = 'Campfire';
        accentColor = const Color(0xFFf85149);
        break;
      case NodeType.randomEvent:
        icon = '❓';
        name = 'Mystery';
        accentColor = const Color(0xFFa371f7);
        break;
      default:
        icon = '📍';
        name = 'Interactable';
        accentColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () => widget.onInteractableTapped?.call(nodeType),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF161b22),
          border: Border.all(color: accentColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Text(icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),

            // Name
            Text(
              name,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 8),

            // Tap hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'TAP TO INTERACT',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFc9d1d9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoorWidget(DoorConfig door) {
    final isBlocked = _controller.areDoorsBlocked;
    final color = isBlocked ? const Color(0xFF6e7681) : const Color(0xFF58a6ff);

    return GestureDetector(
      onTap: () => _onDoorTapped(door),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF161b22),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isBlocked ? '🔒' : '🚪', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              door.direction.icon,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (isBlocked) ...[
              const SizedBox(height: 4),
              Text(
                'BLOCKED',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  color: Colors.grey.shade500,
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                'TAP',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClearedIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3fb950).withValues(alpha: 0.2),
        border: Border.all(color: const Color(0xFF3fb950)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('✓', style: TextStyle(fontSize: 20, color: Color(0xFF3fb950))),
          SizedBox(width: 8),
          Text(
            'CLEARED',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3fb950),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel() {
    final interactable = _controller.activeInteractable!;
    final previewData = interactable.previewData;

    switch (_selectedType) {
      case InteractableType.enemy:
        return EnemyPreviewPanel(
          enemy: previewData['enemy'] as Enemy,
          isElite: previewData['isElite'] as bool? ?? false,
          playerSpellElements: widget.mage.spellLoadout
              .map((s) => s.element)
              .toList(),
          directorLine: _controller.directorMessage,
          onConfirm: _onConfirmInteraction,
          onCancel: _onCancelPreview,
        );

      case InteractableType.door:
        return DoorPreviewPanel(
          direction: previewData['direction'] as DoorDirection,
          destinationType: previewData['destinationType'] as String,
          doorState: _controller.areDoorsBlocked
              ? DoorState.blocked
              : previewData['doorState'] as DoorState,
          blockedReason: _controller.areDoorsBlocked
              ? 'Defeat the enemy first'
              : null,
          directorLine: _controller.directorMessage,
          onConfirm: _controller.areDoorsBlocked ? null : _onConfirmInteraction,
          onCancel: _onCancelPreview,
        );

      default:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161b22),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Coming soon: ${_selectedType?.name ?? 'unknown'}',
            style: const TextStyle(color: Colors.white),
          ),
        );
    }
  }

  Color _getElementColor(game_element.Element element) {
    switch (element) {
      case game_element.Element.fire:
        return const Color(0xFFf85149);
      case game_element.Element.water:
        return const Color(0xFF58a6ff);
      case game_element.Element.earth:
        return const Color(0xFF7c6f4a);
      case game_element.Element.air:
        return const Color(0xFF79c0ff);
    }
  }

  String _getElementIcon(game_element.Element element) {
    switch (element) {
      case game_element.Element.fire:
        return '🔥';
      case game_element.Element.water:
        return '💧';
      case game_element.Element.earth:
        return '🪨';
      case game_element.Element.air:
        return '💨';
    }
  }
}

/// Painter for the room grid background.
class _RoomGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF30363d).withValues(alpha: 0.3)
      ..strokeWidth = 1;

    const gridSize = 40.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
