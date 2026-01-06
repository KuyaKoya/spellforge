import 'package:flutter/foundation.dart';
import 'narrative_node.dart';

/// Boss narrative for Act 1 Gatekeepers.
class BossNarrative {
  BossNarrative._();

  /// Pre-fight narrative shared by both gatekeepers.
  static NarrativeNode getPreFightNarrative({VoidCallback? onComplete}) {
    return NarrativeNode.director(
      id: 'boss_pre_fight',
      pages: [
        '''You have reached the gate.

Not an ending.

A filter.''',
      ],
      onComplete: onComplete,
    );
  }

  /// Boss-specific commentary by name.
  static NarrativeNode? getBossSpecificNarrative({
    required String bossName,
    VoidCallback? onComplete,
  }) {
    final dialogue = _bossDialogues[bossName];
    if (dialogue == null) return null;

    return NarrativeNode.director(
      id: 'boss_${bossName.toLowerCase().replaceAll(' ', '_')}',
      pages: [dialogue],
      onComplete: onComplete,
    );
  }

  /// Post-victory narrative.
  static NarrativeNode getPostVictoryNarrative({VoidCallback? onComplete}) {
    return NarrativeNode.director(
      id: 'boss_post_victory',
      pages: [
        '''Interesting.

You passed.

Most do not.''',
      ],
      onComplete: onComplete,
    );
  }

  /// Boss-specific dialogue.
  static const Map<String, String> _bossDialogues = {
    'Gatekeeper of Pyre': '''This one does not burn.

It endures.''',

    'Gatekeeper of Tide': '''This one does not slow.

It overwhelms.''',
  };

  /// Gets all boss names that have dialogue.
  static List<String> get allBossNames => _bossDialogues.keys.toList();

  /// Checks if a boss has dialogue defined.
  static bool hasDialogue(String bossName) =>
      _bossDialogues.containsKey(bossName);
}
