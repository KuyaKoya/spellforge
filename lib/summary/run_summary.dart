import '../domain/element.dart';
import '../domain/spell.dart';
import '../relics/relic.dart';

/// Comprehensive run statistics for the summary screen.
class RunSummary {
  final int seed;
  final int ascensionLevel;
  final bool victory;
  final String mageName;
  final Element mageElement;
  final int depthReached;
  final int maxDepth;
  final int durationSeconds;
  final int combatsFought;
  final int combatsWon;
  final int elitesDefeated;
  final int bossesDefeated;
  final int totalCombatTurns;
  final int totalDamageDealt;
  final int totalDamageTaken;
  final Map<Element, int> damageByElement;
  final int spellsCast;
  final Map<Element, int> spellsByElement;
  final int spellsLearned;
  final int spellsUpgraded;
  final List<SpellSummary> finalSpells;
  final String? mostUsedSpell;
  final int mostUsedSpellCount;
  final Map<String, int> statusEffectsApplied;
  final List<RelicSummary> relicsAcquired;
  final int fragmentsEarned;
  final int crystalsEarned;
  final int totalHealing;

  const RunSummary({
    required this.seed,
    required this.ascensionLevel,
    required this.victory,
    required this.mageName,
    required this.mageElement,
    required this.depthReached,
    required this.maxDepth,
    this.durationSeconds = 0,
    this.combatsFought = 0,
    this.combatsWon = 0,
    this.elitesDefeated = 0,
    this.bossesDefeated = 0,
    this.totalCombatTurns = 0,
    this.totalDamageDealt = 0,
    this.totalDamageTaken = 0,
    this.damageByElement = const {},
    this.spellsCast = 0,
    this.spellsByElement = const {},
    this.spellsLearned = 0,
    this.spellsUpgraded = 0,
    this.finalSpells = const [],
    this.mostUsedSpell,
    this.mostUsedSpellCount = 0,
    this.statusEffectsApplied = const {},
    this.relicsAcquired = const [],
    this.fragmentsEarned = 0,
    this.crystalsEarned = 0,
    this.totalHealing = 0,
  });

  double get winRate =>
      combatsFought > 0 ? (combatsWon / combatsFought) * 100 : 0;

  double get avgTurnsPerCombat =>
      combatsWon > 0 ? totalCombatTurns / combatsWon : 0;

  String get shareableSeed =>
      seed.toRadixString(16).toUpperCase().padLeft(8, '0');

  String format() {
    final buffer = StringBuffer();
    buffer.writeln('╔══════════════════════════════════════╗');
    buffer.writeln(
      victory
          ? '║         🎉 VICTORY! 🎉               ║'
          : '║         💀 DEFEAT 💀                 ║',
    );
    buffer.writeln('╚══════════════════════════════════════╝');
    buffer.writeln('');
    buffer.writeln('─── RUN INFO ───');
    buffer.writeln('Seed: $shareableSeed');
    if (ascensionLevel > 0) buffer.writeln('Ascension: $ascensionLevel');
    buffer.writeln('Mage: $mageName (${mageElement.displayName})');
    buffer.writeln('Depth: $depthReached / $maxDepth');
    buffer.writeln('');
    buffer.writeln('─── COMBAT ───');
    buffer.writeln('Battles: $combatsWon / $combatsFought');
    buffer.writeln('Elites: $elitesDefeated | Damage Dealt: $totalDamageDealt');
    buffer.writeln('');
    buffer.writeln('─── REWARDS ───');
    buffer.writeln('💎 Fragments: $fragmentsEarned');
    if (crystalsEarned > 0) buffer.writeln('✨ Crystals: $crystalsEarned');
    return buffer.toString();
  }
}

class SpellSummary {
  final String name;
  final Element element;
  final int starLevel;
  final int timesUsed;

  const SpellSummary({
    required this.name,
    required this.element,
    required this.starLevel,
    this.timesUsed = 0,
  });

  String get starsDisplay => '★' * starLevel + '☆' * (3 - starLevel);
  String get elementIcon => element.icon;

  factory SpellSummary.fromSpell(Spell spell, {int timesUsed = 0}) {
    return SpellSummary(
      name: spell.name,
      element: spell.element,
      starLevel: spell.starLevel,
      timesUsed: timesUsed,
    );
  }
}

class RelicSummary {
  final String name;
  final RelicRarity rarity;
  final int timesTriggered;

  const RelicSummary({
    required this.name,
    required this.rarity,
    this.timesTriggered = 0,
  });

  String get rarityIcon => rarity.icon;

  factory RelicSummary.fromRelic(Relic relic, {int timesTriggered = 0}) {
    return RelicSummary(
      name: relic.name,
      rarity: relic.rarity,
      timesTriggered: timesTriggered,
    );
  }
}
