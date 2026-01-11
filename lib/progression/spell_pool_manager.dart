import 'package:shared_preferences/shared_preferences.dart';
import '../data/spell_definitions.dart';
import '../domain/spell.dart';

/// Manages the player's unlocked spell pool across runs and catalog discovery.
///
/// Phase 7.9.5: Tracks which spells are available for learning.
/// - Common, Uncommon, Rare: Always unlocked (available for runs)
/// - Signature: Unlocked via progression milestones
/// - Legendary: Unlocked by defeating specific bosses for the first time
///
/// Also tracks "Discovered" spells for the Catalog (Pokedex style).
class SpellPoolManager {
  static const String _unlockedSpellsKey = 'unlocked_spells';
  static const String _defeatedBossesKey = 'defeated_bosses_first_clear';
  static const String _discoveredSpellsKey = 'discovered_spells';

  SharedPreferences? _prefs;

  /// Set of unlocked spell IDs (for signature/legendary availability)
  final Set<String> _unlockedSpellIds = {};

  /// Set of bosses defeated for the first time (for legendary unlocks)
  final Set<String> _firstClearBosses = {};

  /// Set of discovered spell IDs (for Catalog/Pokedex)
  final Set<String> _discoveredSpellIds = {};

  /// Singleton instance
  static final SpellPoolManager _instance = SpellPoolManager._internal();
  static SpellPoolManager get instance => _instance;

  SpellPoolManager._internal();

  /// Initialize the spell pool manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadData();

    // Ensure base spells are always available
    _initializeBaseSpells();

    // Auto-discover base spells? No, user wants Pokedex style (discover on learn).
  }

  void _loadData() {
    final unlockedList = _prefs?.getStringList(_unlockedSpellsKey) ?? [];
    _unlockedSpellIds.addAll(unlockedList);

    final defeatedList = _prefs?.getStringList(_defeatedBossesKey) ?? [];
    _firstClearBosses.addAll(defeatedList);

    final discoveredList = _prefs?.getStringList(_discoveredSpellsKey) ?? [];
    _discoveredSpellIds.addAll(discoveredList);
  }

  Future<void> _saveData() async {
    await _prefs?.setStringList(_unlockedSpellsKey, _unlockedSpellIds.toList());
    await _prefs?.setStringList(_defeatedBossesKey, _firstClearBosses.toList());
    await _prefs?.setStringList(
      _discoveredSpellsKey,
      _discoveredSpellIds.toList(),
    );
  }

  void _initializeBaseSpells() {
    // Common, Uncommon, Rare are always unlocked
    for (final spell in SpellDefinitions.commonSpells) {
      _unlockedSpellIds.add(spell.id);
    }
    for (final spell in SpellDefinitions.uncommonSpells) {
      _unlockedSpellIds.add(spell.id);
    }
    for (final spell in SpellDefinitions.rareSpells) {
      _unlockedSpellIds.add(spell.id);
    }
  }

  // ==================== QUERIES ====================

  /// Whether a spell is unlocked and available for learning
  bool isSpellUnlocked(String spellId) {
    return _unlockedSpellIds.contains(spellId);
  }

  /// Whether a spell is discovered and visible in the catalog
  bool isSpellDiscovered(String spellId) {
    return _discoveredSpellIds.contains(spellId);
  }

  /// Whether a boss has been defeated for the first time
  bool isBossFirstCleared(String bossId) {
    return _firstClearBosses.contains(bossId);
  }

  /// Get all unlocked spells (available for runs)
  List<Spell> get unlockedSpells {
    return SpellDefinitions.allSpells
        .where((s) => isSpellUnlocked(s.id))
        .toList();
  }

  /// Get all locked legendary spells
  List<Spell> get lockedLegendarySpells {
    return SpellDefinitions.legendarySpells
        .where((s) => !isSpellUnlocked(s.id))
        .toList();
  }

  /// Get spells available for a spell learn node (excludes locked legendaries)
  List<Spell> getAvailableSpellsForLearning({List<String>? excludeIds}) {
    var pool = unlockedSpells;

    // Exclude signature and legendary from normal learn nodes
    pool = pool
        .where(
          (s) =>
              s.rarity != SpellRarity.signature &&
              s.rarity != SpellRarity.legendary,
        )
        .toList();

    if (excludeIds != null) {
      pool = pool.where((s) => !excludeIds.contains(s.id)).toList();
    }

    return pool;
  }

  // ==================== UNLOCKING & DISCOVERY ====================

  /// Unlock a spell by ID (Availability)
  Future<void> unlockSpell(String spellId) async {
    _unlockedSpellIds.add(spellId);
    await _saveData();
  }

  /// Mark a spell as discovered (Catalog)
  Future<void> markSpellDiscovered(String spellId) async {
    if (!_discoveredSpellIds.contains(spellId)) {
      _discoveredSpellIds.add(spellId);
      await _saveData();
    }
  }

  /// Record a boss first clear and unlock associated legendary
  Future<Spell?> recordBossFirstClear(String bossId) async {
    if (_firstClearBosses.contains(bossId)) {
      return null; // Already cleared
    }

    _firstClearBosses.add(bossId);

    // Unlock the legendary spell associated with this boss
    final legendarySpell = _getLegendaryForBoss(bossId);
    if (legendarySpell != null) {
      await unlockSpell(legendarySpell.id);
      // NOTE: Unlocking availability doesn't strictly mean discovered yet?
      // But if it's a reward, they'll learn it and discover it.
    }

    await _saveData();
    return legendarySpell;
  }

  /// Get the legendary spell associated with a boss
  Spell? _getLegendaryForBoss(String bossId) {
    switch (bossId) {
      case 'gatekeeper_pyre':
        return SpellDefinitions.forgeCollapse;
      case 'gatekeeper_tide':
        return SpellDefinitions.tidalSeverance;
      default:
        return null;
    }
  }

  /// Get unlock info for display
  Map<String, dynamic> getUnlockInfo(String spellId) {
    final spell = SpellDefinitions.allSpells.firstWhere(
      (s) => s.id == spellId,
      orElse: () => SpellDefinitions.fireball,
    );

    if (spell.rarity == SpellRarity.legendary) {
      final bossId = _getBossForLegendary(spellId);
      final bossName = _getBossDisplayName(bossId);
      return {
        'unlocked': isSpellUnlocked(spellId),
        'unlockSource': 'Boss: $bossName',
        'requirement': 'Defeat $bossName for the first time',
      };
    }

    return {'unlocked': true, 'unlockSource': 'Default', 'requirement': null};
  }

  String? _getBossForLegendary(String spellId) {
    switch (spellId) {
      case 'forgeCollapse':
        return 'gatekeeper_pyre';
      case 'tidalSeverance':
        return 'gatekeeper_tide';
      default:
        return null;
    }
  }

  String _getBossDisplayName(String? bossId) {
    switch (bossId) {
      case 'gatekeeper_pyre':
        return 'Gatekeeper of Pyre';
      case 'gatekeeper_tide':
        return 'Gatekeeper of Tide';
      default:
        return 'Unknown Boss';
    }
  }

  // ==================== DEBUG/ADMIN ====================

  /// Reset all unlocks (for testing)
  Future<void> resetAllUnlocks() async {
    _unlockedSpellIds.clear();
    _firstClearBosses.clear();
    _discoveredSpellIds.clear();
    _initializeBaseSpells();
    await _saveData();
  }

  /// Unlock all spells and mark discovered (for testing)
  Future<void> unlockAllSpells() async {
    for (final spell in SpellDefinitions.allSpells) {
      _unlockedSpellIds.add(spell.id);
      _discoveredSpellIds.add(spell.id);
    }
    await _saveData();
  }
}
