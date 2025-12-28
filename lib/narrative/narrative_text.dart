import 'director_lines.dart';
import 'lore_fragments.dart';

/// Narrative text presentation rules and content.
/// Handles the centered, focused display of narrative between nodes.
class NarrativeText {
  NarrativeText._();

  /// Duration for fade-in animation (no typewriter effect).
  static const Duration fadeInDuration = Duration(milliseconds: 800);

  /// Duration narrative text stays on screen.
  static const Duration displayDuration = Duration(seconds: 3);

  /// Gets narrative text for run entry.
  static NarrativeBlock getEntryNarrative(int runNumber) {
    final directorLine = DirectorLines.getEntryLine(runNumber);

    return NarrativeBlock(
      type: NarrativeType.entry,
      lines: ['The Threshold.', '', directorLine],
      directorLine: directorLine,
    );
  }

  /// Gets narrative text for node transitions (used rarely).
  static NarrativeBlock? getTransitionNarrative(int depth, int seed) {
    // Only show transition narrative at certain depths
    if (depth != 3 && depth != 6 && depth != 9) return null;

    return NarrativeBlock(
      type: NarrativeType.transition,
      lines: [DirectorLines.getLine(DirectorLines.transitionLines, seed)],
    );
  }

  /// Gets narrative text for boss approach.
  static NarrativeBlock getBossApproachNarrative(int runNumber) {
    return NarrativeBlock(
      type: NarrativeType.bossApproach,
      lines: [
        'The path ends here.',
        '',
        'Two figures stand in silence.',
        '',
        DirectorLines.getLine(DirectorLines.bossApproachLines, runNumber),
      ],
    );
  }

  /// Gets narrative text for victory ending.
  static NarrativeBlock getVictoryEndingNarrative(int runNumber) {
    return NarrativeBlock(
      type: NarrativeType.victoryEnding,
      lines: [
        'The Gatekeepers fall.',
        '',
        'The threshold yields.',
        '',
        'And yet—',
        '',
        'The path continues.',
        '',
        DirectorLines.getLine(DirectorLines.victoryEndingLines, runNumber),
      ],
    );
  }

  /// Gets narrative text for defeat ending.
  static NarrativeBlock getDefeatEndingNarrative(int runNumber, int depth) {
    final lines = <String>['Darkness.', ''];

    if (depth <= 3) {
      lines.add(
        DirectorLines.getLine(DirectorLines.earlyDeathLines, runNumber),
      );
    } else {
      lines.add(
        DirectorLines.getLine(DirectorLines.defeatEndingLines, runNumber),
      );
    }

    lines.addAll(['', 'The loop continues.']);

    return NarrativeBlock(type: NarrativeType.defeatEnding, lines: lines);
  }

  /// Gets narrative text for lore fragment discovery.
  static NarrativeBlock getLoreDiscoveryNarrative(LoreFragment fragment) {
    return NarrativeBlock(
      type: NarrativeType.loreDiscovery,
      lines: [fragment.content, '', '— ${fragment.source}'],
    );
  }

  /// Gets narrative text for relic discovery.
  static NarrativeBlock getRelicDiscoveryNarrative(
    String relicName,
    String lore,
  ) {
    return NarrativeBlock(
      type: NarrativeType.relicDiscovery,
      lines: [relicName, '', lore],
    );
  }
}

/// A block of narrative text to be displayed.
class NarrativeBlock {
  final NarrativeType type;
  final List<String> lines;
  final String? directorLine;
  final LoreFragment? loreFragment;

  const NarrativeBlock({
    required this.type,
    required this.lines,
    this.directorLine,
    this.loreFragment,
  });

  /// Combines all lines into a single string.
  String get fullText => lines.join('\n');

  /// Whether this narrative should darken the background.
  bool get shouldDarkenBackground =>
      type == NarrativeType.entry ||
      type == NarrativeType.bossApproach ||
      type == NarrativeType.victoryEnding ||
      type == NarrativeType.defeatEnding;

  /// Whether this narrative should pause gameplay.
  bool get shouldPauseGameplay =>
      type == NarrativeType.entry || type == NarrativeType.bossApproach;
}

/// Types of narrative text blocks.
enum NarrativeType {
  entry, // Beginning of a run
  transition, // Between nodes
  bossApproach, // Before Twin Gatekeepers
  victoryEnding, // After defeating Gatekeepers
  defeatEnding, // After player death
  loreDiscovery, // Finding a lore fragment
  relicDiscovery; // Finding a relic

  String get debugName {
    switch (this) {
      case NarrativeType.entry:
        return 'Entry';
      case NarrativeType.transition:
        return 'Transition';
      case NarrativeType.bossApproach:
        return 'Boss Approach';
      case NarrativeType.victoryEnding:
        return 'Victory Ending';
      case NarrativeType.defeatEnding:
        return 'Defeat Ending';
      case NarrativeType.loreDiscovery:
        return 'Lore Discovery';
      case NarrativeType.relicDiscovery:
        return 'Relic Discovery';
    }
  }
}
