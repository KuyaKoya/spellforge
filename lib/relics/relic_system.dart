import '../core/seeded_random.dart';
import '../domain/element.dart';
import 'relic.dart';

/// System for managing relics during a run.
class RelicSystem {
  /// Relics currently held by the player.
  final List<Relic> _relics = [];

  /// Relics that have been offered but not taken (for tracking).
  final Set<String> _offeredRelicIds = {};

  /// Maximum number of relics the player can hold.
  static const int maxRelics = 10;

  /// Gets all current relics.
  List<Relic> get relics => List.unmodifiable(_relics);

  /// Gets relic count.
  int get count => _relics.length;

  /// Whether the player can acquire more relics.
  bool get canAcquireMore => _relics.length < maxRelics;

  /// Clears all relics for a new run.
  void clear() {
    _relics.clear();
    _offeredRelicIds.clear();
  }

  /// Attempts to acquire a relic.
  /// Returns true if successful.
  bool acquireRelic(Relic relic) {
    if (!canAcquireMore && !relic.stackable) {
      return false;
    }

    // Check for stacking
    if (relic.stackable) {
      final existing = _relics.where((r) => r.id == relic.id).toList();
      if (existing.isNotEmpty) {
        existing.first.stackCount++;
        return true;
      }
    }

    // Check for duplicates (non-stackable)
    if (_relics.any((r) => r.id == relic.id)) {
      return false;
    }

    _relics.add(relic.copy());
    return true;
  }

  /// Removes a relic by ID.
  bool removeRelic(String id) {
    final index = _relics.indexWhere((r) => r.id == id);
    if (index >= 0) {
      _relics.removeAt(index);
      return true;
    }
    return false;
  }

  /// Checks if the player has a specific relic.
  bool hasRelic(String id) {
    return _relics.any((r) => r.id == id);
  }

  /// Gets a relic by ID.
  Relic? getRelic(String id) {
    try {
      return _relics.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Gets all relics with a specific trigger.
  List<Relic> getRelicsWithTrigger(RelicTrigger trigger) {
    return _relics.where((r) => r.trigger == trigger).toList();
  }

  /// Gets all relics with a specific synergy tag.
  List<Relic> getRelicsWithTag(String tag) {
    return _relics.where((r) => r.synergyTags.contains(tag)).toList();
  }

  /// Generates relic choices for a reward.
  List<Relic> generateRelicChoices({
    required int depth,
    required Element playerElement,
    required SeededRandom random,
    int count = 3,
    double synergyBias = 0.5,
  }) {
    // Build weighted pool
    final pool = <Relic>[];
    final weights = <Relic, double>{};

    for (final relic in RelicDefinitions.allRelics) {
      // Skip already owned non-stackable relics
      if (!relic.stackable && hasRelic(relic.id)) continue;

      // Add to pool
      final relicCopy = relic.copy();
      pool.add(relicCopy);

      // Calculate weight
      double weight = 1.0;

      // Rarity weighting
      switch (relic.rarity) {
        case RelicRarity.common:
          weight *= 1.0;
          break;
        case RelicRarity.uncommon:
          weight *= 0.6;
          break;
        case RelicRarity.rare:
          weight *= 0.3;
          break;
        case RelicRarity.legendary:
          weight *= 0.1;
          break;
      }

      // Depth scaling for rarer relics
      if (depth >= 5 && relic.rarity == RelicRarity.rare) {
        weight *= 1.5;
      }
      if (depth >= 8 && relic.rarity == RelicRarity.legendary) {
        weight *= 2.0;
      }

      // Synergy bias
      if (relic.synergyElements.contains(playerElement)) {
        weight *= (1.0 + synergyBias);
      }

      // Reduce weight for already offered relics
      if (_offeredRelicIds.contains(relic.id)) {
        weight *= 0.5;
      }

      weights[relicCopy] = weight;
    }

    // Select relics
    final selected = <Relic>[];
    for (int i = 0; i < count && pool.isNotEmpty; i++) {
      final relic = random.nextWeighted(weights);
      selected.add(relic);
      pool.remove(relic);
      weights.remove(relic);

      // Track offered
      _offeredRelicIds.add(relic.id);
    }

    return selected;
  }

  /// Calculates total synergy score with current build.
  double calculateSynergyScore(Element primaryElement) {
    if (_relics.isEmpty) return 0.0;

    double score = 0.0;
    final tagCounts = <String, int>{};

    for (final relic in _relics) {
      // Element synergy
      if (relic.synergyElements.contains(primaryElement)) {
        score += 0.1;
      }

      // Tag synergy (matching tags between relics)
      for (final tag in relic.synergyTags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    // Bonus for tag combinations
    for (final count in tagCounts.values) {
      if (count >= 2) score += 0.1 * (count - 1);
    }

    return score.clamp(0.0, 1.0);
  }

  /// Gets a display summary of all relics.
  String getSummary() {
    if (_relics.isEmpty) return 'No relics';

    final buffer = StringBuffer();
    buffer.writeln('=== RELICS (${_relics.length}/$maxRelics) ===');
    for (final relic in _relics) {
      buffer.writeln(relic.fullDisplay);
      buffer.writeln('  ${relic.description}');
    }
    return buffer.toString();
  }
}
