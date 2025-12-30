import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../domain/enemy.dart';
import '../../../domain/element.dart' as game_element;
import 'interactable_component.dart';

/// Enemy interactable component for exploration rooms.
///
/// Displays an enemy that the player can approach and engage.
/// Shows preview panel with enemy stats before combat confirmation.
class EnemyInteractable extends InteractableComponent with GlowEffect {
  /// The enemy data.
  final Enemy enemy;

  /// Whether this is an elite enemy.
  final bool isElite;

  /// Idle animation timer.
  double _idleTimer = 0.0;

  /// Flash effect timer.
  double _flashTimer = 0.0;

  /// Whether currently flashing.
  bool _isFlashing = false;

  EnemyInteractable({
    required this.enemy,
    this.isElite = false,
    super.onApproach,
    super.onConfirm,
    super.onCancel,
    super.position,
  }) : super(
         type: InteractableType.enemy,
         triggerRadius: 80.0,
         size: Vector2(80, 90),
       );

  @override
  Color get glowColor => _elementColor;

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

  String get _intentIcon {
    switch (enemy.intent) {
      case EnemyIntent.attack:
        return '⚔️';
      case EnemyIntent.defend:
        return '🛡️';
      case EnemyIntent.debuff:
        return '💀';
    }
  }

  @override
  Map<String, dynamic> get previewData => {
    'type': 'enemy',
    'name': enemy.name,
    'element': enemy.element,
    'elementIcon': _elementIcon,
    'hp': enemy.currentHP,
    'maxHp': enemy.maxHP,
    'attack': enemy.attackDamage,
    'armor': enemy.armorGain,
    'intent': enemy.intent,
    'intentIcon': _intentIcon,
    'isElite': isElite,
    'enemy': enemy,
  };

  /// Trigger a visual flash effect.
  void flash() {
    _isFlashing = true;
    _flashTimer = 0.5;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _idleTimer += dt * 1.5;
    updateGlow(dt);

    if (_isFlashing) {
      _flashTimer -= dt;
      if (_flashTimer <= 0) {
        _isFlashing = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (isCompleted) return; // Don't render defeated enemies

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

    // Preview highlight
    if (isInPreview) {
      canvas.drawRRect(
        rrect.inflate(6),
        Paint()
          ..color = _elementColor.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    // Enemy glow
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = currentGlowColor.withValues(alpha: 0.3)
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
        ..strokeWidth = isElite ? 3 : 2,
    );

    // Elite indicator
    if (isElite) {
      final elitePaint = Paint()
        ..color = const Color(0xFFffd700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawRRect(rrect.inflate(2), elitePaint);

      // Crown icon for elite
      final crownPainter = TextPainter(
        text: const TextSpan(text: '👑', style: TextStyle(fontSize: 14)),
        textDirection: TextDirection.ltr,
      );
      crownPainter.layout();
      crownPainter.paint(canvas, Offset(size.x - 18, breathOffset - 12));
    }

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
    final intentPainter = TextPainter(
      text: TextSpan(text: _intentIcon, style: const TextStyle(fontSize: 14)),
      textDirection: TextDirection.ltr,
    );
    intentPainter.layout();
    intentPainter.paint(canvas, Offset(size.x - 20, breathOffset - 5));

    // HP indicator (small bar)
    final hpBarWidth = size.x - 16;
    final hpPercent = enemy.currentHP / enemy.maxHP;
    final hpBarRect = Rect.fromLTWH(8, size.y - 6, hpBarWidth, 4);

    // HP background
    canvas.drawRRect(
      RRect.fromRectAndRadius(hpBarRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFF21262d),
    );

    // HP fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, size.y - 6, hpBarWidth * hpPercent, 4),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF3fb950),
    );
  }

  @override
  void onApproachInternal() {
    // Could trigger sound effect or animation
    startPulse();
  }

  @override
  void onCancelInternal() {
    // Reset visual state
    setIntensity(0.5);
    startPulse();
  }

  @override
  void onConfirmInternal() {
    // Flash before transitioning to combat
    flash();
  }

  @override
  void onCompleteInternal() {
    // Enemy defeated - stop rendering
    stopPulse();
  }
}
