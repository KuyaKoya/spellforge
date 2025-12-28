import 'director_state.dart';

/// Reason codes for Director decisions.
enum DirectorReasonCode {
  /// Player HP is consistently high
  highHp,

  /// Player HP is consistently low
  lowHp,

  /// Player clearing encounters quickly
  fastClears,

  /// Player taking many turns to clear
  slowClears,

  /// Player taking heavy damage
  heavyDamage,

  /// Player taking minimal damage
  lightDamage,

  /// Strong build detected
  strongBuild,

  /// Weak build detected
  weakBuild,

  /// Cooldown expired, returning to neutral
  cooldownExpired,

  /// Ascension rule triggered
  ascensionRule,

  /// Standard adjustment
  standardAdjustment,
}

/// Represents a single Director log entry.
class DirectorLogEntry {
  final DateTime timestamp;
  final int depth;
  final String action;
  final DirectorPressureState? fromState;
  final DirectorPressureState? toState;
  final List<DirectorReasonCode> reasons;
  final Map<String, dynamic> details;

  const DirectorLogEntry({
    required this.timestamp,
    required this.depth,
    required this.action,
    this.fromState,
    this.toState,
    this.reasons = const [],
    this.details = const {},
  });

  /// Whether this is a state change entry.
  bool get isStateChange => fromState != null && toState != null;

  /// Formats the log entry for display.
  String format() {
    final buffer = StringBuffer();
    buffer.write('[D$depth] ');

    if (isStateChange) {
      buffer.write(
        'StateChange: ${fromState!.displayName} → ${toState!.displayName}',
      );
    } else {
      buffer.write(action);
    }

    if (reasons.isNotEmpty) {
      buffer.write(' | Reasons: ');
      buffer.write(reasons.map((r) => r.name).join(', '));
    }

    if (details.isNotEmpty) {
      buffer.write(' | ');
      buffer.write(
        details.entries.map((e) => '${e.key}=${e.value}').join(', '),
      );
    }

    return buffer.toString();
  }

  @override
  String toString() => format();
}

/// Logger for Director decisions and state changes.
/// Maintains a history of all Director actions for debugging and replay.
class DirectorLogger {
  final List<DirectorLogEntry> _entries = [];

  /// Maximum number of entries to keep.
  static const int maxEntries = 100;

  /// All log entries.
  List<DirectorLogEntry> get entries => List.unmodifiable(_entries);

  /// Logs a state change.
  void logStateChange({
    required int depth,
    required DirectorPressureState fromState,
    required DirectorPressureState toState,
    required List<DirectorReasonCode> reasons,
    Map<String, dynamic>? details,
  }) {
    _addEntry(
      DirectorLogEntry(
        timestamp: DateTime.now(),
        depth: depth,
        action: 'StateChange',
        fromState: fromState,
        toState: toState,
        reasons: reasons,
        details: details ?? {},
      ),
    );
  }

  /// Logs a probability adjustment.
  void logAdjustment({
    required int depth,
    required String adjustment,
    required List<DirectorReasonCode> reasons,
    Map<String, dynamic>? details,
  }) {
    _addEntry(
      DirectorLogEntry(
        timestamp: DateTime.now(),
        depth: depth,
        action: adjustment,
        reasons: reasons,
        details: details ?? {},
      ),
    );
  }

  /// Logs a general Director action.
  void logAction({
    required int depth,
    required String action,
    Map<String, dynamic>? details,
  }) {
    _addEntry(
      DirectorLogEntry(
        timestamp: DateTime.now(),
        depth: depth,
        action: action,
        details: details ?? {},
      ),
    );
  }

  void _addEntry(DirectorLogEntry entry) {
    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
  }

  /// Gets recent entries.
  List<DirectorLogEntry> getRecent({int count = 10}) {
    final start = (_entries.length - count).clamp(0, _entries.length);
    return _entries.sublist(start);
  }

  /// Gets all state changes.
  List<DirectorLogEntry> getStateChanges() {
    return _entries.where((e) => e.isStateChange).toList();
  }

  /// Clears all entries.
  void clear() {
    _entries.clear();
  }

  /// Gets a formatted log summary.
  String getSummary() {
    if (_entries.isEmpty) return 'No Director activity logged.';

    final buffer = StringBuffer();
    buffer.writeln('=== Director Log Summary ===');
    buffer.writeln('Total Entries: ${_entries.length}');
    buffer.writeln(
      'State Changes: ${_entries.where((e) => e.isStateChange).length}',
    );
    buffer.writeln('');
    buffer.writeln('Recent Activity:');
    for (final entry in getRecent(count: 5)) {
      buffer.writeln('  ${entry.format()}');
    }
    return buffer.toString();
  }
}
