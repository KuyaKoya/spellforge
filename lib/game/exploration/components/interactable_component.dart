import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Type of interactable in a room.
enum InteractableType { enemy, door, shop, event, shrine }

/// State of an interactable component.
enum InteractionState {
  /// Default state - player is not near.
  idle,

  /// Player is within trigger radius, preview is shown.
  preview,

  /// Player has confirmed interaction.
  confirmed,

  /// Interactable has been completed/used.
  completed,
}

/// Base class for all room interactables.
///
/// All room objects (enemies, doors, shops, events, shrines) inherit from this.
/// Provides a unified interaction flow:
/// 1. Player enters triggerRadius → preview UI appears
/// 2. Game pauses movement (world not frozen)
/// 3. Player chooses: Confirm or Cancel
/// 4. On confirm → world transition or UI modal
abstract class InteractableComponent extends PositionComponent {
  /// Type of this interactable.
  final InteractableType type;

  /// Radius within which interaction can be triggered.
  final double triggerRadius;

  /// Current interaction state.
  InteractionState _state = InteractionState.idle;

  /// Callback when player enters trigger radius.
  final void Function(InteractableComponent)? onApproach;

  /// Callback when interaction is confirmed.
  final void Function(InteractableComponent)? onConfirm;

  /// Callback when interaction is cancelled.
  final void Function(InteractableComponent)? onCancel;

  InteractableComponent({
    required this.type,
    this.triggerRadius = 60.0,
    this.onApproach,
    this.onConfirm,
    this.onCancel,
    super.position,
    super.size,
  });

  /// Current interaction state.
  InteractionState get state => _state;

  /// Whether player is currently in preview mode.
  bool get isInPreview => _state == InteractionState.preview;

  /// Whether this interactable has been completed.
  bool get isCompleted => _state == InteractionState.completed;

  /// Whether this interactable can be interacted with.
  bool get canInteract => _state == InteractionState.idle;

  /// Preview data for the UI layer.
  /// Override in subclasses to provide specific preview information.
  Map<String, dynamic> get previewData;

  /// Called when player enters the trigger radius.
  void approach() {
    if (_state != InteractionState.idle) return;
    _state = InteractionState.preview;
    onApproach?.call(this);
    onApproachInternal();
  }

  /// Called when player confirms the interaction.
  void confirm() {
    if (_state != InteractionState.preview) return;
    _state = InteractionState.confirmed;
    onConfirm?.call(this);
    onConfirmInternal();
  }

  /// Called when player cancels/retreats.
  void cancel() {
    if (_state != InteractionState.preview) return;
    _state = InteractionState.idle;
    onCancel?.call(this);
    onCancelInternal();
  }

  /// Marks this interactable as completed.
  void complete() {
    _state = InteractionState.completed;
    onCompleteInternal();
  }

  /// Reset to idle state (for re-entry scenarios).
  void reset() {
    _state = InteractionState.idle;
    onResetInternal();
  }

  /// Check distance to a point.
  bool isWithinRange(Vector2 point) {
    return position.distanceTo(point) <= triggerRadius;
  }

  // ==================== INTERNAL HOOKS ====================
  // Override these in subclasses for specific behavior.

  /// Called internally when approached.
  @protected
  void onApproachInternal() {}

  /// Called internally when confirmed.
  @protected
  void onConfirmInternal() {}

  /// Called internally when cancelled.
  @protected
  void onCancelInternal() {}

  /// Called internally when completed.
  @protected
  void onCompleteInternal() {}

  /// Called internally when reset.
  @protected
  void onResetInternal() {}
}

/// Direction indicator for visual feedback.
mixin DirectionalIndicator on InteractableComponent {
  /// Direction this interactable is facing or pointing.
  Vector2 get facingDirection => Vector2(0, -1); // Default: up

  /// Gets the icon for this direction.
  String get directionIcon {
    if (facingDirection.y < -0.5) return '↑';
    if (facingDirection.y > 0.5) return '↓';
    if (facingDirection.x < -0.5) return '←';
    if (facingDirection.x > 0.5) return '→';
    return '•';
  }
}

/// Visual glow effect for interactables.
mixin GlowEffect on InteractableComponent {
  /// Base color for the glow.
  Color get glowColor;

  /// Current glow intensity (0.0 to 1.0).
  double _glowIntensity = 0.5;

  /// Whether glow is pulsing.
  bool _isPulsing = true;

  /// Pulse timer.
  double _pulseTimer = 0.0;

  /// Update glow effect.
  void updateGlow(double dt) {
    if (_isPulsing) {
      _pulseTimer += dt * 2.0;
      _glowIntensity = 0.4 + (0.3 * (1 + _sin(_pulseTimer)) / 2);
    }
  }

  /// Get current glow color with intensity.
  Color get currentGlowColor => glowColor.withValues(alpha: _glowIntensity);

  /// Start pulsing.
  void startPulse() => _isPulsing = true;

  /// Stop pulsing at current intensity.
  void stopPulse() => _isPulsing = false;

  /// Set fixed intensity.
  void setIntensity(double intensity) {
    _isPulsing = false;
    _glowIntensity = intensity.clamp(0.0, 1.0);
  }

  double _sin(double x) {
    // Simple sine approximation
    x = x % (3.14159 * 2);
    if (x < 0) x += 3.14159 * 2;

    // Taylor series approximation
    double x2 = x * x;
    double x3 = x2 * x;
    double x5 = x3 * x2;
    double x7 = x5 * x2;

    return x - (x3 / 6) + (x5 / 120) - (x7 / 5040);
  }
}
