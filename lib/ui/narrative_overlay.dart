import 'package:flutter/material.dart';
import '../narrative/narrative_node.dart' as narrative;
import '../systems/audio_manager.dart';

/// Fullscreen narrative overlay with tap-to-advance functionality.
///
/// This widget displays narrative content (lore, dialogue) in a fullscreen
/// overlay that pauses gameplay, ducks background audio, and allows the
/// player to tap to advance through pages.
class NarrativeOverlay extends StatefulWidget {
  /// The narrative content to display.
  final narrative.NarrativeNode narrativeNode;

  /// Callback when the narrative sequence completes.
  final VoidCallback? onComplete;

  /// Whether to show a fade-in animation.
  final bool showFadeIn;

  /// Background image path (optional).
  final String? backgroundImage;

  const NarrativeOverlay({
    super.key,
    required this.narrativeNode,
    this.onComplete,
    this.showFadeIn = true,
    this.backgroundImage,
  });

  @override
  State<NarrativeOverlay> createState() => _NarrativeOverlayState();
}

class _NarrativeOverlayState extends State<NarrativeOverlay>
    with SingleTickerProviderStateMixin {
  int _currentPageIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Duck background audio when narrative appears
    AudioManager().duckBackgroundMusic();

    // Setup fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    if (widget.showFadeIn) {
      _fadeController.forward();
    } else {
      _fadeController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    // Restore background audio when narrative closes
    AudioManager().restoreBackgroundMusic();
    super.dispose();
  }

  void _advancePage() {
    if (_currentPageIndex < widget.narrativeNode.pageCount - 1) {
      setState(() {
        _currentPageIndex++;
      });
    } else {
      _closeNarrative();
    }
  }

  void _closeNarrative() async {
    // Fade out
    await _fadeController.reverse();

    // Notify completion
    widget.narrativeNode.onComplete?.call();
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = widget.narrativeNode.pages[_currentPageIndex];
    final isLastPage = _currentPageIndex == widget.narrativeNode.pageCount - 1;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: _advancePage,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withValues(alpha: 0.95),
          child: Stack(
            children: [
              // Optional background image
              if (widget.backgroundImage != null)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.15,
                    child: Image.asset(
                      widget.backgroundImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // Content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Speaker header (if present)
                      if (widget.narrativeNode.speaker != null) ...[
                        Text(
                          widget.narrativeNode.speaker!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: Colors.amber.shade400,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Narrative text
                      Text(
                        currentPage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20,
                          height: 1.8,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Tap indicator
                      _buildTapIndicator(isLastPage),

                      // Page indicator (if multiple pages)
                      if (widget.narrativeNode.hasMultiplePages) ...[
                        const SizedBox(height: 24),
                        _buildPageIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTapIndicator(bool isLastPage) {
    return AnimatedOpacity(
      opacity: 0.6,
      duration: const Duration(milliseconds: 800),
      child: Text(
        isLastPage ? 'Tap to close' : 'Tap to continue',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: Colors.grey.shade500,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.narrativeNode.pageCount,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentPageIndex
                ? Colors.amber.shade400
                : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
