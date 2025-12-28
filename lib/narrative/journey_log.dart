import 'lore_fragments.dart';

/// A single entry in the Journey Log.
/// Can be a lore fragment, Director observation, or relic description.
class JourneyEntry {
  final String id;
  final JourneyEntryType type;
  final String title;
  final String content;
  final String? source;
  final int runNumber;
  final int depth;
  final DateTime timestamp;

  JourneyEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.source,
    required this.runNumber,
    required this.depth,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates an entry from a lore fragment.
  factory JourneyEntry.fromLoreFragment(
    LoreFragment fragment, {
    required int runNumber,
    required int depth,
  }) {
    return JourneyEntry(
      id: 'lore_${fragment.id}_r${runNumber}_d$depth',
      type: JourneyEntryType.lore,
      title: fragment.title,
      content: fragment.content,
      source: fragment.source,
      runNumber: runNumber,
      depth: depth,
    );
  }

  /// Creates an entry from a Director observation.
  factory JourneyEntry.fromDirectorLine(
    String line, {
    required int runNumber,
    required int depth,
  }) {
    return JourneyEntry(
      id: 'director_r${runNumber}_d$depth',
      type: JourneyEntryType.director,
      title: 'The Director',
      content: line,
      source: 'Observation',
      runNumber: runNumber,
      depth: depth,
    );
  }

  /// Creates an entry from a relic discovery.
  factory JourneyEntry.fromRelicDiscovery(
    String relicName,
    String relicLore, {
    required int runNumber,
    required int depth,
  }) {
    return JourneyEntry(
      id: 'relic_${relicName}_r${runNumber}_d$depth',
      type: JourneyEntryType.relic,
      title: relicName,
      content: relicLore,
      source: 'Artifact',
      runNumber: runNumber,
      depth: depth,
    );
  }

  /// Display format for the journey log.
  String get displayText {
    final buffer = StringBuffer();
    buffer.writeln('─── $title ───');
    buffer.writeln(content);
    if (source != null) {
      buffer.writeln('— $source');
    }
    return buffer.toString();
  }

  @override
  String toString() => '[$type] $title: $content';
}

/// Types of journey log entries.
enum JourneyEntryType {
  lore, // Lore fragments discovered
  director, // Director observations
  relic, // Relic discoveries
  milestone; // Major events (boss defeat, act completion)

  String get displayName {
    switch (this) {
      case JourneyEntryType.lore:
        return 'Lore';
      case JourneyEntryType.director:
        return 'Observation';
      case JourneyEntryType.relic:
        return 'Artifact';
      case JourneyEntryType.milestone:
        return 'Milestone';
    }
  }

  String get icon {
    switch (this) {
      case JourneyEntryType.lore:
        return '📜';
      case JourneyEntryType.director:
        return '👁️';
      case JourneyEntryType.relic:
        return '🔮';
      case JourneyEntryType.milestone:
        return '⭐';
    }
  }
}

/// The Journey Log - persistent record of discovered lore and observations.
/// Read-only, chronological, accessible from pause or side panel.
class JourneyLog {
  /// All entries across all runs, persisted.
  final List<JourneyEntry> _allEntries = [];

  /// Entries from the current run only.
  final List<JourneyEntry> _currentRunEntries = [];

  /// Current run number.
  int _currentRun = 0;

  /// All entries (read-only).
  List<JourneyEntry> get allEntries => List.unmodifiable(_allEntries);

  /// Current run entries (read-only).
  List<JourneyEntry> get currentRunEntries =>
      List.unmodifiable(_currentRunEntries);

  /// Unique lore fragments discovered (for collection tracking).
  Set<String> get discoveredLoreIds {
    return _allEntries
        .where((e) => e.type == JourneyEntryType.lore)
        .map((e) => e.id.split('_r').first.replaceFirst('lore_', ''))
        .toSet();
  }

  /// Starts a new run.
  void startNewRun(int runNumber) {
    _currentRun = runNumber;
    _currentRunEntries.clear();
  }

  /// Adds an entry.
  void addEntry(JourneyEntry entry) {
    _allEntries.add(entry);
    if (entry.runNumber == _currentRun) {
      _currentRunEntries.add(entry);
    }
  }

  /// Adds a lore fragment discovery.
  void addLoreFragment(LoreFragment fragment, {required int depth}) {
    addEntry(
      JourneyEntry.fromLoreFragment(
        fragment,
        runNumber: _currentRun,
        depth: depth,
      ),
    );
  }

  /// Adds a Director observation.
  void addDirectorLine(String line, {required int depth}) {
    addEntry(
      JourneyEntry.fromDirectorLine(line, runNumber: _currentRun, depth: depth),
    );
  }

  /// Adds a relic discovery.
  void addRelicDiscovery(
    String relicName,
    String relicLore, {
    required int depth,
  }) {
    addEntry(
      JourneyEntry.fromRelicDiscovery(
        relicName,
        relicLore,
        runNumber: _currentRun,
        depth: depth,
      ),
    );
  }

  /// Adds a milestone.
  void addMilestone(String title, String description, {required int depth}) {
    addEntry(
      JourneyEntry(
        id: 'milestone_${title}_r${_currentRun}_d$depth',
        type: JourneyEntryType.milestone,
        title: title,
        content: description,
        runNumber: _currentRun,
        depth: depth,
      ),
    );
  }

  /// Gets entries by type.
  List<JourneyEntry> getEntriesByType(JourneyEntryType type) {
    return _allEntries.where((e) => e.type == type).toList();
  }

  /// Gets the last N entries.
  List<JourneyEntry> getRecentEntries({int count = 10}) {
    final start = (_allEntries.length - count).clamp(0, _allEntries.length);
    return _allEntries.sublist(start);
  }

  /// Clears log (for testing or reset).
  void clear() {
    _allEntries.clear();
    _currentRunEntries.clear();
  }

  /// Gets discovery percentage for lore.
  double get loreDiscoveryPercentage {
    final total = LoreFragments.allFragments.length;
    final discovered = discoveredLoreIds.length;
    return discovered / total;
  }
}
