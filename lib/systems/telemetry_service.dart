import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local telemetry service for game balance metrics.
/// A5 Spec: Tracks turns per battle, damage taken, spell usage, death cause.
/// Stored locally as JSON.
class TelemetryService {
  static TelemetryService? _instance;
  static TelemetryService get instance => _instance ??= TelemetryService._();

  static const String _storageKey = 'spellforge_telemetry';

  TelemetryService._();

  // Current combat session data
  CombatTelemetry? _currentCombat;

  // Run session data
  RunTelemetry? _currentRun;

  // Aggregated data
  final List<RunTelemetry> _completedRuns = [];

  /// Starts tracking a new run.
  void startRun({required String mageId, required String startingElement}) {
    _currentRun = RunTelemetry(
      runId: DateTime.now().millisecondsSinceEpoch.toString(),
      mageId: mageId,
      startingElement: startingElement,
      startTime: DateTime.now(),
    );
  }

  /// Starts tracking a new combat encounter.
  void startCombat({
    required List<String> enemyIds,
    required int playerHP,
    required int playerMaxHP,
    required int depth,
    bool isElite = false,
  }) {
    _currentCombat = CombatTelemetry(
      encounterNumber: (_currentRun?.combatCount ?? 0) + 1,
      enemyIds: enemyIds,
      playerStartingHP: playerHP,
      playerMaxHP: playerMaxHP,
      depth: depth,
      isElite: isElite,
      startTime: DateTime.now(),
    );
  }

  /// Records a spell being cast.
  void recordSpellCast({
    required String spellId,
    required String spellElement,
    required int damage,
    required int manaCost,
  }) {
    if (_currentCombat == null) return;

    _currentCombat!.spellsCast.add(
      SpellCastRecord(
        spellId: spellId,
        spellElement: spellElement,
        damage: damage,
        manaCost: manaCost,
        turn: _currentCombat!.currentTurn,
      ),
    );

    // Track spell usage frequency
    _currentCombat!.spellUsageCount[spellId] =
        (_currentCombat!.spellUsageCount[spellId] ?? 0) + 1;
  }

  /// Records damage taken by the player.
  void recordDamageTaken({
    required int damage,
    required String source,
    String? damageType,
  }) {
    if (_currentCombat == null) return;

    _currentCombat!.damageTaken.add(
      DamageRecord(
        damage: damage,
        source: source,
        damageType: damageType ?? 'attack',
        turn: _currentCombat!.currentTurn,
      ),
    );

    _currentCombat!.totalDamageTaken += damage;
  }

  /// Advances to the next turn.
  void advanceTurn() {
    if (_currentCombat == null) return;
    _currentCombat!.currentTurn++;
  }

  /// Ends combat with result.
  void endCombat({required bool victory, String? deathCause}) {
    if (_currentCombat == null) return;

    _currentCombat!.endTime = DateTime.now();
    _currentCombat!.victory = victory;
    _currentCombat!.deathCause = deathCause;
    _currentCombat!.turnsElapsed = _currentCombat!.currentTurn;

    // Add to run telemetry
    if (_currentRun != null) {
      _currentRun!.combats.add(_currentCombat!);
      _currentRun!.combatCount++;
      if (victory) {
        _currentRun!.combatsWon++;
      }
    }

    _currentCombat = null;
  }

  /// Ends the current run.
  void endRun({required bool victory, required int depth, String? deathCause}) {
    if (_currentRun == null) return;

    _currentRun!.endTime = DateTime.now();
    _currentRun!.victory = victory;
    _currentRun!.finalDepth = depth;
    _currentRun!.deathCause = deathCause;

    _completedRuns.add(_currentRun!);
    _saveToFile();

    _currentRun = null;
  }

  /// Gets aggregated spell usage stats.
  Map<String, int> getSpellUsageStats() {
    final stats = <String, int>{};
    for (final run in _completedRuns) {
      for (final combat in run.combats) {
        combat.spellUsageCount.forEach((spellId, count) {
          stats[spellId] = (stats[spellId] ?? 0) + count;
        });
      }
    }
    return stats;
  }

  /// Gets average turns per combat.
  double getAverageTurnsPerCombat() {
    int totalTurns = 0;
    int totalCombats = 0;

    for (final run in _completedRuns) {
      for (final combat in run.combats) {
        totalTurns += combat.turnsElapsed;
        totalCombats++;
      }
    }

    return totalCombats > 0 ? totalTurns / totalCombats : 0.0;
  }

  /// Gets death cause statistics.
  Map<String, int> getDeathCauseStats() {
    final stats = <String, int>{};
    for (final run in _completedRuns) {
      if (!run.victory && run.deathCause != null) {
        stats[run.deathCause!] = (stats[run.deathCause!] ?? 0) + 1;
      }
    }
    return stats;
  }

  /// Gets average damage taken per combat.
  double getAverageDamagePerCombat() {
    int totalDamage = 0;
    int totalCombats = 0;

    for (final run in _completedRuns) {
      for (final combat in run.combats) {
        totalDamage += combat.totalDamageTaken;
        totalCombats++;
      }
    }

    return totalCombats > 0 ? totalDamage / totalCombats : 0.0;
  }

  /// Saves telemetry data using SharedPreferences.
  Future<void> _saveToFile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final data = {
        'version': 1,
        'savedAt': DateTime.now().toIso8601String(),
        'runs': _completedRuns.map((r) => r.toJson()).toList(),
      };

      await prefs.setString(_storageKey, jsonEncode(data));
      debugPrint('Telemetry saved: ${_completedRuns.length} runs');
    } catch (e) {
      debugPrint('Failed to save telemetry: $e');
    }
  }

  /// Loads telemetry data from SharedPreferences.
  Future<void> loadFromFile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString(_storageKey);

      if (content != null) {
        final data = jsonDecode(content) as Map<String, dynamic>;

        final runs = data['runs'] as List<dynamic>;
        _completedRuns.clear();
        for (final runJson in runs) {
          _completedRuns.add(
            RunTelemetry.fromJson(runJson as Map<String, dynamic>),
          );
        }

        debugPrint('Loaded ${_completedRuns.length} runs from telemetry');
      }
    } catch (e) {
      debugPrint('Failed to load telemetry: $e');
    }
  }

  /// Exports telemetry summary for debugging/balance analysis.
  Map<String, dynamic> exportSummary() {
    return {
      'totalRuns': _completedRuns.length,
      'victories': _completedRuns.where((r) => r.victory).length,
      'avgTurnsPerCombat': getAverageTurnsPerCombat(),
      'avgDamagePerCombat': getAverageDamagePerCombat(),
      'spellUsage': getSpellUsageStats(),
      'deathCauses': getDeathCauseStats(),
    };
  }
}

/// Telemetry data for a single run.
class RunTelemetry {
  final String runId;
  final String mageId;
  final String startingElement;
  final DateTime startTime;
  DateTime? endTime;
  bool victory = false;
  int finalDepth = 0;
  String? deathCause;
  int combatCount = 0;
  int combatsWon = 0;
  final List<CombatTelemetry> combats = [];

  RunTelemetry({
    required this.runId,
    required this.mageId,
    required this.startingElement,
    required this.startTime,
  });

  Map<String, dynamic> toJson() => {
    'runId': runId,
    'mageId': mageId,
    'startingElement': startingElement,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'victory': victory,
    'finalDepth': finalDepth,
    'deathCause': deathCause,
    'combatCount': combatCount,
    'combatsWon': combatsWon,
    'combats': combats.map((c) => c.toJson()).toList(),
  };

  factory RunTelemetry.fromJson(Map<String, dynamic> json) {
    final run = RunTelemetry(
      runId: json['runId'] as String,
      mageId: json['mageId'] as String,
      startingElement: json['startingElement'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
    );
    run.endTime = json['endTime'] != null
        ? DateTime.parse(json['endTime'] as String)
        : null;
    run.victory = json['victory'] as bool;
    run.finalDepth = json['finalDepth'] as int;
    run.deathCause = json['deathCause'] as String?;
    run.combatCount = json['combatCount'] as int;
    run.combatsWon = json['combatsWon'] as int;

    final combats = json['combats'] as List<dynamic>;
    for (final c in combats) {
      run.combats.add(CombatTelemetry.fromJson(c as Map<String, dynamic>));
    }

    return run;
  }
}

/// Telemetry data for a single combat encounter.
class CombatTelemetry {
  final int encounterNumber;
  final List<String> enemyIds;
  final int playerStartingHP;
  final int playerMaxHP;
  final int depth;
  final bool isElite;
  final DateTime startTime;
  DateTime? endTime;

  int currentTurn = 1;
  int turnsElapsed = 0;
  bool victory = false;
  String? deathCause;
  int totalDamageTaken = 0;

  final List<SpellCastRecord> spellsCast = [];
  final List<DamageRecord> damageTaken = [];
  final Map<String, int> spellUsageCount = {};

  CombatTelemetry({
    required this.encounterNumber,
    required this.enemyIds,
    required this.playerStartingHP,
    required this.playerMaxHP,
    required this.depth,
    required this.isElite,
    required this.startTime,
  });

  Map<String, dynamic> toJson() => {
    'encounterNumber': encounterNumber,
    'enemyIds': enemyIds,
    'playerStartingHP': playerStartingHP,
    'playerMaxHP': playerMaxHP,
    'depth': depth,
    'isElite': isElite,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'turnsElapsed': turnsElapsed,
    'victory': victory,
    'deathCause': deathCause,
    'totalDamageTaken': totalDamageTaken,
    'spellUsageCount': spellUsageCount,
  };

  factory CombatTelemetry.fromJson(Map<String, dynamic> json) {
    final combat = CombatTelemetry(
      encounterNumber: json['encounterNumber'] as int,
      enemyIds: (json['enemyIds'] as List<dynamic>).cast<String>(),
      playerStartingHP: json['playerStartingHP'] as int,
      playerMaxHP: json['playerMaxHP'] as int,
      depth: json['depth'] as int,
      isElite: json['isElite'] as bool,
      startTime: DateTime.parse(json['startTime'] as String),
    );
    combat.endTime = json['endTime'] != null
        ? DateTime.parse(json['endTime'] as String)
        : null;
    combat.turnsElapsed = json['turnsElapsed'] as int;
    combat.victory = json['victory'] as bool;
    combat.deathCause = json['deathCause'] as String?;
    combat.totalDamageTaken = json['totalDamageTaken'] as int;

    final usage = json['spellUsageCount'] as Map<String, dynamic>;
    usage.forEach((key, value) {
      combat.spellUsageCount[key] = value as int;
    });

    return combat;
  }
}

/// Record of a single spell cast.
class SpellCastRecord {
  final String spellId;
  final String spellElement;
  final int damage;
  final int manaCost;
  final int turn;

  SpellCastRecord({
    required this.spellId,
    required this.spellElement,
    required this.damage,
    required this.manaCost,
    required this.turn,
  });
}

/// Record of damage taken by the player.
class DamageRecord {
  final int damage;
  final String source;
  final String damageType;
  final int turn;

  DamageRecord({
    required this.damage,
    required this.source,
    required this.damageType,
    required this.turn,
  });
}
