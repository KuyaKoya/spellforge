import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../domain/enemy.dart';
import '../../domain/element.dart' as game_element;

/// Room configuration for exploration
class RoomConfig {
  final List<DoorPosition> doors;
  final bool hasEnemy;
  final Enemy? enemy;
  final String? roomDescription;

  const RoomConfig({
    required this.doors,
    this.hasEnemy = false,
    this.enemy,
    this.roomDescription,
  });
}

/// Door position enum
enum DoorPosition { north, south, east, west }

/// Exploration room Flame world.
///
/// Renders the spatial layout:
/// - RoomTileMap (background tiles)
/// - PlayerComponent (mage sprite at bottom-center)
/// - EnemyAnchorComponent (enemy at center-top if present)
/// - DoorComponent(s) at configured positions
/// - RoomBounds
class ExplorationRoomWorld extends FlameGame {
  final RoomConfig roomConfig;
  final String playerElement;
  final void Function(DoorPosition door)? onDoorApproach;
  final void Function()? onEnemyApproach;
  final void Function(DoorPosition door)? onDoorEnter;

  late _PlayerComponent _player;
  _EnemyAnchorComponent? _enemyAnchor;
  final List<_DoorComponent> _doors = [];
  late _RoomBackground _background;

  // Player position tracking
  Vector2 _playerPosition = Vector2.zero();
  bool _isNearEnemy = false;
  DoorPosition? _nearDoor;

  ExplorationRoomWorld({
    required this.roomConfig,
    required this.playerElement,
    this.onDoorApproach,
    this.onEnemyApproach,
    this.onDoorEnter,
  });

  @override
  Future<void> onLoad() async {
    // Background
    _background = _RoomBackground();
    add(_background);

    // Room bounds visual
    add(_RoomBounds());

    // Doors
    for (final doorPos in roomConfig.doors) {
      final door = _DoorComponent(
        position: doorPos,
        onEnter: () => onDoorEnter?.call(doorPos),
      );
      _doors.add(door);
      add(door);
    }

    // Enemy
    if (roomConfig.hasEnemy && roomConfig.enemy != null) {
      _enemyAnchor = _EnemyAnchorComponent(
        enemy: roomConfig.enemy!,
      );
      add(_enemyAnchor!);
    }

    // Player (starts at bottom-center)
    _playerPosition = Vector2(size.x / 2, size.y * 0.75);
    _player = _PlayerComponent(
      element: playerElement,
      initialPosition: _playerPosition,
    );
    add(_player);
  }

  /// Move player in direction (called from UI)
  void movePlayer(Vector2 direction) {
    final speed = 4.0;
    final newPos = _playerPosition + (direction * speed);

    // Clamp to room bounds
    final margin = 60.0;
    newPos.x = newPos.x.clamp(margin, size.x - margin);
    newPos.y = newPos.y.clamp(margin, size.y - margin);

    _playerPosition = newPos;
    _player.position = newPos;

    // Check proximity to enemy
    if (_enemyAnchor != null) {
      final distToEnemy = _playerPosition.distanceTo(_enemyAnchor!.position);
      final wasNearEnemy = _isNearEnemy;
      _isNearEnemy = distToEnemy < 80;

      if (_isNearEnemy && !wasNearEnemy) {
        onEnemyApproach?.call();
      }
    }

    // Check proximity to doors
    DoorPosition? nearestDoor;
    for (final door in _doors) {
      final distToDoor = _playerPosition.distanceTo(door.position);
      if (distToDoor < 60) {
        nearestDoor = door.doorPosition;
        break;
      }
    }

    if (nearestDoor != _nearDoor) {
      _nearDoor = nearestDoor;
      if (_nearDoor != null) {
        onDoorApproach?.call(_nearDoor!);
      }
    }
  }

  /// Check if player is near enemy
  bool get isNearEnemy => _isNearEnemy;

  /// Check if player is near a door
  DoorPosition? get nearDoor => _nearDoor;

  /// Play enemy idle flash (for attention)
  void flashEnemy() {
    _enemyAnchor?.flash();
  }
}

/// Room background with gradient and floor
class _RoomBackground extends PositionComponent with HasGameReference {
  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, game.size.x, game.size.y);

    // Dark dungeon gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF0a0e12),
        Color(0xFF0d1117),
        Color(0xFF131920),
      ],
    );

    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Floor tiles pattern
    final tileSize = 40.0;
    final tilePaint = Paint()
      ..color = const Color(0xFF1a1f26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var x = 0.0; x < game.size.x; x += tileSize) {
      for (var y = game.size.y * 0.5; y < game.size.y; y += tileSize) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, tileSize, tileSize),
          tilePaint,
        );
      }
    }
  }
}

/// Room bounds visual indicator
class _RoomBounds extends PositionComponent with HasGameReference {
  @override
  void render(Canvas canvas) {
    final margin = 40.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(margin, margin, game.size.x - margin * 2, game.size.y - margin * 2),
      const Radius.circular(16),
    );

    final paint = Paint()
      ..color = const Color(0xFF30363d)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(rect, paint);

    // Corner decorations
    final cornerPaint = Paint()
      ..color = const Color(0xFF484f58)
      ..style = PaintingStyle.fill;

    final corners = [
      Offset(margin, margin),
      Offset(game.size.x - margin, margin),
      Offset(margin, game.size.y - margin),
      Offset(game.size.x - margin, game.size.y - margin),
    ];

    for (final corner in corners) {
      canvas.drawCircle(corner, 6, cornerPaint);
    }
  }
}

/// Door component
class _DoorComponent extends PositionComponent with HasGameReference {
  final DoorPosition doorPosition;
  final VoidCallback? onEnter;
  double _pulseTimer = 0;

  _DoorComponent({
    required DoorPosition position,
    this.onEnter,
  }) : doorPosition = position, super(size: Vector2(60, 60));

  @override
  Future<void> onLoad() async {
    // Position door based on direction
    switch (doorPosition) {
      case DoorPosition.north:
        position = Vector2(game.size.x / 2 - 30, 20);
        break;
      case DoorPosition.south:
        position = Vector2(game.size.x / 2 - 30, game.size.y - 80);
        break;
      case DoorPosition.east:
        position = Vector2(game.size.x - 80, game.size.y / 2 - 30);
        break;
      case DoorPosition.west:
        position = Vector2(20, game.size.y / 2 - 30);
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt * 2;
  }

  @override
  void render(Canvas canvas) {
    final pulseAlpha = 0.5 + (math.sin(_pulseTimer) * 0.3);

    // Door frame
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Glow effect
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF58a6ff).withValues(alpha: pulseAlpha * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Door background
    canvas.drawRRect(
      rrect,
      Paint()..color = const Color(0xFF21262d),
    );

    // Door border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF58a6ff).withValues(alpha: pulseAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Door icon
    final textPainter = TextPainter(
      text: const TextSpan(text: '🚪', style: TextStyle(fontSize: 24)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.x - textPainter.width) / 2, (size.y - textPainter.height) / 2),
    );

    // Direction indicator
    final dirText = switch (doorPosition) {
      DoorPosition.north => '↑',
      DoorPosition.south => '↓',
      DoorPosition.east => '→',
      DoorPosition.west => '←',
    };

    final dirPainter = TextPainter(
      text: TextSpan(
        text: dirText,
        style: TextStyle(
          fontSize: 14,
          color: const Color(0xFF58a6ff).withValues(alpha: pulseAlpha),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    dirPainter.layout();
    dirPainter.paint(canvas, Offset((size.x - dirPainter.width) / 2, size.y - 14));
  }
}

/// Enemy anchor component
class _EnemyAnchorComponent extends PositionComponent with HasGameReference {
  final Enemy enemy;
  double _idleTimer = 0;
  double _flashTimer = 0;
  bool _isFlashing = false;

  _EnemyAnchorComponent({
    required this.enemy,
  }) : super(size: Vector2(80, 90));

  @override
  Future<void> onLoad() async {
    // Position at center-top of room
    position = Vector2(game.size.x / 2 - 40, game.size.y * 0.25);
  }

  void flash() {
    _isFlashing = true;
    _flashTimer = 0.5;
  }

  Color get _elementColor {
    switch (enemy.element) {
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

  String get _elementIcon {
    switch (enemy.element) {
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

  @override
  void update(double dt) {
    super.update(dt);
    _idleTimer += dt * 1.5;

    if (_isFlashing) {
      _flashTimer -= dt;
      if (_flashTimer <= 0) {
        _isFlashing = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final breathOffset = math.sin(_idleTimer) * 3;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y + 5),
        width: size.x * 0.8,
        height: 10,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // Body background
    final rect = Rect.fromLTWH(0, breathOffset, size.x, size.y - 10);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    // Flash effect
    if (_isFlashing) {
      canvas.drawRRect(
        rrect.inflate(4),
        Paint()
          ..color = Colors.white.withValues(alpha: _flashTimer)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Enemy glow
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _elementColor.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Enemy body
    canvas.drawRRect(
      rrect,
      Paint()..color = _elementColor.withValues(alpha: 0.4),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _elementColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Element icon
    final textPainter = TextPainter(
      text: TextSpan(text: _elementIcon, style: const TextStyle(fontSize: 28)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        breathOffset + (size.y - 10 - textPainter.height) / 2 - 8,
      ),
    );

    // Enemy name
    final namePainter = TextPainter(
      text: TextSpan(
        text: enemy.name,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFFc9d1d9),
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    namePainter.layout();
    namePainter.paint(
      canvas,
      Offset((size.x - namePainter.width) / 2, breathOffset + size.y - 24),
    );

    // Intent indicator
    final intentIcon = switch (enemy.intent) {
      EnemyIntent.attack => '⚔️',
      EnemyIntent.defend => '🛡️',
      EnemyIntent.debuff => '💀',
    };

    final intentPainter = TextPainter(
      text: TextSpan(text: intentIcon, style: const TextStyle(fontSize: 14)),
      textDirection: TextDirection.ltr,
    );
    intentPainter.layout();
    intentPainter.paint(
      canvas,
      Offset(size.x - 20, breathOffset - 5),
    );
  }
}

/// Player component
class _PlayerComponent extends PositionComponent with HasGameReference {
  final String element;
  double _idleTimer = 0;

  _PlayerComponent({
    required this.element,
    required Vector2 initialPosition,
  }) : super(position: initialPosition, size: Vector2(50, 60));

  Color get _elementColor {
    switch (element) {
      case 'fire':
        return const Color(0xFFf85149);
      case 'water':
        return const Color(0xFF58a6ff);
      case 'earth':
        return const Color(0xFF7c6f4a);
      case 'air':
        return const Color(0xFF79c0ff);
      default:
        return const Color(0xFF8b949e);
    }
  }

  String get _elementIcon {
    switch (element) {
      case 'fire':
        return '🔥';
      case 'water':
        return '💧';
      case 'earth':
        return '🪨';
      case 'air':
        return '💨';
      default:
        return '🧙';
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _idleTimer += dt * 2;
  }

  @override
  void render(Canvas canvas) {
    final breathOffset = math.sin(_idleTimer) * 2;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y + 3),
        width: size.x * 0.7,
        height: 8,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.4),
    );

    // Player body
    final rect = Rect.fromLTWH(0, breathOffset, size.x, size.y - 5);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Aura
    canvas.drawRRect(
      rrect.inflate(3),
      Paint()
        ..color = _elementColor.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Body
    canvas.drawRRect(
      rrect,
      Paint()..color = const Color(0xFF21262d),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _elementColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Mage icon
    final textPainter = TextPainter(
      text: const TextSpan(text: '🧙', style: TextStyle(fontSize: 22)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        breathOffset + (size.y - 5 - textPainter.height) / 2 - 4,
      ),
    );

    // Element indicator
    final elemPainter = TextPainter(
      text: TextSpan(text: _elementIcon, style: const TextStyle(fontSize: 12)),
      textDirection: TextDirection.ltr,
    );
    elemPainter.layout();
    elemPainter.paint(
      canvas,
      Offset(size.x - 14, breathOffset),
    );
  }
}
