/// Director dialogue lines for Act 1.
/// The Director speaks sparingly, never explains mechanics,
/// reacts to performance with cold, observational, unemotional tone.
/// The Director should feel present, not frequent.
class DirectorLines {
  DirectorLines._();

  // ==================== ENTRY LINES ====================

  /// Lines spoken at the very beginning of a run.
  static const List<String> entryLines = [
    'Another arrives.',
    'The threshold awaits.',
    'You have been here before.',
    'Exodia observes.',
    'The loop begins again.',
  ];

  // ==================== OBSERVATION LINES ====================

  /// Lines based on player performance (neutral).
  static const List<String> neutralObservations = [
    'Adequate.',
    'Noted.',
    'Continue.',
    'The path remains.',
    'Progress. Of a sort.',
  ];

  /// Lines when player is performing well (aggressive pressure).
  static const List<String> dominatingObservations = [
    'Confidence. Interesting.',
    'You believe this is mastery.',
    'The threshold is not so easily passed.',
    'Speed without caution.',
    'How many times have you felt this certain?',
  ];

  /// Lines when player is struggling (merciful pressure).
  static const List<String> strugglingObservations = [
    'Persistence. Or futility.',
    'The loop does not judge.',
    'Rest is an illusion here.',
    'You have fallen before. You will fall again.',
    'Exodia watches. Nothing more.',
  ];

  // ==================== COMBAT LINES ====================

  /// Lines at the start of combat.
  static const List<String> combatStartLines = [
    'They do not remember you.',
    'Familiar ground.',
    'Again.',
  ];

  /// Lines on decisive victory (quick/no damage taken).
  static const List<String> decisiveVictoryLines = [
    'Swift. Expected.',
    'Efficiency. For now.',
    'The Gatekeepers will not be so easily dismissed.',
  ];

  /// Lines on close victory (low HP remaining).
  static const List<String> closeVictoryLines = [
    'Survival. Nothing more.',
    'That was closer than you think.',
    'The pattern holds. Barely.',
  ];

  /// Lines on taking heavy damage.
  static const List<String> heavyDamageLines = [
    'Pain teaches. Sometimes.',
    'You have learned this lesson before.',
    'The threshold demands more.',
  ];

  // ==================== RELIC DISCOVERY LINES ====================

  /// Lines when discovering a relic.
  static const List<String> relicDiscoveryLines = [
    'A fragment of what was.',
    'You recognize this.',
    'Power. With a cost.',
    'The loop leaves traces.',
  ];

  /// Lines when completing a relic set.
  static const List<String> setCompletionLines = [
    'The pieces align. For now.',
    'Completion is not the same as understanding.',
    'You have held these before.',
  ];

  // ==================== NODE TRANSITION LINES ====================

  /// Lines between nodes (rare).
  static const List<String> transitionLines = [
    'Forward.',
    'The path narrows.',
    'Closer.',
  ];

  // ==================== BOSS APPROACH LINES ====================

  /// Lines when approaching the Twin Gatekeepers.
  static const List<String> bossApproachLines = [
    'The Gatekeepers await.',
    'They have ended this before.',
    'The threshold tests. Always.',
    'You are not ready. But you will try.',
  ];

  // ==================== ENDING LINES ====================

  /// Lines after defeating the Gatekeepers (loop continues).
  static const List<String> victoryEndingLines = [
    'The threshold yields. For now.',
    'You have passed. Again.',
    'Progress? Or repetition?',
    'The loop continues.',
    'Exodia notes your passage.',
  ];

  /// Lines after defeat.
  static const List<String> defeatEndingLines = [
    'The pattern holds.',
    'You will return.',
    'The threshold remains.',
    'Another attempt. In time.',
    'Rest. Then begin again.',
  ];

  // ==================== SPECIAL CONDITION LINES ====================

  /// Lines on player death at low depth (quick failure).
  static const List<String> earlyDeathLines = [
    'Brief.',
    'The threshold is not so forgiving.',
    'You have learned nothing.',
  ];

  /// Lines on long run survival.
  static const List<String> longSurvivalLines = [
    'Persistence. Or stubbornness.',
    'The loop rewards nothing but continuation.',
    'You believe you are progressing.',
  ];

  // ==================== LINE SELECTION ====================

  /// Gets a random line from a list using a seed.
  static String getLine(List<String> lines, int seed) {
    return lines[seed % lines.length];
  }

  /// Gets an entry line for run start.
  static String getEntryLine(int runNumber) {
    return getLine(entryLines, runNumber);
  }

  /// Gets an observation based on pressure state.
  static String getObservation(String pressureState, int seed) {
    switch (pressureState) {
      case 'aggressive':
        return getLine(dominatingObservations, seed);
      case 'merciful':
        return getLine(strugglingObservations, seed);
      default:
        return getLine(neutralObservations, seed);
    }
  }
}
