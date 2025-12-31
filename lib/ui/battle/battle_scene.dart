import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../domain/mage.dart';
import '../../domain/enemy.dart';

/// Flame game component for battle scene rendering.
///
/// This handles:
/// - Background rendering (dungeon/arena style)
/// - Mage sprite (idle, cast, hit animations) - bottom-left
/// - Enemy sprites (idle, damage, defeat animations) - upper-center/right
/// - Visual effects (spells, damage numbers handled by Flutter overlay)
///
/// Rule: Flame renders the world, Flutter renders decisions.
///
/// Layout (Pokémon-inspired):
/// +--------------------------------+
/// | Enemy HP / Mana Status  [Icon] |  <- Flutter overlay
/// |                                |
/// |        Enemy Sprite            |  <- Flame (upper-right)
/// |                                |
/// | Player Sprite     Player Stats |  <- Flame (lower-left) + Flutter overlay
/// |                                |
/// | [ Action Button ][ Spell Btn ] |  <- Flutter overlay
/// +--------------------------------+
class BattleScene extends FlameGame {
  final Mage mage;
  final List<Enemy> enemies;
  final void Function(int index, int damage, bool isPlayer)? onDamageDealt;
  final void Function(int index, String status, bool isPlayer)? onStatusApplied;

  late _MageSprite _mageSprite;
  late List<_EnemySprite> _enemySprites;
  late _BattleBackground _background;
  late _BattleArena _arena;

  BattleScene({
    required this.mage,
    required this.enemies,
    this.onDamageDealt,
    this.onStatusApplied,
  });

  @override
  Future<void> onLoad() async {
    // Background
    _background = _BattleBackground();
    add(_background);

    // Arena floor
    _arena = _BattleArena();
    add(_arena);

    // Mage sprite (bottom-left area, facing right towards enemies)
    _mageSprite = _MageSprite(
      element: mage.primaryElement.name,
      position: Vector2(size.x * 0.12, size.y * 0.58),
    );
    add(_mageSprite);

    // Enemy sprites are now handled by Flutter's EnemySpriteOverlay
    // to enable GIF animations and avoid duplication
    _enemySprites = [];
    // NOTE: Not adding enemy sprites to Flame canvas anymore
    // The EnemySpriteOverlay in battle_screen.dart handles all enemy rendering
  }

  /// Play mage cast animation.
  void playMageCast() {
    _mageSprite.playCast();
  }

  /// Play mage hit reaction.
  void playMageHit() {
    _mageSprite.playHit();
  }

  /// Play enemy damage reaction.
  void playEnemyHit(int index) {
    if (index < _enemySprites.length) {
      _enemySprites[index].playHit();
    }
  }

  /// Play enemy defeat animation.
  void playEnemyDefeat(int index) {
    if (index < _enemySprites.length) {
      _enemySprites[index].playDefeat();
    }
  }

  /// Highlight a specific enemy (for targeting)
  void highlightEnemy(int index) {
    for (int i = 0; i < _enemySprites.length; i++) {
      _enemySprites[i].setHighlighted(i == index);
    }
  }

  /// Clear all enemy highlights
  void clearHighlights() {
    for (final sprite in _enemySprites) {
      sprite.setHighlighted(false);
    }
  }
}

/// Battle background with atmospheric gradient
class _BattleBackground extends PositionComponent with HasGameReference {
  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, game.size.x, game.size.y);

    // Deep dungeon gradient - dark and atmospheric
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF08090c),
        Color(0xFF0d1117),
        Color(0xFF131920),
        Color(0xFF1a2028),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Subtle vignette effect
    final vignetteGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
    );
    canvas.drawRect(
      rect,
      Paint()..shader = vignetteGradient.createShader(rect),
    );
  }
}

/// Battle arena floor
class _BattleArena extends PositionComponent with HasGameReference {
  @override
  void render(Canvas canvas) {
    // Arena floor line with glow
    final floorY = game.size.y * 0.72;

    // Glow
    canvas.drawLine(
      Offset(game.size.x * 0.05, floorY),
      Offset(game.size.x * 0.95, floorY),
      Paint()
        ..color = const Color(0xFF30363d)
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Main line
    canvas.drawLine(
      Offset(game.size.x * 0.05, floorY),
      Offset(game.size.x * 0.95, floorY),
      Paint()
        ..color = const Color(0xFF30363d)
        ..strokeWidth = 2,
    );

    // Decorative corner markers
    final markerPaint = Paint()
      ..color = const Color(0xFF484f58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Left corner
    canvas.drawPath(
      Path()
        ..moveTo(game.size.x * 0.05, floorY - 10)
        ..lineTo(game.size.x * 0.05, floorY)
        ..lineTo(game.size.x * 0.08, floorY),
      markerPaint,
    );

    // Right corner
    canvas.drawPath(
      Path()
        ..moveTo(game.size.x * 0.92, floorY)
        ..lineTo(game.size.x * 0.95, floorY)
        ..lineTo(game.size.x * 0.95, floorY - 10),
      markerPaint,
    );

    // Perspective floor tiles
    final tilePaint = Paint()
      ..color = const Color(0xFF21262d).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var x = 0.1; x < 0.9; x += 0.1) {
      canvas.drawLine(
        Offset(game.size.x * x, floorY),
        Offset(game.size.x * (0.5 + (x - 0.5) * 0.3), game.size.y),
        tilePaint,
      );
    }
  }
}

/// Mage sprite with animations.
class _MageSprite extends PositionComponent with HasGameReference {
  final String element;
  _MageState _state = _MageState.idle;
  double _animationTimer = 0;
  double _idleTimer = 0;

  _MageSprite({required this.element, required Vector2 position})
    : super(position: position, size: Vector2(90, 110));

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

  String get _icon {
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

  void playCast() {
    _state = _MageState.casting;
    _animationTimer = 0.5;
  }

  void playHit() {
    _state = _MageState.hit;
    _animationTimer = 0.3;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _idleTimer += dt * 2;

    if (_animationTimer > 0) {
      _animationTimer -= dt;
      if (_animationTimer <= 0) {
        _state = _MageState.idle;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final breathOffset = math.sin(_idleTimer) * 2;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y + 5),
        width: size.x * 0.7,
        height: 12,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.4),
    );

    // State-based appearance
    Color bodyColor = _elementColor.withValues(alpha: 0.3);
    Color auraColor = _elementColor.withValues(alpha: 0.2);
    double scale = 1.0;

    if (_state == _MageState.casting) {
      bodyColor = _elementColor.withValues(alpha: 0.7);
      auraColor = _elementColor.withValues(alpha: 0.5);
      scale = 1.05;
    } else if (_state == _MageState.hit) {
      bodyColor = const Color(0xFFf85149).withValues(alpha: 0.5);
      auraColor = const Color(0xFFf85149).withValues(alpha: 0.3);
    }

    final rect = Rect.fromLTWH(
      (1 - scale) * size.x / 2,
      breathOffset + (1 - scale) * size.y / 2,
      size.x * scale,
      size.y * scale,
    );

    // Aura/glow effect
    if (_state == _MageState.casting) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(8), const Radius.circular(16)),
        Paint()
          ..color = auraColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    // Body
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(rrect, Paint()..color = bodyColor);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _elementColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Mage icon
    final textPainter = TextPainter(
      text: const TextSpan(text: '🧙', style: TextStyle(fontSize: 36)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        breathOffset + (size.y - textPainter.height) / 2 - 10,
      ),
    );

    // Element indicator
    final elemPainter = TextPainter(
      text: TextSpan(text: _icon, style: const TextStyle(fontSize: 16)),
      textDirection: TextDirection.ltr,
    );
    elemPainter.layout();
    elemPainter.paint(canvas, Offset(size.x - 20, breathOffset + 5));

    // Cast effect particles
    if (_state == _MageState.casting) {
      _drawCastParticles(canvas, breathOffset);
    }
  }

  void _drawCastParticles(Canvas canvas, double breathOffset) {
    final particlePaint = Paint()
      ..color = _elementColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final angle = (_animationTimer * 10 + i * 1.2);
      final radius = 15 + (_animationTimer * 20);
      final x = size.x / 2 + math.cos(angle) * radius;
      final y = breathOffset + size.y / 2 + math.sin(angle) * radius * 0.5;
      canvas.drawCircle(Offset(x, y), 3 - _animationTimer * 4, particlePaint);
    }
  }
}

enum _MageState { idle, casting, hit }

/// Enemy sprite with animations and GIF support placeholder.
class _EnemySprite extends PositionComponent with HasGameReference {
  final Enemy enemy;
  final int spriteIndex;
  _EnemyState _state = _EnemyState.idle;
  double _animationTimer = 0;
  double _idleTimer = 0;
  double _opacity = 1.0;
  bool _isHighlighted = false;

  _EnemySprite({
    required this.enemy,
    required Vector2 position,
    required this.spriteIndex,
  }) : super(position: position, size: Vector2(100, 120));

  Color get _elementColor {
    switch (enemy.element.name) {
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

  String get _icon {
    switch (enemy.element.name) {
      case 'fire':
        return '🔥';
      case 'water':
        return '💧';
      case 'earth':
        return '🪨';
      case 'air':
        return '💨';
      default:
        return '👹';
    }
  }

  /// Get the sprite asset path for this enemy
  /// TODO: Use this when implementing GIF sprite loading
  // ignore: unused_element
  String? get _spriteAssetPath {
    // Map enemy ID to sprite file
    switch (enemy.id) {
      case 'fireImp':
        return 'assets/enemy_sprites/fire_imp.gif';
      case 'flameSerpent':
        return 'assets/enemy_sprites/fire_serpent.gif';
      case 'waterSprite':
      case 'waterSpirit':
        return 'assets/enemy_sprites/water spirit.gif';
      case 'seaSerpent':
      case 'seaStalker':
        return 'assets/enemy_sprites/sea_serpent.gif';
      case 'earthGolem':
        return 'assets/enemy_sprites/earth_golem.gif';
      default:
        return null;
    }
  }

  void playHit() {
    _state = _EnemyState.hit;
    _animationTimer = 0.3;
  }

  void playDefeat() {
    _state = _EnemyState.defeat;
    _animationTimer = 1.0;
  }

  void setHighlighted(bool highlighted) {
    _isHighlighted = highlighted;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _idleTimer += dt * 1.5;

    if (_animationTimer > 0) {
      _animationTimer -= dt;

      if (_state == _EnemyState.defeat) {
        _opacity = _animationTimer; // Fade out on defeat
      }

      if (_animationTimer <= 0) {
        if (_state == _EnemyState.hit) {
          _state = _EnemyState.idle;
        }
        // Keep defeat state
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_state == _EnemyState.defeat && _animationTimer <= 0) {
      return; // Don't render defeated enemies
    }

    final breathOffset = math.sin(_idleTimer) * 3;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y + 5),
        width: size.x * 0.7,
        height: 10,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.3 * _opacity),
    );

    final rect = Rect.fromLTWH(0, breathOffset, size.x, size.y - 10);

    Color bodyColor = _elementColor.withValues(alpha: 0.4 * _opacity);
    if (_state == _EnemyState.hit) {
      bodyColor = Colors.white.withValues(alpha: 0.7);
    }

    // Highlight glow for targeting
    if (_isHighlighted) {
      final glowRect = RRect.fromRectAndRadius(
        rect.inflate(6),
        const Radius.circular(16),
      );
      canvas.drawRRect(
        glowRect,
        Paint()
          ..color = const Color(0xFFe3b341).withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Enemy glow
    final glowRect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(
      glowRect,
      Paint()
        ..color = _elementColor.withValues(alpha: 0.3 * _opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Body
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(rrect, Paint()..color = bodyColor);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _elementColor.withValues(alpha: _opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Element icon (placeholder for GIF sprite)
    final textPainter = TextPainter(
      text: TextSpan(
        text: _icon,
        style: TextStyle(
          fontSize: 32,
          color: Colors.white.withValues(alpha: _opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        breathOffset + (size.y - 10 - textPainter.height) / 2 - 10,
      ),
    );

    // Enemy name
    final namePainter = TextPainter(
      text: TextSpan(
        text: enemy.name,
        style: TextStyle(
          fontSize: 10,
          color: Color.lerp(
            const Color(0xFFc9d1d9),
            Colors.transparent,
            1 - _opacity,
          ),
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
      text: TextSpan(
        text: intentIcon,
        style: TextStyle(
          fontSize: 16,
          color: Colors.white.withValues(alpha: _opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    intentPainter.layout();
    intentPainter.paint(canvas, Offset(size.x - 22, breathOffset - 5));

    // Hit flash effect
    if (_state == _EnemyState.hit) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5 * _animationTimer * 3)
          ..style = PaintingStyle.fill,
      );
    }
  }
}

enum _EnemyState { idle, hit, defeat }
