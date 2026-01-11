import 'package:shared_preferences/shared_preferences.dart';

/// Centralized account-level unlock and progression tracking.
///
/// Phase 7.9.5: Tracks persistent unlocks across runs including:
/// - Legendary spell unlocks (from boss first clears)
/// - Achievement unlocks
/// - Cosmetic unlocks (future)
/// - Character progression milestones
class AccountUnlocks {
  static const String _keyPrefix = 'account_unlock_';
  static const String _achievementsKey = '${_keyPrefix}achievements';
  static const String _milestonesKey = '${_keyPrefix}milestones';
  static const String _totalBossDefeatsKey = '${_keyPrefix}boss_defeats';
  static const String _totalEliteDefeatsKey = '${_keyPrefix}elite_defeats';

  SharedPreferences? _prefs;

  /// Unlocked achievements
  final Set<String> _achievements = {};

  /// Completed milestones
  final Set<String> _milestones = {};

  /// Total boss defeats (across all runs)
  int _totalBossDefeats = 0;
  int get totalBossDefeats => _totalBossDefeats;

  /// Total elite defeats (across all runs)
  int _totalEliteDefeats = 0;
  int get totalEliteDefeats => _totalEliteDefeats;

  /// Singleton instance
  static final AccountUnlocks _instance = AccountUnlocks._internal();
  static AccountUnlocks get instance => _instance;

  AccountUnlocks._internal();

  /// Initialize account unlocks
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadData();
  }

  void _loadData() {
    final achievementsList = _prefs?.getStringList(_achievementsKey) ?? [];
    _achievements.addAll(achievementsList);

    final milestonesList = _prefs?.getStringList(_milestonesKey) ?? [];
    _milestones.addAll(milestonesList);

    _totalBossDefeats = _prefs?.getInt(_totalBossDefeatsKey) ?? 0;
    _totalEliteDefeats = _prefs?.getInt(_totalEliteDefeatsKey) ?? 0;
  }

  Future<void> _saveData() async {
    await _prefs?.setStringList(_achievementsKey, _achievements.toList());
    await _prefs?.setStringList(_milestonesKey, _milestones.toList());
    await _prefs?.setInt(_totalBossDefeatsKey, _totalBossDefeats);
    await _prefs?.setInt(_totalEliteDefeatsKey, _totalEliteDefeats);
  }

  // ==================== ACHIEVEMENTS ====================

  /// Whether an achievement is unlocked
  bool hasAchievement(String achievementId) {
    return _achievements.contains(achievementId);
  }

  /// Unlock an achievement
  Future<void> unlockAchievement(String achievementId) async {
    if (!_achievements.contains(achievementId)) {
      _achievements.add(achievementId);
      await _saveData();
    }
  }

  /// Get all unlocked achievements
  List<String> get unlockedAchievements => _achievements.toList();

  // ==================== MILESTONES ====================

  /// Whether a milestone is completed
  bool hasMilestone(String milestoneId) {
    return _milestones.contains(milestoneId);
  }

  /// Complete a milestone
  Future<void> completeMilestone(String milestoneId) async {
    if (!_milestones.contains(milestoneId)) {
      _milestones.add(milestoneId);
      await _saveData();
    }
  }

  // ==================== COMBAT TRACKING ====================

  /// Record a boss defeat
  Future<void> recordBossDefeat() async {
    _totalBossDefeats++;
    await _saveData();

    // Check for boss-related achievements
    await _checkBossAchievements();
  }

  /// Record an elite defeat
  Future<void> recordEliteDefeat() async {
    _totalEliteDefeats++;
    await _saveData();

    // Check for elite-related achievements
    await _checkEliteAchievements();
  }

  Future<void> _checkBossAchievements() async {
    if (_totalBossDefeats >= 1) {
      await unlockAchievement('first_boss_defeat');
    }
    if (_totalBossDefeats >= 5) {
      await unlockAchievement('boss_slayer_5');
    }
    if (_totalBossDefeats >= 10) {
      await unlockAchievement('boss_slayer_10');
    }
  }

  Future<void> _checkEliteAchievements() async {
    if (_totalEliteDefeats >= 1) {
      await unlockAchievement('first_elite_defeat');
    }
    if (_totalEliteDefeats >= 10) {
      await unlockAchievement('elite_hunter_10');
    }
    if (_totalEliteDefeats >= 25) {
      await unlockAchievement('elite_hunter_25');
    }
  }

  // ==================== PROGRESS SUMMARY ====================

  /// Get a summary of account progress
  Map<String, dynamic> getProgressSummary() {
    return {
      'totalBossDefeats': _totalBossDefeats,
      'totalEliteDefeats': _totalEliteDefeats,
      'achievementsUnlocked': _achievements.length,
      'milestonesCompleted': _milestones.length,
    };
  }

  // ==================== DEBUG/ADMIN ====================

  /// Reset all unlocks (for testing)
  Future<void> resetAll() async {
    _achievements.clear();
    _milestones.clear();
    _totalBossDefeats = 0;
    _totalEliteDefeats = 0;
    await _saveData();
  }
}

/// Known achievement IDs
class AchievementIds {
  static const String firstBossDefeat = 'first_boss_defeat';
  static const String bossSlayer5 = 'boss_slayer_5';
  static const String bossSlayer10 = 'boss_slayer_10';
  static const String firstEliteDefeat = 'first_elite_defeat';
  static const String eliteHunter10 = 'elite_hunter_10';
  static const String eliteHunter25 = 'elite_hunter_25';

  static String getDisplayName(String id) {
    switch (id) {
      case firstBossDefeat:
        return 'First Blood';
      case bossSlayer5:
        return 'Boss Slayer';
      case bossSlayer10:
        return 'Boss Hunter';
      case firstEliteDefeat:
        return 'Elite Vanquisher';
      case eliteHunter10:
        return 'Elite Hunter';
      case eliteHunter25:
        return 'Elite Nemesis';
      default:
        return 'Unknown Achievement';
    }
  }

  static String getDescription(String id) {
    switch (id) {
      case firstBossDefeat:
        return 'Defeat a boss for the first time';
      case bossSlayer5:
        return 'Defeat 5 bosses';
      case bossSlayer10:
        return 'Defeat 10 bosses';
      case firstEliteDefeat:
        return 'Defeat an elite enemy for the first time';
      case eliteHunter10:
        return 'Defeat 10 elite enemies';
      case eliteHunter25:
        return 'Defeat 25 elite enemies';
      default:
        return 'Unknown achievement';
    }
  }
}
