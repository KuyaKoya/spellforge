import 'director_state.dart';
import 'director_rules.dart';
import 'director_logger.dart';
import 'pressure_metrics.dart';
import '../ascension/ascension.dart';
import '../domain/mage.dart';
import '../domain/element.dart';
import '../relics/relic.dart';
import '../core/seeded_random.dart';

/// The Director observes run state and adjusts selection weights.
/// It never generates new content, overrides player choice, or introduces hidden randomness.
class DirectorSystem {
  /// Current Director state.
  final DirectorState _state = DirectorState();

  /// Director log for debugging.
  final DirectorLogger _logger = DirectorLogger();

  /// Current metrics snapshot.
  PressureMetrics? _currentMetrics;

  /// Current adjustments.
  DirectorAdjustments _currentAdjustments = DirectorAdjustments.neutral;

  /// Current ascension level.
  int _ascensionLevel = 0;

  /// Seeded random for deterministic decisions.
  SeededRandom? _random;

  // ==================== TRACKING DATA ====================

  /// Recent HP values for trend calculation.
  final List<int> _hpHistory = [];

  /// Recent turns-to-clear values.
  final List<int> _turnsToClearHistory = [];

  /// Recent damage taken per combat.
  final List<int> _damagePerCombatHistory = [];

  /// Element usage counts.
  final Map<Element, int> _elementUsageCounts = {};

  /// Nodes completed.
  int _nodesCompleted = 0;

  /// Elites defeated.
  int _elitesDefeated = 0;

  // ==================== ACCESSORS ====================

  /// Current pressure state.
  DirectorPressureState get pressureState => _state.pressureState;

  /// Current adjustments.
  DirectorAdjustments get adjustments => _currentAdjustments;

  /// Current metrics.
  PressureMetrics? get metrics => _currentMetrics;

  /// Director logger.
  DirectorLogger get logger => _logger;

  /// Pressure score.
  int get pressureScore => _state.pressureScore;

  /// Phase 7.9.3: Current state accessor for save/load.
  DirectorState get currentState => _state;

  /// Seeded random for deterministic decisions.
  SeededRandom? get random => _random;

  // ==================== LIFECYCLE ====================

  /// Initializes the Director for a new run.
  void initialize({
    required int seed,
    required int ascensionLevel,
    Element? startingElement,
  }) {
    _state.reset();
    _logger.clear();
    _currentMetrics = null;
    _currentAdjustments = DirectorAdjustments.neutral;
    _ascensionLevel = ascensionLevel;
    _startingElement = startingElement;
    _random = SeededRandom(seed);

    // Clear tracking data
    _hpHistory.clear();
    _turnsToClearHistory.clear();
    _damagePerCombatHistory.clear();
    _elementUsageCounts.clear();
    _nodesCompleted = 0;
    _elitesDefeated = 0;

    _logger.logAction(
      depth: 0,
      action: 'Director initialized',
      details: {'seed': seed, 'ascension': ascensionLevel},
    );
  }

  /// Updates the Director with current game state.
  /// Should be called after each significant game event.
  void update({
    required Mage mage,
    required List<Relic> relics,
    required int currentDepth,
    required int maxDepth,
  }) {
    // Record HP
    _recordHp(mage.currentHP);

    // Calculate metrics
    _currentMetrics = PressureMetrics.fromGameState(
      mage: mage,
      relics: relics,
      currentDepth: currentDepth,
      maxDepth: maxDepth,
      recentHpHistory: _hpHistory,
      turnsToClearHistory: _turnsToClearHistory,
      damagePerCombatHistory: _damagePerCombatHistory,
      nodesCompleted: _nodesCompleted,
      elitesDefeated: _elitesDefeated,
      elementUsageCounts: _elementUsageCounts,
    );

    // Update pressure score
    _state.pressureScore = _currentMetrics!.calculatePressureScore();

    // Evaluate state transition
    final newState = DirectorRuleSet.evaluateState(
      metrics: _currentMetrics!,
      currentState: _state,
      ascensionLevel: _ascensionLevel,
    );

    // Handle state change
    if (newState != _state.pressureState) {
      final reasons = DirectorRuleSet.getReasonCodes(_currentMetrics!);
      _logger.logStateChange(
        depth: currentDepth,
        fromState: _state.pressureState,
        toState: newState,
        reasons: reasons,
        details: {
          'score': _state.pressureScore,
          'hp': '${(mage.currentHP / mage.maxHP * 100).toStringAsFixed(0)}%',
        },
      );

      _state.pressureState = newState;
      _state.turnsSinceStateChange = 0;
    } else {
      _state.turnsSinceStateChange++;
    }

    // Calculate adjustments
    _currentAdjustments = DirectorAdjustments.forState(_state.pressureState);

    // Apply ascension modifiers if applicable
    if (_ascensionLevel > 0) {
      final ascension = AscensionDefinitions.getAscension(_ascensionLevel);
      _currentAdjustments = _currentAdjustments.withAscension(ascension);
    }

    // Validate adjustments
    _currentAdjustments = DirectorRuleSet.validateAdjustments(
      _currentAdjustments,
      _currentMetrics!,
    );
  }

  // ==================== TRACKING METHODS ====================

  /// Records HP for trend calculation.
  void _recordHp(int hp) {
    _hpHistory.insert(0, hp);
    if (_hpHistory.length > 10) {
      _hpHistory.removeLast();
    }
  }

  /// Records combat completion.
  void recordCombatComplete({
    required int turnsTaken,
    required int damageTaken,
    required bool isElite,
  }) {
    _turnsToClearHistory.add(turnsTaken);
    if (_turnsToClearHistory.length > 10) {
      _turnsToClearHistory.removeAt(0);
    }

    _damagePerCombatHistory.add(damageTaken);
    if (_damagePerCombatHistory.length > 10) {
      _damagePerCombatHistory.removeAt(0);
    }

    if (isElite) {
      _elitesDefeated++;
    }
  }

  /// Records spell usage for element tracking.
  void recordSpellUsed(Element element) {
    _elementUsageCounts[element] = (_elementUsageCounts[element] ?? 0) + 1;
  }

  /// Records node completion.
  void recordNodeComplete() {
    _nodesCompleted++;
  }

  // ==================== QUERY METHODS ====================

  /// Gets adjusted elite chance.
  double getAdjustedEliteChance(double baseChance) {
    return (baseChance + _currentAdjustments.eliteChanceModifier).clamp(
      0.0,
      0.5,
    );
  }

  /// Gets adjusted rest node chance.
  double getAdjustedRestChance(double baseChance) {
    return (baseChance + _currentAdjustments.restChanceModifier).clamp(
      0.05,
      0.6,
    );
  }

  /// Gets combat difficulty multiplier.
  double getCombatDifficultyMultiplier() {
    return _currentAdjustments.combatDifficultyModifier;
  }

  /// Gets reward tier modifier.
  int getRewardTierModifier() {
    return _currentAdjustments.rewardTierModifier;
  }

  /// Gets enemy synergy factor (0.0 to 1.0).
  /// Higher = more synergistic enemy compositions.
  double getEnemySynergyFactor() {
    return _currentAdjustments.enemySynergyModifier;
  }

  /// Whether the Director should favor a rest node.
  bool shouldFavorRestNode() {
    return _state.pressureState == DirectorPressureState.merciful;
  }

  /// Whether the Director should favor an elite node.
  bool shouldFavorEliteNode() {
    return _state.pressureState == DirectorPressureState.aggressive;
  }

  /// Starting element chosen by the player.
  Element? _startingElement;

  /// Gets the weight multiplier for a given element.
  /// Used to bias spell drops and enemy generation.
  double getElementWeight(Element element) {
    if (_startingElement == null) return 1.0;

    // Bias: 1.2x for starting element (Phase 7.6.1)
    if (element == _startingElement) {
      return 1.2;
    }

    return 1.0;
  }

  // ==================== DEBUG ====================

  /// Gets a debug summary of the Director state.
  String getDebugSummary() {
    final buffer = StringBuffer();
    buffer.writeln('=== DIRECTOR STATUS ===');
    buffer.writeln('State: ${_state.pressureState.displayName}');
    buffer.writeln('Pressure Score: ${_state.pressureScore}');
    buffer.writeln('Ascension Level: $_ascensionLevel');
    buffer.writeln(
      'Cooldown: ${_state.turnsSinceStateChange}/${DirectorState.stateChangeCooldown}',
    );
    buffer.writeln('');
    buffer.writeln('Adjustments:');
    buffer.writeln(_currentAdjustments.toString());
    buffer.writeln('');
    if (_currentMetrics != null) {
      buffer.writeln('Metrics:');
      buffer.writeln(_currentMetrics.toString());
    }
    return buffer.toString();
  }

  // ==================== PHASE 7.9.3: SAVE/LOAD ====================

  /// Restores director state from save data.
  void restoreState({
    required int pressureScore,
    required int turnsSinceChange,
  }) {
    _state.pressureScore = pressureScore;
    _state.turnsSinceStateChange = turnsSinceChange;

    // Recalculate pressure state from score
    if (pressureScore >= DirectorState.aggressiveThreshold) {
      _state.pressureState = DirectorPressureState.aggressive;
    } else if (pressureScore <= DirectorState.mercifulThreshold) {
      _state.pressureState = DirectorPressureState.merciful;
    } else {
      _state.pressureState = DirectorPressureState.neutral;
    }

    _currentAdjustments = DirectorAdjustments.forState(_state.pressureState);
  }
}
