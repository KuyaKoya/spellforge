import 'dart:convert';

/// Local telemetry system for balance tuning.
///
/// Phase 7 - A5: Telemetry Hooks (Local)
///
/// Metrics Captured:
/// - Turns per battle
/// - Damage taken per fight
/// - Spell usage frequency
/// - Death cause (enemy / burn / misplay)
///
/// Storage: Local JSON/log (in-memory for now, can be persisted later)
class Telemetry {
  static final Telemetry _instance = Telemetry._internal();
  factory Telemetry() => _instance;
  Telemetry._internal();

  /// All recorded combat sessions.
  final List<CombatSession> _sessions = [];

  /// Current session being recorded.
  CombatSession? _currentSession;

  // ==================== SESSION MANAGEMENT ====================

  /// Starts recording a new combat session.
  void startCombat({
    required String mageId,
    required int mageLevel,
    required int mageHP,
    required int mageMaxHP,
    required List<String> enemies,
    required int depth,
  }) {
    _currentSession = CombatSession(
      startTime: DateTime.now(),
      mageId: mageId,
      mageLevel: mageLevel,
      mageStartHP: mageHP,
      mageMaxHP: mageMaxHP,
      enemies: enemies,
      depth: depth,
    );
  }

  /// Ends the current combat session.
  void endCombat({
    required bool victory,
    required int mageEndHP,
    String? deathCause,
  }) {
    if (_currentSession == null) return;

    _currentSession!
      ..endTime = DateTime.now()
      ..victory = victory
      ..mageEndHP = mageEndHP
      ..deathCause = deathCause;

    _sessions.add(_currentSession!);
    _currentSession = null;

    _logSession(_sessions.last);
  }

  // ==================== EVENT RECORDING ====================

  /// Records a turn starting.
  void recordTurnStart({required bool isPlayerTurn}) {
    if (_currentSession == null) return;
    if (isPlayerTurn) {
      _currentSession!.playerTurns++;
    } else {
      _currentSession!.enemyTurns++;
    }
  }

  /// Records spell usage.
  void recordSpellCast({
    required String spellId,
    required int manaCost,
    required int damage,
    required List<String> effects,
  }) {
    if (_currentSession == null) return;

    final usage = _currentSession!.spellUsage[spellId] ?? SpellUsageStats();
    usage.castCount++;
    usage.totalDamage += damage;
    usage.totalManaCost += manaCost;
    _currentSession!.spellUsage[spellId] = usage;
  }

  /// Records damage taken by player.
  void recordDamageTaken({
    required int amount,
    required String source,
    DamageCause cause = DamageCause.enemyAttack,
  }) {
    if (_currentSession == null) return;

    _currentSession!.damageTaken += amount;

    switch (cause) {
      case DamageCause.enemyAttack:
        _currentSession!.damageFromEnemies += amount;
        break;
      case DamageCause.burn:
        _currentSession!.damageFromBurn += amount;
        break;
      case DamageCause.debuff:
        _currentSession!.damageFromDebuffs += amount;
        break;
      case DamageCause.other:
        break;
    }
  }

  /// Records enemy defeated.
  void recordEnemyDefeated({required String enemyId}) {
    if (_currentSession == null) return;
    _currentSession!.enemiesDefeated++;
  }

  // ==================== ANALYTICS ====================

  /// Gets aggregate statistics across all sessions.
  TelemetryStats getStats() {
    if (_sessions.isEmpty) {
      return TelemetryStats.empty();
    }

    final victories = _sessions.where((s) => s.victory).length;
    final totalTurns = _sessions.fold(0, (sum, s) => sum + s.playerTurns);
    final totalDamage = _sessions.fold(0, (sum, s) => sum + s.damageTaken);
    final combatCount = _sessions.length;

    // Aggregate spell usage
    final allSpellUsage = <String, SpellUsageStats>{};
    for (final session in _sessions) {
      session.spellUsage.forEach((spellId, usage) {
        final existing = allSpellUsage[spellId] ?? SpellUsageStats();
        existing.castCount += usage.castCount;
        existing.totalDamage += usage.totalDamage;
        existing.totalManaCost += usage.totalManaCost;
        allSpellUsage[spellId] = existing;
      });
    }

    // Death causes
    final deathCauses = <String, int>{};
    for (final session in _sessions) {
      if (!session.victory && session.deathCause != null) {
        deathCauses[session.deathCause!] =
            (deathCauses[session.deathCause!] ?? 0) + 1;
      }
    }

    return TelemetryStats(
      totalCombats: combatCount,
      victories: victories,
      losses: combatCount - victories,
      winRate: combatCount > 0 ? victories / combatCount : 0.0,
      averageTurnsPerCombat: combatCount > 0 ? totalTurns / combatCount : 0.0,
      averageDamageTaken: combatCount > 0 ? totalDamage / combatCount : 0.0,
      spellUsage: allSpellUsage,
      deathCauses: deathCauses,
    );
  }

  /// Gets the most recent sessions.
  List<CombatSession> getRecentSessions({int count = 10}) {
    final start = _sessions.length > count ? _sessions.length - count : 0;
    return _sessions.sublist(start);
  }

  /// Clears all telemetry data.
  void clear() {
    _sessions.clear();
    _currentSession = null;
  }

  /// Exports all sessions as JSON.
  String exportAsJson() {
    return jsonEncode(_sessions.map((s) => s.toJson()).toList());
  }

  // ==================== LOGGING ====================

  void _logSession(CombatSession session) {
    // ignore: avoid_print
    print(
      '[Telemetry] Combat ${session.victory ? 'WON' : 'LOST'} - '
      'Turns: ${session.playerTurns}, '
      'Damage: ${session.damageTaken}, '
      'Duration: ${session.duration?.inSeconds ?? 0}s',
    );
  }
}

/// Cause of damage for analytics.
enum DamageCause { enemyAttack, burn, debuff, other }

/// Records data for a single combat session.
class CombatSession {
  final DateTime startTime;
  DateTime? endTime;
  final String mageId;
  final int mageLevel;
  final int mageStartHP;
  final int mageMaxHP;
  int mageEndHP = 0;
  final List<String> enemies;
  final int depth;
  bool victory = false;
  String? deathCause;

  int playerTurns = 0;
  int enemyTurns = 0;
  int damageTaken = 0;
  int damageFromEnemies = 0;
  int damageFromBurn = 0;
  int damageFromDebuffs = 0;
  int enemiesDefeated = 0;

  final Map<String, SpellUsageStats> spellUsage = {};

  CombatSession({
    required this.startTime,
    required this.mageId,
    required this.mageLevel,
    required this.mageStartHP,
    required this.mageMaxHP,
    required this.enemies,
    required this.depth,
  });

  Duration? get duration => endTime?.difference(startTime);

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'mageId': mageId,
    'mageLevel': mageLevel,
    'startHP': mageStartHP,
    'endHP': mageEndHP,
    'maxHP': mageMaxHP,
    'enemies': enemies,
    'depth': depth,
    'victory': victory,
    'deathCause': deathCause,
    'playerTurns': playerTurns,
    'enemyTurns': enemyTurns,
    'damageTaken': damageTaken,
    'damageFromEnemies': damageFromEnemies,
    'damageFromBurn': damageFromBurn,
    'damageFromDebuffs': damageFromDebuffs,
    'enemiesDefeated': enemiesDefeated,
    'spellUsage': spellUsage.map((k, v) => MapEntry(k, v.toJson())),
  };
}

/// Spell usage statistics.
class SpellUsageStats {
  int castCount = 0;
  int totalDamage = 0;
  int totalManaCost = 0;

  double get averageDamage => castCount > 0 ? totalDamage / castCount : 0.0;
  double get damagePerMana =>
      totalManaCost > 0 ? totalDamage / totalManaCost : 0.0;

  Map<String, dynamic> toJson() => {
    'castCount': castCount,
    'totalDamage': totalDamage,
    'totalManaCost': totalManaCost,
    'averageDamage': averageDamage,
    'damagePerMana': damagePerMana,
  };
}

/// Aggregate telemetry statistics.
class TelemetryStats {
  final int totalCombats;
  final int victories;
  final int losses;
  final double winRate;
  final double averageTurnsPerCombat;
  final double averageDamageTaken;
  final Map<String, SpellUsageStats> spellUsage;
  final Map<String, int> deathCauses;

  TelemetryStats({
    required this.totalCombats,
    required this.victories,
    required this.losses,
    required this.winRate,
    required this.averageTurnsPerCombat,
    required this.averageDamageTaken,
    required this.spellUsage,
    required this.deathCauses,
  });

  factory TelemetryStats.empty() => TelemetryStats(
    totalCombats: 0,
    victories: 0,
    losses: 0,
    winRate: 0.0,
    averageTurnsPerCombat: 0.0,
    averageDamageTaken: 0.0,
    spellUsage: {},
    deathCauses: {},
  );

  /// Gets the most used spells, sorted by cast count.
  List<MapEntry<String, SpellUsageStats>> get topSpells {
    final entries = spellUsage.entries.toList();
    entries.sort((a, b) => b.value.castCount.compareTo(a.value.castCount));
    return entries;
  }

  @override
  String toString() {
    return '''
Telemetry Stats:
- Total Combats: $totalCombats
- Win Rate: ${(winRate * 100).toStringAsFixed(1)}%
- Avg Turns/Combat: ${averageTurnsPerCombat.toStringAsFixed(1)}
- Avg Damage Taken: ${averageDamageTaken.toStringAsFixed(1)}
- Top Death Causes: $deathCauses
''';
  }
}
