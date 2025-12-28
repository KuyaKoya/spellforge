import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../domain/mage.dart';
import '../../domain/enemy.dart';

/// Flame game component for battle scene rendering.
///
/// This handles:
/// - Background rendering
/// - Mage sprite (idle, cast, hit animations)
/// - Enemy sprites (idle, damage, defeat animations)
/// - Visual effects
///
/// Rule: Flame renders the world, Flutter renders decisions.
class BattleScene extends FlameGame {
  final Mage mage;
  final List<Enemy> enemies;
  final void Function(int index, int damage, bool isPlayer)? onDamageDealt;
  final void Function(int index, String status, bool isPlayer)? onStatusApplied;

  late _MageSprite _mageSprite;
  late List<_EnemySprite> _enemySprites;
  late _BackgroundComponent _background;

  BattleScene({
    required this.mage,
    required this.enemies,
    this.onDamageDealt,
    this.onStatusApplied,
  });

  @override
  Future<void> onLoad() async {
    // Background
    _background = _BackgroundComponent();
    add(_background);

    // Mage sprite (bottom-left area)
    _mageSprite = _MageSprite(
      element: mage.primaryElement.name,
      position: Vector2(size.x * 0.2, size.y * 0.65),
    );
    add(_mageSprite);

    // Enemy sprites (right side, stacked)
    _enemySprites = [];
    for (int i = 0; i < enemies.length; i++) {
      final enemy = enemies[i];
      final sprite = _EnemySprite(
        element: enemy.element.name,
        position: Vector2(size.x * 0.75, size.y * 0.35 + (i * 80)),
      );
      _enemySprites.add(sprite);
      add(sprite);
    }
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
}

/// Background component.
class _BackgroundComponent extends PositionComponent with HasGameReference {
  @override
  void render(Canvas canvas) {
    // Dark gradient background
    final rect = Rect.fromLTWH(0, 0, game.size.x, game.size.y);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0d1117),
        const Color(0xFF161b22),
        const Color(0xFF21262d),
      ],
    );

    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Ground line
    canvas.drawLine(
      Offset(0, game.size.y * 0.75),
      Offset(game.size.x, game.size.y * 0.75),
      Paint()
        ..color = const Color(0xFF30363d)
        ..strokeWidth = 2,
    );
  }
}

/// Mage sprite with animations.
class _MageSprite extends PositionComponent with HasGameReference {
  final String element;
  _MageState _state = _MageState.idle;
  double _animationTimer = 0;

  _MageSprite({required this.element, required Vector2 position})
    : super(position: position, size: Vector2(80, 100));

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

    if (_animationTimer > 0) {
      _animationTimer -= dt;
      if (_animationTimer <= 0) {
        _state = _MageState.idle;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Simple placeholder sprite
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // Body color based on state
    Color bodyColor = _elementColor.withValues(alpha: 0.3);
    if (_state == _MageState.casting) {
      bodyColor = _elementColor.withValues(alpha: 0.7);
    } else if (_state == _MageState.hit) {
      bodyColor = const Color(0xFFf85149).withValues(alpha: 0.5);
    }

    // Draw body
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, Paint()..color = bodyColor);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _elementColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw element icon in center (using TextPainter for emoji)
    final textPainter = TextPainter(
      text: TextSpan(text: _icon, style: const TextStyle(fontSize: 32)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );
  }
}

enum _MageState { idle, casting, hit }

/// Enemy sprite with animations.
class _EnemySprite extends PositionComponent with HasGameReference {
  final String element;
  _EnemyState _state = _EnemyState.idle;
  double _animationTimer = 0;
  double _opacity = 1.0;

  _EnemySprite({required this.element, required Vector2 position})
    : super(position: position, size: Vector2(60, 70));

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
        return '👹';
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

  @override
  void update(double dt) {
    super.update(dt);

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

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    Color bodyColor = _elementColor.withValues(alpha: 0.3 * _opacity);
    if (_state == _EnemyState.hit) {
      bodyColor = Colors.white.withValues(alpha: 0.5);
    }

    // Draw body
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, Paint()..color = bodyColor);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _elementColor.withValues(alpha: _opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw element icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: _icon,
        style: TextStyle(
          fontSize: 24,
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
        (size.y - textPainter.height) / 2,
      ),
    );
  }
}

enum _EnemyState { idle, hit, defeat }
