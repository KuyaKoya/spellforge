import 'package:flutter/material.dart';
import '../../narrative/narrative_text.dart';

/// Narrative text display widget.
/// Shows narrative text between nodes, at milestones, and after boss encounters.
///
/// UI Rules:
/// - Centered or isolated text blocks
/// - Darkened background or focus mode
/// - No UI clutter during narration
///
/// Animation:
/// - Slow fade-in
/// - No typewriter effect (avoid theatrics)
class NarrativeDisplay extends StatefulWidget {
  final NarrativeBlock narrative;
  final VoidCallback? onComplete;
  final bool autoAdvance;
  final Duration autoAdvanceDelay;

  const NarrativeDisplay({
    super.key,
    required this.narrative,
    this.onComplete,
    this.autoAdvance = false,
    this.autoAdvanceDelay = const Duration(seconds: 3),
  });

  @override
  State<NarrativeDisplay> createState() => _NarrativeDisplayState();
}

class _NarrativeDisplayState extends State<NarrativeDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: NarrativeText.fadeInDuration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _fadeController.forward();

    if (widget.autoAdvance) {
      Future.delayed(
        NarrativeText.fadeInDuration + widget.autoAdvanceDelay,
        () {
          if (mounted && widget.onComplete != null) {
            widget.onComplete!();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onComplete,
          child: Container(
            color: widget.narrative.shouldDarkenBackground
                ? Colors.black.withValues(alpha: _backgroundAnimation.value)
                : Colors.transparent,
            child: Center(
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: _buildContent(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.narrative.lines.asMap().entries.map((entry) {
          final index = entry.key;
          final line = entry.value;

          // Staggered fade for each line
          final lineDelay = index * 0.1;
          final lineOpacity =
              ((_fadeAnimation.value - lineDelay) / (1 - lineDelay)).clamp(
                0.0,
                1.0,
              );

          if (line.isEmpty) {
            return const SizedBox(height: 24);
          }

          return Opacity(
            opacity: lineOpacity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                line,
                textAlign: TextAlign.center,
                style: _getTextStyle(line),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  TextStyle _getTextStyle(String line) {
    // Director lines are styled differently
    if (widget.narrative.directorLine == line) {
      return TextStyle(
        fontFamily: 'monospace',
        fontSize: 16,
        color: Colors.purple.shade300,
        fontStyle: FontStyle.italic,
        letterSpacing: 2,
        height: 1.5,
      );
    }

    // Default narrative style
    return TextStyle(
      fontFamily: 'monospace',
      fontSize: 18,
      color: Colors.grey.shade300,
      letterSpacing: 1,
      height: 1.6,
    );
  }
}

/// Overlay wrapper for narrative display.
/// Can be shown as a full-screen overlay without navigation.
class NarrativeOverlay extends StatelessWidget {
  final NarrativeBlock narrative;
  final VoidCallback onDismiss;

  const NarrativeOverlay({
    super.key,
    required this.narrative,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: NarrativeDisplay(narrative: narrative, onComplete: onDismiss),
      ),
    );
  }
}

/// Controller for managing narrative displays.
class NarrativeController extends ChangeNotifier {
  NarrativeBlock? _currentNarrative;
  bool _isDisplaying = false;

  NarrativeBlock? get currentNarrative => _currentNarrative;
  bool get isDisplaying => _isDisplaying;

  void showNarrative(NarrativeBlock narrative) {
    _currentNarrative = narrative;
    _isDisplaying = true;
    notifyListeners();
  }

  void dismiss() {
    _isDisplaying = false;
    _currentNarrative = null;
    notifyListeners();
  }
}
