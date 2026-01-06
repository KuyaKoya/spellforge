import 'package:shared_preferences/shared_preferences.dart';

/// Represents persistent meta-progression state across runs.
///
/// This state survives between runs and is persisted to storage.
/// It includes resources, statistics, and unlocks that carry over.
class MetaState {
  static const String _fragmentsKey = 'spell_fragments';
  static const String _crystalsKey = 'spell_crystals';
  static const String _totalRunsKey = 'total_runs';
  static const String _victoriesKey = 'total_victories';
  static const String _bestNodeKey = 'best_node_reached';
  static const String _totalCombatsKey = 'total_combats_won';

  SharedPreferences? _prefs;

  // ==================== RESOURCES ====================

  /// Persistent spell fragments.
  int _spellFragments = 0;
  int get spellFragments => _spellFragments;

  /// Persistent spell crystals.
  int _spellCrystals = 0;
  int get spellCrystals => _spellCrystals;

  // ==================== STATISTICS ====================

  /// Total runs played.
  int _totalRuns = 0;
  int get totalRuns => _totalRuns;

  /// Total victories (boss defeats).
  /// Phase 7.9: This is the "successfulRuns" metric for meta difficulty calculation.
  int _totalVictories = 0;
  int get totalVictories => _totalVictories;

  /// Phase 7.9: Alias for meta difficulty calculation.
  /// successfulRuns = total boss defeats across all runs.
  int get successfulRuns => _totalVictories;

  /// Best node reached in any run.
  int _bestNodeReached = 0;
  int get bestNodeReached => _bestNodeReached;

  /// Total combats won across all runs.
  int _totalCombatsWon = 0;
  int get totalCombatsWon => _totalCombatsWon;

  // ==================== LIFECYCLE ====================

  /// Initializes the meta state, loading from storage.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadData();
  }

  void _loadData() {
    _spellFragments = _prefs?.getInt(_fragmentsKey) ?? 0;
    _spellCrystals = _prefs?.getInt(_crystalsKey) ?? 0;
    _totalRuns = _prefs?.getInt(_totalRunsKey) ?? 0;
    _totalVictories = _prefs?.getInt(_victoriesKey) ?? 0;
    _bestNodeReached = _prefs?.getInt(_bestNodeKey) ?? 0;
    _totalCombatsWon = _prefs?.getInt(_totalCombatsKey) ?? 0;
  }

  Future<void> _saveData() async {
    await _prefs?.setInt(_fragmentsKey, _spellFragments);
    await _prefs?.setInt(_crystalsKey, _spellCrystals);
    await _prefs?.setInt(_totalRunsKey, _totalRuns);
    await _prefs?.setInt(_victoriesKey, _totalVictories);
    await _prefs?.setInt(_bestNodeKey, _bestNodeReached);
    await _prefs?.setInt(_totalCombatsKey, _totalCombatsWon);
  }

  // ==================== RESOURCE MANAGEMENT ====================

  /// Adds fragments.
  Future<void> addFragments(int amount) async {
    _spellFragments += amount;
    await _saveData();
  }

  /// Spends fragments. Returns true if successful.
  Future<bool> spendFragments(int amount) async {
    if (_spellFragments < amount) return false;
    _spellFragments -= amount;
    await _saveData();
    return true;
  }

  /// Adds crystals.
  Future<void> addCrystals(int amount) async {
    _spellCrystals += amount;
    await _saveData();
  }

  /// Spends crystals. Returns true if successful.
  Future<bool> spendCrystals(int amount) async {
    if (_spellCrystals < amount) return false;
    _spellCrystals -= amount;
    await _saveData();
    return true;
  }

  // ==================== RUN COMPLETION ====================

  /// Records a completed run.
  Future<void> recordRunEnd({
    required int nodesCompleted,
    required bool victory,
    required int fragmentsEarned,
    required int crystalsEarned,
    required int combatsWon,
  }) async {
    _totalRuns++;
    if (victory) _totalVictories++;
    _spellFragments += fragmentsEarned;
    _spellCrystals += crystalsEarned;
    _totalCombatsWon += combatsWon;

    if (nodesCompleted > _bestNodeReached) {
      _bestNodeReached = nodesCompleted;
    }

    await _saveData();
  }

  // ==================== STATISTICS ====================

  /// Win rate as a percentage.
  double get winRate =>
      _totalRuns > 0 ? (_totalVictories / _totalRuns) * 100 : 0;

  /// Average combats won per run.
  double get averageCombatsPerRun =>
      _totalRuns > 0 ? _totalCombatsWon / _totalRuns : 0;

  /// Gets a summary of persistent progress.
  String getProgressSummary() {
    return '''
=== PROGRESS ===
Spell Fragments: $_spellFragments
Spell Crystals: $_spellCrystals
Total Runs: $_totalRuns
Victories: $_totalVictories
Best Node Reached: $_bestNodeReached
''';
  }

  /// Gets statistics as a map.
  Map<String, dynamic> getStatistics() {
    return {
      'spellFragments': _spellFragments,
      'spellCrystals': _spellCrystals,
      'totalRuns': _totalRuns,
      'totalVictories': _totalVictories,
      'bestNodeReached': _bestNodeReached,
      'totalCombatsWon': _totalCombatsWon,
      'winRate': winRate,
    };
  }

  // ==================== DEBUG ====================

  /// Resets all persistent data (for testing).
  Future<void> resetAll() async {
    _spellFragments = 0;
    _spellCrystals = 0;
    _totalRuns = 0;
    _totalVictories = 0;
    _bestNodeReached = 0;
    _totalCombatsWon = 0;
    await _saveData();
  }
}
