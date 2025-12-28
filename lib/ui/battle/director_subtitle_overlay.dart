import 'package:flutter/material.dart';

/// Director subtitle overlay (Bottom-Center).
///
/// Rules (LOCKED):
/// - Auto-fade
/// - Never blocks input
/// - One line only
/// - Small, muted text
class DirectorSubtitleOverlay extends StatefulWidget {
  final String message;
  final Duration fadeInDuration;
  final Duration displayDuration;
  final Duration fadeOutDuration;

  const DirectorSubtitleOverlay({
    super.key,
    required this.message,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.displayDuration = const Duration(seconds: 2),
    this.fadeOutDuration = const Duration(milliseconds: 500),
  });

  @override
  State<DirectorSubtitleOverlay> createState() =>
      _DirectorSubtitleOverlayState();
}

class _DirectorSubtitleOverlayState extends State<DirectorSubtitleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    final totalDuration =
        widget.fadeInDuration + widget.displayDuration + widget.fadeOutDuration;

    _controller = AnimationController(duration: totalDuration, vsync: this);

    // Calculate fade timing
    final fadeInEnd =
        widget.fadeInDuration.inMilliseconds / totalDuration.inMilliseconds;
    final fadeOutStart =
        1.0 -
        (widget.fadeOutDuration.inMilliseconds / totalDuration.inMilliseconds);

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: fadeInEnd * 100,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: (fadeOutStart - fadeInEnd) * 100,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: (1.0 - fadeOutStart) * 100,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // Never blocks input - LOCKED
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(opacity: _fadeAnimation.value, child: child);
        },
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0d1117).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.message,
              style: TextStyle(
                fontFamily:
                    'Georgia', // Serif for Director - matches Journey Log
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade500, // Muted - LOCKED
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1, // One line only - LOCKED
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
