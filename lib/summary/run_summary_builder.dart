import '../domain/element.dart';
import '../domain/mage.dart';
import '../domain/spell.dart';
import '../relics/relic_system.dart';
import 'run_summary.dart';

/// Tracks statistics during a run and builds the final summary.
class RunSummaryBuilder {
  int _seed = 0;
  int _ascensionLevel = 0;
  String _mageName = '';
  Element _mageElement = Element.fire;
  DateTime? _runStartTime;

  int _combatsFought = 0;
  int _combatsWon = 0;
  int _elitesDefeated = 0;
  int _bossesDefeated = 0;
  int _totalCombatTurns = 0;
  int _totalDamageDealt = 0;
  int _totalDamageTaken = 0;
  int _totalHealing = 0;
  final Map<Element, int> _damageByElement = {};
  int _spellsCast = 0;
  final Map<Element, int> _spellsByElement = {};
  int _spellsLearned = 0;
  int _spellsUpgraded = 0;
  final Map<String, int> _spellUseCounts = {};
  final Map<String, int> _statusEffectsApplied = {};
  int _fragmentsEarned = 0;
  int _crystalsEarned = 0;

  void initialize({
    required int seed,
    required int ascensionLevel,
    required Mage mage,
  }) {
    _seed = seed;
    _ascensionLevel = ascensionLevel;
    _mageName = mage.name;
    _mageElement = mage.primaryElement;
    _runStartTime = DateTime.now();
    _reset();
  }

  void _reset() {
    _combatsFought = 0;
    _combatsWon = 0;
    _elitesDefeated = 0;
    _bossesDefeated = 0;
    _totalCombatTurns = 0;
    _totalDamageDealt = 0;
    _totalDamageTaken = 0;
    _totalHealing = 0;
    _damageByElement.clear();
    _spellsCast = 0;
    _spellsByElement.clear();
    _spellsLearned = 0;
    _spellsUpgraded = 0;
    _spellUseCounts.clear();
    _statusEffectsApplied.clear();
    _fragmentsEarned = 0;
    _crystalsEarned = 0;
  }

  void recordCombatStart() => _combatsFought++;

  void recordCombatWin({
    required int turnsTaken,
    required int damageTaken,
    bool isElite = false,
    bool isBoss = false,
  }) {
    _combatsWon++;
    _totalCombatTurns += turnsTaken;
    _totalDamageTaken += damageTaken;
    if (isElite) _elitesDefeated++;
    if (isBoss) _bossesDefeated++;
  }

  void recordDamageDealt(int damage, Element element) {
    _totalDamageDealt += damage;
    _damageByElement[element] = (_damageByElement[element] ?? 0) + damage;
  }

  void recordSpellCast(Spell spell) {
    _spellsCast++;
    _spellsByElement[spell.element] =
        (_spellsByElement[spell.element] ?? 0) + 1;
    _spellUseCounts[spell.name] = (_spellUseCounts[spell.name] ?? 0) + 1;
  }

  void recordSpellLearned() => _spellsLearned++;
  void recordSpellUpgraded() => _spellsUpgraded++;
  void recordHealing(int amount) => _totalHealing += amount;
  void recordFragmentsEarned(int amount) => _fragmentsEarned += amount;
  void recordCrystalsEarned(int amount) => _crystalsEarned += amount;

  void recordStatusEffectApplied(String effectName) {
    _statusEffectsApplied[effectName] =
        (_statusEffectsApplied[effectName] ?? 0) + 1;
  }

  RunSummary build({
    required bool victory,
    required int depthReached,
    required int maxDepth,
    required Mage mage,
    required RelicSystem relicSystem,
  }) {
    final duration = _runStartTime != null
        ? DateTime.now().difference(_runStartTime!).inSeconds
        : 0;
    String? mostUsed;
    int mostUsedCount = 0;
    for (final entry in _spellUseCounts.entries) {
      if (entry.value > mostUsedCount) {
        mostUsed = entry.key;
        mostUsedCount = entry.value;
      }
    }

    return RunSummary(
      seed: _seed,
      ascensionLevel: _ascensionLevel,
      victory: victory,
      mageName: _mageName,
      mageElement: _mageElement,
      depthReached: depthReached,
      maxDepth: maxDepth,
      durationSeconds: duration,
      combatsFought: _combatsFought,
      combatsWon: _combatsWon,
      elitesDefeated: _elitesDefeated,
      bossesDefeated: _bossesDefeated,
      totalCombatTurns: _totalCombatTurns,
      totalDamageDealt: _totalDamageDealt,
      totalDamageTaken: _totalDamageTaken,
      damageByElement: Map.from(_damageByElement),
      spellsCast: _spellsCast,
      spellsByElement: Map.from(_spellsByElement),
      spellsLearned: _spellsLearned,
      spellsUpgraded: _spellsUpgraded,
      finalSpells: mage.spellLoadout
          .map(
            (s) => SpellSummary.fromSpell(
              s,
              timesUsed: _spellUseCounts[s.name] ?? 0,
            ),
          )
          .toList(),
      mostUsedSpell: mostUsed,
      mostUsedSpellCount: mostUsedCount,
      statusEffectsApplied: Map.from(_statusEffectsApplied),
      relicsAcquired: relicSystem.relics
          .map((r) => RelicSummary.fromRelic(r))
          .toList(),
      fragmentsEarned: _fragmentsEarned,
      crystalsEarned: _crystalsEarned,
      totalHealing: _totalHealing,
    );
  }
}
