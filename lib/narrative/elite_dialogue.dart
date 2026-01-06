import 'package:flutter/foundation.dart';
import 'narrative_node.dart';

/// Elite-specific dialogue from The Director.
/// Each elite has a unique line that foreshadows their mechanics.
class EliteDialogue {
  EliteDialogue._();

  /// Gets Director dialogue for a specific elite enemy.
  /// Returns null if the elite name is not recognized.
  static NarrativeNode? getDialogueForElite({
    required String eliteName,
    VoidCallback? onComplete,
  }) {
    final dialogue = _eliteDialogues[eliteName];
    if (dialogue == null) return null;

    return NarrativeNode.director(
      id: 'elite_${eliteName.toLowerCase().replaceAll(' ', '_')}',
      pages: [dialogue],
      onComplete: onComplete,
    );
  }

  /// Dialogue table for each elite enemy.
  static const Map<String, String> _eliteDialogues = {
    // Burnward Colossus (Earth / Fire-Resistant)
    'Burnward Colossus': '''It learned long ago that flame is noise, not threat.

Break the stone — not the heat.''',

    // Tempest Twins (Air / Relentless)
    'Tempest Twins': '''They do not wait for turns.

They never learned how.''',

    // Glacial Executioner (Water / Control)
    'Glacial Executioner': '''It does not hurry.

It simply ensures you never move again.''',

    // Infernal Warlord (Fire / Adaptive)
    'Infernal Warlord': '''You repeat yourself.

And it notices.''',

    // Stone Sentinel (Earth / High Armor)
    'Stone Sentinel': '''Endurance is its only answer.

Make sure you ask the right question.''',

    // Typhoon Herald (Air / Aggressive)
    'Typhoon Herald': '''Speed is a mercy.

It offers none.''',
  };

  /// Gets all elite names that have dialogue.
  static List<String> get allEliteNames => _eliteDialogues.keys.toList();

  /// Checks if an elite has dialogue defined.
  static bool hasDialogue(String eliteName) =>
      _eliteDialogues.containsKey(eliteName);
}
