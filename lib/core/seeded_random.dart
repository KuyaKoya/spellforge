import 'dart:math';

/// A seeded random number generator for deterministic runs.
/// Same seed = same sequence of random values.
class SeededRandom {
  late Random _random;
  final int seed;

  /// Sub-seed offset for different subsystems.
  int _subSeedOffset = 0;

  SeededRandom(this.seed) {
    _random = Random(seed);
  }

  /// Gets the next random integer in range [0, max).
  int nextInt(int max) {
    return _random.nextInt(max);
  }

  /// Gets the next random double in range [0.0, 1.0).
  double nextDouble() {
    return _random.nextDouble();
  }

  /// Gets a random boolean with given probability.
  bool nextBool([double probability = 0.5]) {
    return _random.nextDouble() < probability;
  }

  /// Gets a random element from a list.
  T nextElement<T>(List<T> list) {
    if (list.isEmpty) {
      throw ArgumentError('Cannot get random element from empty list');
    }
    return list[_random.nextInt(list.length)];
  }

  /// Gets multiple random elements from a list (without replacement).
  List<T> nextElements<T>(List<T> list, int count) {
    if (count > list.length) {
      throw ArgumentError(
        'Cannot get $count elements from list of ${list.length}',
      );
    }
    final copy = List<T>.from(list);
    final result = <T>[];
    for (int i = 0; i < count; i++) {
      final index = _random.nextInt(copy.length);
      result.add(copy.removeAt(index));
    }
    return result;
  }

  /// Shuffles a list in place and returns it.
  List<T> shuffle<T>(List<T> list) {
    for (int i = list.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
    return list;
  }

  /// Gets a random value from a weighted distribution.
  /// Weights map values to their relative weights.
  T nextWeighted<T>(Map<T, double> weights) {
    if (weights.isEmpty) {
      throw ArgumentError('Cannot get weighted random from empty map');
    }

    final totalWeight = weights.values.reduce((a, b) => a + b);
    var roll = _random.nextDouble() * totalWeight;

    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll <= 0) {
        return entry.key;
      }
    }

    return weights.keys.last;
  }

  /// Creates a sub-random generator with a derived seed.
  /// Useful for isolating randomness between subsystems.
  SeededRandom derive(String subsystem) {
    final subSeed = seed ^ subsystem.hashCode ^ (_subSeedOffset++);
    return SeededRandom(subSeed);
  }

  /// Gets a random integer in a range [min, max] (inclusive).
  int nextIntRange(int min, int max) {
    return min + _random.nextInt(max - min + 1);
  }

  /// Gets a random double in a range [min, max).
  double nextDoubleRange(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  /// Resets the random generator to its initial state.
  void reset() {
    _random = Random(seed);
    _subSeedOffset = 0;
  }

  @override
  String toString() => 'SeededRandom(seed: $seed)';
}

/// Service for managing seeded randomness across a run.
class SeededRandomService {
  SeededRandom? _runRandom;
  int? _currentSeed;

  /// The current run seed.
  int? get currentSeed => _currentSeed;

  /// Whether a seeded run is active.
  bool get isSeededRunActive => _runRandom != null;

  /// Initializes a new seeded run.
  void initializeRun(int seed) {
    _currentSeed = seed;
    _runRandom = SeededRandom(seed);
  }

  /// Gets the main random generator for the run.
  SeededRandom get runRandom {
    if (_runRandom == null) {
      throw StateError('No seeded run is active');
    }
    return _runRandom!;
  }

  /// Gets a derived random generator for a specific subsystem.
  SeededRandom getSubsystem(String name) {
    return runRandom.derive(name);
  }

  /// Generates a random seed based on current time.
  static int generateRandomSeed() {
    return DateTime.now().microsecondsSinceEpoch;
  }

  /// Parses a seed from a string (for sharing runs).
  static int? parseSeed(String seedString) {
    return int.tryParse(seedString);
  }

  /// Formats a seed for display and sharing.
  static String formatSeed(int seed) {
    // Format as 8-character hex string for readability
    return seed.toRadixString(16).toUpperCase().padLeft(8, '0');
  }

  /// Ends the current seeded run.
  void endRun() {
    _runRandom = null;
    _currentSeed = null;
  }
}
