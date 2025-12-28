/// Lore fragments that can be discovered throughout Act 1.
/// These are short, fragmentary, archival in tone.
/// They hint at the world, the loop, and the nature of Exodia.
class LoreFragment {
  final String id;
  final String title;
  final String content;
  final String source;
  final LoreCategory category;

  const LoreFragment({
    required this.id,
    required this.title,
    required this.content,
    required this.source,
    required this.category,
  });

  @override
  String toString() => '[$source] $title';
}

/// Categories of lore fragments.
enum LoreCategory {
  world, // About Exodia
  loop, // About the cycle
  threshold, // About Act 1 / the test
  relics, // About items and artifacts
  gatekeepers; // About the Twin Gatekeepers

  String get displayName {
    switch (this) {
      case LoreCategory.world:
        return 'Exodia';
      case LoreCategory.loop:
        return 'The Loop';
      case LoreCategory.threshold:
        return 'The Threshold';
      case LoreCategory.relics:
        return 'Artifacts';
      case LoreCategory.gatekeepers:
        return 'Gatekeepers';
    }
  }
}

/// Collection of all Act 1 lore fragments.
class LoreFragments {
  LoreFragments._();

  // ==================== WORLD LORE ====================

  static const worldFragments = [
    LoreFragment(
      id: 'world_01',
      title: 'On Exodia',
      content: 'The world has a name. Or did. Now it simply is.',
      source: 'Unmarked Stone',
      category: LoreCategory.world,
    ),
    LoreFragment(
      id: 'world_02',
      title: 'The Watcher',
      content: 'Something observes. It does not interfere. It notes.',
      source: 'Scratched Wall',
      category: LoreCategory.world,
    ),
    LoreFragment(
      id: 'world_03',
      title: 'Empty Halls',
      content:
          'The architecture suggests purpose. The emptiness suggests otherwise.',
      source: 'Crumbled Archway',
      category: LoreCategory.world,
    ),
  ];

  // ==================== LOOP LORE ====================

  static const loopFragments = [
    LoreFragment(
      id: 'loop_01',
      title: 'Again',
      content: 'Time moves. Memory does not. Or is it the reverse?',
      source: 'Faded Journal',
      category: LoreCategory.loop,
    ),
    LoreFragment(
      id: 'loop_02',
      title: 'Recognition',
      content: 'You have held this object. You do not remember.',
      source: 'Worn Handle',
      category: LoreCategory.loop,
    ),
    LoreFragment(
      id: 'loop_03',
      title: 'Counting',
      content: 'Someone kept count. The marks stopped at an unreadable number.',
      source: 'Prison Wall',
      category: LoreCategory.loop,
    ),
  ];

  // ==================== THRESHOLD LORE ====================

  static const thresholdFragments = [
    LoreFragment(
      id: 'threshold_01',
      title: 'The Test',
      content: 'The threshold does not welcome. It filters.',
      source: 'Stone Tablet',
      category: LoreCategory.threshold,
    ),
    LoreFragment(
      id: 'threshold_02',
      title: 'Purpose',
      content:
          'Not all who enter are meant to proceed. Most are meant to return.',
      source: 'Worn Inscription',
      category: LoreCategory.threshold,
    ),
    LoreFragment(
      id: 'threshold_03',
      title: 'Persistence',
      content: 'The unready persist. The ready vanish. Which is the victory?',
      source: 'Broken Statue Base',
      category: LoreCategory.threshold,
    ),
  ];

  // ==================== RELIC LORE ====================

  static const relicFragments = [
    LoreFragment(
      id: 'relic_01',
      title: 'Echoes',
      content: 'Objects persist. Their owners do not.',
      source: 'Empty Display',
      category: LoreCategory.relics,
    ),
    LoreFragment(
      id: 'relic_02',
      title: 'Pairs',
      content:
          'Some things belong together. Finding both is rare. Keeping both is rarer.',
      source: 'Matching Pedestals',
      category: LoreCategory.relics,
    ),
    LoreFragment(
      id: 'relic_03',
      title: 'Cost',
      content: 'Every gift is borrowed. Every power is temporary.',
      source: 'Offering Bowl',
      category: LoreCategory.relics,
    ),
  ];

  // ==================== GATEKEEPER LORE ====================

  static const gatekeeperFragments = [
    LoreFragment(
      id: 'gatekeeper_01',
      title: 'Twins',
      content: 'Two stand at the end. They do not speak. They do not need to.',
      source: 'Etched Doorframe',
      category: LoreCategory.gatekeepers,
    ),
    LoreFragment(
      id: 'gatekeeper_02',
      title: 'Opposition',
      content: 'Fire and Water. Earth and Air. Complete in opposition.',
      source: 'Ritual Circle',
      category: LoreCategory.gatekeepers,
    ),
    LoreFragment(
      id: 'gatekeeper_03',
      title: 'Duty',
      content: 'They were not born. They were placed. They do not tire.',
      source: 'Ancient Record',
      category: LoreCategory.gatekeepers,
    ),
  ];

  /// All fragments combined.
  static List<LoreFragment> get allFragments => [
    ...worldFragments,
    ...loopFragments,
    ...thresholdFragments,
    ...relicFragments,
    ...gatekeeperFragments,
  ];

  /// Gets a fragment by ID.
  static LoreFragment? getById(String id) {
    try {
      return allFragments.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Gets random fragments for a run.
  static List<LoreFragment> getRunFragments(int seed, {int count = 3}) {
    final shuffled = List<LoreFragment>.from(allFragments);
    shuffled.shuffle();
    return shuffled.take(count).toList();
  }
}
