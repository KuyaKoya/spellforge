import 'package:flutter/material.dart';

/// A1.1 Interaction affordance - pulsing glow animation for interactables.
/// All interactable objects must expose one visual affordance.
/// Affordance disappears after first interaction (per run).
class InteractionAffordance extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final bool showAffordance;
  final double intensity;
  final Duration pulseDuration;

  const InteractionAffordance({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFF58a6ff),
    this.showAffordance = true,
    this.intensity = 1.0,
    this.pulseDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<InteractionAffordance> createState() => _InteractionAffordanceState();
}

class _InteractionAffordanceState extends State<InteractionAffordance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.pulseDuration,
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAffordance) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(
                  alpha: _pulseAnimation.value * widget.intensity,
                ),
                blurRadius: 16 * _pulseAnimation.value,
                spreadRadius: 4 * _pulseAnimation.value,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Pulsing outline decoration for enemy interaction affordance.
class EnemyAffordanceDecoration extends StatefulWidget {
  final Widget child;
  final bool showAffordance;

  const EnemyAffordanceDecoration({
    super.key,
    required this.child,
    this.showAffordance = true,
  });

  @override
  State<EnemyAffordanceDecoration> createState() =>
      _EnemyAffordanceDecorationState();
}

class _EnemyAffordanceDecorationState extends State<EnemyAffordanceDecoration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAffordance) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(
                0xFFf85149,
              ).withValues(alpha: _pulseAnimation.value * 0.8),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFf85149,
                ).withValues(alpha: _pulseAnimation.value * 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Directional arrow icon for door affordance.
class DoorAffordanceIcon extends StatefulWidget {
  final DoorDirection direction;
  final bool showAffordance;

  const DoorAffordanceIcon({
    super.key,
    this.direction = DoorDirection.north,
    this.showAffordance = true,
  });

  @override
  State<DoorAffordanceIcon> createState() => _DoorAffordanceIconState();
}

class _DoorAffordanceIconState extends State<DoorAffordanceIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData get _arrowIcon {
    switch (widget.direction) {
      case DoorDirection.north:
        return Icons.arrow_upward;
      case DoorDirection.south:
        return Icons.arrow_downward;
      case DoorDirection.east:
        return Icons.arrow_forward;
      case DoorDirection.west:
        return Icons.arrow_back;
    }
  }

  Offset get _bounceOffset {
    switch (widget.direction) {
      case DoorDirection.north:
        return Offset(0, -_bounceAnimation.value);
      case DoorDirection.south:
        return Offset(0, _bounceAnimation.value);
      case DoorDirection.east:
        return Offset(_bounceAnimation.value, 0);
      case DoorDirection.west:
        return Offset(-_bounceAnimation.value, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAffordance) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: _bounceOffset,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF58a6ff).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF58a6ff).withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(_arrowIcon, color: Colors.white, size: 20),
          ),
        );
      },
    );
  }
}

/// Floating icon for shop/event affordance.
class FloatingAffordanceIcon extends StatefulWidget {
  final String icon;
  final bool showAffordance;
  final Color iconColor;

  const FloatingAffordanceIcon({
    super.key,
    required this.icon,
    this.showAffordance = true,
    this.iconColor = const Color(0xFFe3b341),
  });

  @override
  State<FloatingAffordanceIcon> createState() => _FloatingAffordanceIconState();
}

class _FloatingAffordanceIconState extends State<FloatingAffordanceIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(
      begin: 0.0,
      end: 6.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAffordance) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_floatAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF21262d),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.iconColor.withValues(alpha: 0.7),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.iconColor.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(widget.icon, style: const TextStyle(fontSize: 20)),
          ),
        );
      },
    );
  }
}

enum DoorDirection { north, south, east, west }
