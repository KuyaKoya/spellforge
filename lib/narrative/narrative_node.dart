import 'package:flutter/foundation.dart';

/// Represents a single narrative node with speaker and content pages.
class NarrativeNode {
  /// Unique identifier for this narrative node.
  final String id;

  /// Speaker name (e.g., "The Director", "World", null for silent narration).
  final String? speaker;

  /// Pages of text to display. Each page is shown sequentially with tap-to-advance.
  final List<String> pages;

  /// Optional callback to execute when narrative completes.
  final VoidCallback? onComplete;

  const NarrativeNode({
    required this.id,
    this.speaker,
    required this.pages,
    this.onComplete,
  });

  /// Creates a narrative node from a single page of text.
  factory NarrativeNode.single({
    required String id,
    String? speaker,
    required String text,
    VoidCallback? onComplete,
  }) {
    return NarrativeNode(
      id: id,
      speaker: speaker,
      pages: [text],
      onComplete: onComplete,
    );
  }

  /// Creates a Director dialogue node (speaker auto-set).
  factory NarrativeNode.director({
    required String id,
    required List<String> pages,
    VoidCallback? onComplete,
  }) {
    return NarrativeNode(
      id: id,
      speaker: 'The Director',
      pages: pages,
      onComplete: onComplete,
    );
  }

  /// Creates a world/lore narration node (no speaker).
  factory NarrativeNode.worldNarration({
    required String id,
    required List<String> pages,
    VoidCallback? onComplete,
  }) {
    return NarrativeNode(
      id: id,
      speaker: null,
      pages: pages,
      onComplete: onComplete,
    );
  }

  /// Whether this narrative has multiple pages.
  bool get hasMultiplePages => pages.length > 1;

  /// Total number of pages.
  int get pageCount => pages.length;
}
