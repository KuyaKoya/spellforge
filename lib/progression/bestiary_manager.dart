import 'package:shared_preferences/shared_preferences.dart';
import '../domain/enemy.dart';
import '../domain/elite_enemy.dart';
import '../domain/enemy_passive.dart';
import '../data/passive_definitions.dart';

/// Manages the player's discovered enemies and passives across runs.
///
/// Unlike spells (which require an unlock system), enemies and passives
/// are automatically discovered when encountered during a run.
/// The catalog shows "???" for undiscovered entries until the player
/// encounters them in combat.
class BestiaryManager {
  static const String _discoveredEnemiesKey = 'discovered_enemies';
  static const String _discoveredPassivesKey = 'discovered_passives';

  SharedPreferences? _prefs;

  /// Set of discovered enemy IDs
  final Set<String> _discoveredEnemyIds = {};

  /// Set of discovered passive IDs
  final Set<String> _discoveredPassiveIds = {};

  /// Singleton instance
  static final BestiaryManager _instance = BestiaryManager._internal();
  static BestiaryManager get instance => _instance;

  BestiaryManager._internal();

  /// Initialize the bestiary manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadData();
  }

  void _loadData() {
    final enemyList = _prefs?.getStringList(_discoveredEnemiesKey) ?? [];
    _discoveredEnemyIds.addAll(enemyList);

    final passiveList = _prefs?.getStringList(_discoveredPassivesKey) ?? [];
    _discoveredPassiveIds.addAll(passiveList);
  }

  Future<void> _saveData() async {
    await _prefs?.setStringList(
      _discoveredEnemiesKey,
      _discoveredEnemyIds.toList(),
    );
    await _prefs?.setStringList(
      _discoveredPassivesKey,
      _discoveredPassiveIds.toList(),
    );
  }

  // ==================== QUERIES ====================

  /// Whether an enemy is discovered and visible in the catalog
  bool isEnemyDiscovered(String enemyId) {
    return _discoveredEnemyIds.contains(enemyId);
  }

  /// Whether a passive is discovered and visible in the catalog
  bool isPassiveDiscovered(String passiveId) {
    return _discoveredPassiveIds.contains(passiveId);
  }

  /// Get count of discovered enemies
  int get discoveredEnemyCount => _discoveredEnemyIds.length;

  /// Get count of discovered passives
  int get discoveredPassiveCount => _discoveredPassiveIds.length;

  // ==================== DISCOVERY ====================

  /// Mark an enemy as discovered (called when encountered in combat)
  Future<void> markEnemyDiscovered(String enemyId) async {
    if (!_discoveredEnemyIds.contains(enemyId)) {
      _discoveredEnemyIds.add(enemyId);
      await _saveData();
    }
  }

  /// Mark a passive as discovered (called when enemy with passive is encountered)
  Future<void> markPassiveDiscovered(String passiveId) async {
    if (!_discoveredPassiveIds.contains(passiveId)) {
      _discoveredPassiveIds.add(passiveId);
      await _saveData();
    }
  }

  /// Discovers an enemy and all its associated passives
  /// This is the main entry point when combat starts
  Future<void> discoverEnemy(Enemy enemy) async {
    await markEnemyDiscovered(enemy.id);

    // If this is an elite enemy, discover its passives too
    if (enemy is EliteEnemy) {
      for (final passive in enemy.passives) {
        await markPassiveDiscovered(passive.id);
      }
    }

    // Also check PassiveDefinitions for any registered passives for this enemy
    final passives = PassiveDefinitions.getPassivesForEnemy(enemy.id);
    for (final passive in passives) {
      await markPassiveDiscovered(passive.id);
    }
  }

  /// Discovers all enemies in a list (for multi-enemy encounters)
  Future<void> discoverEnemies(List<Enemy> enemies) async {
    for (final enemy in enemies) {
      await discoverEnemy(enemy);
    }
  }

  // ==================== DEBUG/ADMIN ====================

  /// Reset all discoveries (for testing)
  Future<void> resetAllDiscoveries() async {
    _discoveredEnemyIds.clear();
    _discoveredPassiveIds.clear();
    await _saveData();
  }

  /// Discover all enemies and passives (for testing)
  Future<void> discoverAll({
    required List<String> allEnemyIds,
    required List<EnemyPassive> allPassives,
  }) async {
    _discoveredEnemyIds.addAll(allEnemyIds);
    for (final passive in allPassives) {
      _discoveredPassiveIds.add(passive.id);
    }
    await _saveData();
  }
}
