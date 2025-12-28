import '../domain/mage.dart';
import '../domain/spell.dart';
import '../domain/element.dart';
import '../relics/relic.dart';

/// Metrics observed by the Director to evaluate player performance.
/// All metrics are derived from observable game state.
class PressureMetrics {
  // ==================== HP METRICS ====================

  /// Current HP as percentage (0.0 - 1.0)
  final double hpPercentage;

  /// HP trend over last 3 nodes (-1.0 to 1.0, negative = losing HP)
  final double hpTrend;

  // ==================== COMBAT METRICS ====================

  /// Average turns to clear encounters (lower = better)
  final double avgTurnsToClear;

  /// Combat win rate (0.0 - 1.0)
  final double combatWinRate;

  /// Damage taken per combat average
  final double avgDamagePerCombat;

  // ==================== BUILD METRICS ====================

  /// Average star level of spells (1.0 - 3.0)
  final double avgSpellStarLevel;

  /// Number of spells in loadout (0 - 4)
  final int spellCount;

  /// Number of relics acquired
  final int relicCount;

  /// Synergy score of current build (0.0 - 1.0)
  final double synergryScore;

  // ==================== ELEMENT METRICS ====================

  /// Most used element
  final Element? dominantElement;

  /// Element usage distribution (0.0 - 1.0 for each)
  final Map<Element, double> elementUsage;

  // ==================== PROGRESSION METRICS ====================

  /// Current depth in the run
  final int currentDepth;

  /// Total depth of the run
  final int maxDepth;

  /// Nodes completed successfully
  final int nodesCompleted;

  /// Elites defeated
  final int elitesDefeated;

  const PressureMetrics({
    this.hpPercentage = 1.0,
    this.hpTrend = 0.0,
    this.avgTurnsToClear = 3.0,
    this.combatWinRate = 1.0,
    this.avgDamagePerCombat = 0.0,
    this.avgSpellStarLevel = 1.0,
    this.spellCount = 1,
    this.relicCount = 0,
    this.synergryScore = 0.0,
    this.dominantElement,
    this.elementUsage = const {},
    this.currentDepth = 1,
    this.maxDepth = 10,
    this.nodesCompleted = 0,
    this.elitesDefeated = 0,
  });

  /// Calculates the pressure score from metrics.
  /// Returns a value from -100 to 100.
  /// Positive = player dominating, Negative = player struggling.
  int calculatePressureScore() {
    double score = 0;

    // HP factor (weight: 30)
    // High HP = +15, Low HP = -15
    score += (hpPercentage - 0.5) * 30;

    // HP trend factor (weight: 20)
    // Gaining HP = +10, Losing HP = -10
    score += hpTrend * 20;

    // Combat efficiency factor (weight: 25)
    // Fast clears = +12.5, Slow clears = -12.5
    // Expected turns: 3-4, excellent: <2, poor: >5
    final turnEfficiency = (4.0 - avgTurnsToClear).clamp(-2.0, 2.0) / 2.0;
    score += turnEfficiency * 25;

    // Build strength factor (weight: 15)
    // Strong build = +7.5, Weak build = -7.5
    final buildStrength =
        ((avgSpellStarLevel - 1.0) / 2.0) + (relicCount * 0.1);
    score += (buildStrength - 0.5) * 15;

    // Damage taken factor (weight: 10)
    // Low damage = +5, High damage = -5
    final damageScore = (20.0 - avgDamagePerCombat).clamp(-10.0, 10.0) / 10.0;
    score += damageScore * 10;

    return score.round().clamp(-100, 100);
  }

  /// Creates metrics from current game state.
  factory PressureMetrics.fromGameState({
    required Mage mage,
    required List<Relic> relics,
    required int currentDepth,
    required int maxDepth,
    required List<int> recentHpHistory,
    required List<int> turnsToClearHistory,
    required List<int> damagePerCombatHistory,
    required int nodesCompleted,
    required int elitesDefeated,
    required Map<Element, int> elementUsageCounts,
  }) {
    // Calculate HP percentage
    final hpPercentage = mage.currentHP / mage.maxHP;

    // Calculate HP trend from history
    double hpTrend = 0.0;
    if (recentHpHistory.length >= 2) {
      final recent = recentHpHistory.take(3).toList();
      if (recent.length >= 2) {
        hpTrend = (recent.first - recent.last) / mage.maxHP;
      }
    }

    // Calculate average turns to clear
    double avgTurns = 3.0;
    if (turnsToClearHistory.isNotEmpty) {
      avgTurns =
          turnsToClearHistory.reduce((a, b) => a + b) /
          turnsToClearHistory.length;
    }

    // Calculate average damage per combat
    double avgDamage = 0.0;
    if (damagePerCombatHistory.isNotEmpty) {
      avgDamage =
          damagePerCombatHistory.reduce((a, b) => a + b) /
          damagePerCombatHistory.length;
    }

    // Calculate spell metrics
    double avgStarLevel = 1.0;
    if (mage.spellLoadout.isNotEmpty) {
      avgStarLevel =
          mage.spellLoadout.map((s) => s.starLevel).reduce((a, b) => a + b) /
          mage.spellLoadout.length;
    }

    // Calculate synergy score
    double synergyScore = _calculateSynergyScore(mage.spellLoadout, relics);

    // Calculate element usage
    final totalUsage = elementUsageCounts.values.fold(0, (a, b) => a + b);
    Map<Element, double> elementUsage = {};
    Element? dominant;
    int maxUsage = 0;

    for (final element in Element.values) {
      final count = elementUsageCounts[element] ?? 0;
      elementUsage[element] = totalUsage > 0 ? count / totalUsage : 0.0;
      if (count > maxUsage) {
        maxUsage = count;
        dominant = element;
      }
    }

    return PressureMetrics(
      hpPercentage: hpPercentage,
      hpTrend: hpTrend.clamp(-1.0, 1.0),
      avgTurnsToClear: avgTurns,
      combatWinRate: 1.0, // Assumed since player is still alive
      avgDamagePerCombat: avgDamage,
      avgSpellStarLevel: avgStarLevel,
      spellCount: mage.spellLoadout.length,
      relicCount: relics.length,
      synergryScore: synergyScore,
      dominantElement: dominant,
      elementUsage: elementUsage,
      currentDepth: currentDepth,
      maxDepth: maxDepth,
      nodesCompleted: nodesCompleted,
      elitesDefeated: elitesDefeated,
    );
  }

  /// Calculates synergy score between spells and relics.
  static double _calculateSynergyScore(List<Spell> spells, List<Relic> relics) {
    if (spells.isEmpty) return 0.0;

    double score = 0.0;
    final elements = spells.map((s) => s.element).toSet();

    // Element focus bonus
    if (elements.length == 1) {
      score += 0.3; // Mono-element build
    } else if (elements.length == 2) {
      score += 0.15; // Dual-element build
    }

    // Relic synergy
    for (final relic in relics) {
      for (final tag in relic.synergyTags) {
        // Check if spells match relic synergy tags
        if (tag == 'burn' && spells.any((s) => s.element == Element.fire)) {
          score += 0.1;
        }
        if (tag == 'control' && spells.any((s) => s.element == Element.water)) {
          score += 0.1;
        }
        if (tag == 'defense' && spells.any((s) => s.element == Element.earth)) {
          score += 0.1;
        }
        if (tag == 'speed' && spells.any((s) => s.element == Element.air)) {
          score += 0.1;
        }
      }
    }

    return score.clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return '''PressureMetrics(
  HP: ${(hpPercentage * 100).toStringAsFixed(1)}% (trend: ${hpTrend.toStringAsFixed(2)})
  Avg Turns: ${avgTurnsToClear.toStringAsFixed(1)}
  Spell Stars: ${avgSpellStarLevel.toStringAsFixed(1)} ($spellCount spells)
  Relics: $relicCount
  Depth: $currentDepth/$maxDepth
  Pressure Score: ${calculatePressureScore()}
)''';
  }
}
