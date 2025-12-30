import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'interactable_component.dart';

/// Door position in a room.
enum DoorDirection {
  north,
  south,
  east,
  west;

  /// Get the direction icon.
  String get icon {
    switch (this) {
      case DoorDirection.north:
        return '↑';
      case DoorDirection.south:
        return '↓';
      case DoorDirection.east:
        return '→';
      case DoorDirection.west:
        return '←';
    }
  }

  /// Get opposite direction.
  DoorDirection get opposite {
    switch (this) {
      case DoorDirection.north:
        return DoorDirection.south;
      case DoorDirection.south:
        return DoorDirection.north;
      case DoorDirection.east:
        return DoorDirection.west;
      case DoorDirection.west:
        return DoorDirection.east;
    }
  }
}

/// State of a door.
enum DoorState {
  /// Door is locked and cannot be used.
  locked,

  /// Door is available to enter.
  available,

  /// Door leads to a cleared room.
  cleared,

  /// Door is blocked (e.g., enemy alive).
  blocked,
}

/// Door interactable component for room navigation.
///
/// Represents a doorway that the player can use to move between rooms.
/// Shows destination preview before confirming travel.
class DoorInteractable extends InteractableComponent
    with GlowEffect, DirectionalIndicator {
  /// Direction of this door.
  final DoorDirection direction;

  /// Destination node/room ID.
  final String destinationId;

  /// Type of the destination (for preview).
  final String destinationType;

  /// Current door state.
  DoorState doorState;

  /// Optional locked reason.
  final String? lockedReason;

  /// Pulse timer for animation.
  double _pulseTimer = 0.0;

  DoorInteractable({
    required this.direction,
    required this.destinationId,
    this.destinationType = 'unknown',
    this.doorState = DoorState.available,
    this.lockedReason,
    super.onApproach,
    super.onConfirm,
    super.onCancel,
    super.position,
  }) : super(
         type: InteractableType.door,
         triggerRadius: 60.0,
         size: Vector2(60, 60),
       );

  @override
  Color get glowColor {
    switch (doorState) {
      case DoorState.locked:
        return const Color(0xFF6e7681);
      case DoorState.available:
        return const Color(0xFF58a6ff);
      case DoorState.cleared:
        return const Color(0xFF3fb950);
      case DoorState.blocked:
        return const Color(0xFFf85149);
    }
  }

  @override
  Vector2 get facingDirection {
    switch (direction) {
      case DoorDirection.north:
        return Vector2(0, -1);
      case DoorDirection.south:
        return Vector2(0, 1);
      case DoorDirection.east:
        return Vector2(1, 0);
      case DoorDirection.west:
        return Vector2(-1, 0);
    }
  }

  @override
  bool get canInteract =>
      super.canInteract &&
      doorState != DoorState.locked &&
      doorState != DoorState.blocked;

  @override
  Map<String, dynamic> get previewData => {
    'type': 'door',
    'direction': direction,
    'directionIcon': direction.icon,
    'destinationId': destinationId,
    'destinationType': destinationType,
    'doorState': doorState,
    'isLocked': doorState == DoorState.locked,
    'isBlocked': doorState == DoorState.blocked,
    'lockedReason': lockedReason,
  };

  /// Block this door (e.g., when an enemy is alive).
  void block(String reason) {
    doorState = DoorState.blocked;
  }

  /// Unblock this door.
  void unblock() {
    if (doorState == DoorState.blocked) {
      doorState = DoorState.available;
    }
  }

  /// Lock this door.
  void lock() {
    doorState = DoorState.locked;
  }

  /// Unlock this door.
  void unlock() {
    if (doorState == DoorState.locked) {
      doorState = DoorState.available;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt * 2;
    updateGlow(dt);
  }

  @override
  void render(Canvas canvas) {
    final pulseAlpha = 0.5 + (math.sin(_pulseTimer) * 0.3);

    // Door frame
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Glow effect
    if (doorState == DoorState.available || isInPreview) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = glowColor.withValues(alpha: pulseAlpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Preview highlight
    if (isInPreview) {
      canvas.drawRRect(
        rrect.inflate(4),
        Paint()
          ..color = glowColor.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Door background
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF21262d));

    // Door border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = glowColor.withValues(alpha: pulseAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Locked/blocked indicator
    if (doorState == DoorState.locked || doorState == DoorState.blocked) {
      // Draw X pattern
      final xPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(size.x * 0.3, size.y * 0.3),
        Offset(size.x * 0.7, size.y * 0.7),
        xPaint,
      );
      canvas.drawLine(
        Offset(size.x * 0.7, size.y * 0.3),
        Offset(size.x * 0.3, size.y * 0.7),
        xPaint,
      );

      // Lock/block icon
      final icon = doorState == DoorState.locked ? '🔒' : '⚠️';
      final iconPainter = TextPainter(
        text: TextSpan(text: icon, style: const TextStyle(fontSize: 16)),
        textDirection: TextDirection.ltr,
      );
      iconPainter.layout();
      iconPainter.paint(
        canvas,
        Offset(
          (size.x - iconPainter.width) / 2,
          (size.y - iconPainter.height) / 2,
        ),
      );
    } else {
      // Door icon
      final textPainter = TextPainter(
        text: const TextSpan(text: '🚪', style: TextStyle(fontSize: 24)),
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

    // Direction indicator
    final dirPainter = TextPainter(
      text: TextSpan(
        text: direction.icon,
        style: TextStyle(
          fontSize: 14,
          color: glowColor.withValues(alpha: pulseAlpha),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    dirPainter.layout();
    dirPainter.paint(
      canvas,
      Offset((size.x - dirPainter.width) / 2, size.y - 14),
    );

    // Cleared checkmark
    if (doorState == DoorState.cleared) {
      final checkPainter = TextPainter(
        text: const TextSpan(
          text: '✓',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF3fb950),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      checkPainter.layout();
      checkPainter.paint(canvas, Offset(size.x - 14, 2));
    }
  }

  @override
  void onApproachInternal() {
    startPulse();
  }

  @override
  void onCancelInternal() {
    setIntensity(0.5);
    startPulse();
  }
}
