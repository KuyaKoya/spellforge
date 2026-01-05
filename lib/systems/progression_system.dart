import 'package:shared_preferences/shared_preferences.dart';

/// Manages persistent resources across runs (fragments, crystals).
class ProgressionSystem {
  static const String _fragmentsKey = 'spell_fragments';
  static const String _crystalsKey = 'spell_crystals';
  static const String _totalRunsKey = 'total_runs';
  static const String _bestNodeKey = 'best_node_reached';
  static const String _lastRunElementKey = 'last_run_element';

  SharedPreferences? _prefs;

  /// Persistent spell fragments.
  int _spellFragments = 0;
  int get spellFragments => _spellFragments;

  /// Persistent spell crystals.
  int _spellCrystals = 0;
  int get spellCrystals => _spellCrystals;

  /// Total runs played.
  int _totalRuns = 0;
  int get totalRuns => _totalRuns;

  /// Best node reached in any run.
  int _bestNodeReached = 0;
  int get bestNodeReached => _bestNodeReached;

  /// Last run starting element (for UI display).
  String? _lastRunElement;
  String? get lastRunElement => _lastRunElement;

  /// Run-transient state.
  int _currentRunLevel = 1;
  int get currentRunLevel => _currentRunLevel;

  int _currentNodeIndex = 0;
  int get currentNodeIndex => _currentNodeIndex;

  /// Initializes the system, loading saved data.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadData();
  }

  void _loadData() {
    _spellFragments = _prefs?.getInt(_fragmentsKey) ?? 0;
    _spellCrystals = _prefs?.getInt(_crystalsKey) ?? 0;
    _totalRuns = _prefs?.getInt(_totalRunsKey) ?? 0;
    _bestNodeReached = _prefs?.getInt(_bestNodeKey) ?? 0;
    _lastRunElement = _prefs?.getString(_lastRunElementKey);
  }

  Future<void> _saveData() async {
    await _prefs?.setInt(_fragmentsKey, _spellFragments);
    await _prefs?.setInt(_crystalsKey, _spellCrystals);
    await _prefs?.setInt(_totalRunsKey, _totalRuns);
    await _prefs?.setInt(_bestNodeKey, _bestNodeReached);
    if (_lastRunElement != null) {
      await _prefs?.setString(_lastRunElementKey, _lastRunElement!);
    }
  }

  /// Starts a new run, resetting transient state.
  void startNewRun() {
    _currentRunLevel = 1;
    _currentNodeIndex = 0;
  }

  /// Ends the current run.
  Future<void> endRun({
    required int nodesCompleted,
    required bool victory,
    required int fragmentsEarned,
    int crystalsEarned = 0,
    String? startingElement,
  }) async {
    _totalRuns++;
    _spellFragments += fragmentsEarned;
    _spellCrystals += crystalsEarned;

    if (nodesCompleted > _bestNodeReached) {
      _bestNodeReached = nodesCompleted;
    }

    if (startingElement != null) {
      _lastRunElement = startingElement;
    }

    await _saveData();
  }

  /// Advances to the next node.
  void advanceNode() {
    _currentNodeIndex++;
  }

  /// Levels up within the current run.
  void levelUp() {
    _currentRunLevel++;
  }

  /// Spends fragments. Returns true if successful.
  Future<bool> spendFragments(int amount) async {
    if (_spellFragments < amount) return false;
    _spellFragments -= amount;
    await _saveData();
    return true;
  }

  /// Spends crystals. Returns true if successful.
  Future<bool> spendCrystals(int amount) async {
    if (_spellCrystals < amount) return false;
    _spellCrystals -= amount;
    await _saveData();
    return true;
  }

  /// Adds fragments (cheat/debug).
  Future<void> addFragments(int amount) async {
    _spellFragments += amount;
    await _saveData();
  }

  /// Adds crystals.
  Future<void> addCrystals(int amount) async {
    _spellCrystals += amount;
    await _saveData();
  }

  /// Calculates fragments earned for a combat victory.
  int calculateCombatReward(int nodeIndex, int enemiesDefeated) {
    final baseReward = 10;
    final nodeBonus = nodeIndex * 2;
    final enemyBonus = enemiesDefeated * 5;
    return baseReward + nodeBonus + enemyBonus;
  }

  /// Gets a summary of persistent progress.
  String getProgressSummary() {
    return '''
=== PROGRESS ===
Spell Fragments: $_spellFragments
Spell Crystals: $_spellCrystals
Total Runs: $_totalRuns
Best Node Reached: $_bestNodeReached
Last Start Element: ${_lastRunElement ?? 'None'}
''';
  }

  /// Resets all persistent data (for testing).
  Future<void> resetAll() async {
    _spellFragments = 0;
    _spellCrystals = 0;
    _totalRuns = 0;
    _bestNodeReached = 0;
    _lastRunElement = null;
    await _saveData();
  }
}
