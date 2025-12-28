/// Director pressure states that influence game pacing.
/// The Director operates in one of three states based on player performance.
enum DirectorPressureState {
  /// Expected difficulty - no adjustments
  neutral,

  /// Player overperforming - increase challenge
  aggressive,

  /// Player struggling - provide assistance
  merciful;

  String get displayName {
    switch (this) {
      case DirectorPressureState.neutral:
        return 'Neutral';
      case DirectorPressureState.aggressive:
        return 'Aggressive';
      case DirectorPressureState.merciful:
        return 'Merciful';
    }
  }

  String get description {
    switch (this) {
      case DirectorPressureState.neutral:
        return 'Standard difficulty pacing';
      case DirectorPressureState.aggressive:
        return 'Increased challenge due to player dominance';
      case DirectorPressureState.merciful:
        return 'Reduced difficulty to assist struggling player';
    }
  }
}

/// Represents the complete state of the Director at any point in a run.
class DirectorState {
  /// Current pressure state
  DirectorPressureState pressureState;

  /// Turns since last state change (for cooldown)
  int turnsSinceStateChange;

  /// Minimum turns before state can change again
  static const int stateChangeCooldown = 3;

  /// Accumulated pressure score (-100 to 100)
  /// Negative = player struggling, Positive = player dominating
  int pressureScore;

  /// Thresholds for state transitions
  static const int aggressiveThreshold = 40;
  static const int mercifulThreshold = -40;

  DirectorState({
    this.pressureState = DirectorPressureState.neutral,
    this.turnsSinceStateChange = 0,
    this.pressureScore = 0,
  });

  /// Whether the state can change (cooldown expired)
  bool get canChangeState => turnsSinceStateChange >= stateChangeCooldown;

  /// Resets the director state for a new run.
  void reset() {
    pressureState = DirectorPressureState.neutral;
    turnsSinceStateChange = 0;
    pressureScore = 0;
  }

  /// Creates a copy of this state.
  DirectorState copy() {
    return DirectorState(
      pressureState: pressureState,
      turnsSinceStateChange: turnsSinceStateChange,
      pressureScore: pressureScore,
    );
  }

  @override
  String toString() =>
      'DirectorState(${pressureState.displayName}, score: $pressureScore, cooldown: $turnsSinceStateChange)';
}
