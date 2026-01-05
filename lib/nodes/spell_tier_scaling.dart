// Phase 7.6: Spell Learn Node Tier Scaling
//
// Spell Learn nodes no longer offer flat rarity.
// Instead, maximum tier increases with depth.

import 'dart:math';
import '../domain/spell.dart';
import '../domain/element.dart';

/// Configuration for depth-based spell tier availability.
class SpellTierConfig {
  /// Gets the maximum spell rarity available at a given run depth.
  ///
  /// Depth-based tier progression (Phase 7.6 - Rule 14.1):
  /// - Depth 1-2: Common only
  /// - Depth 3-4: Common + Uncommon
  /// - Depth 5-6: Common + Uncommon + Rare
  /// - Depth 7+:  All tiers + Star Upgrade Chance
  static SpellRarity getMaxRarityForDepth(int depth) {
    if (depth <= 2) return SpellRarity.common;
    if (depth <= 4) return SpellRarity.uncommon;
    if (depth <= 6) return SpellRarity.rare;
    return SpellRarity.rare; // At 7+, rare but with star upgrade chance
  }

  /// Gets the chance of a star upgrade injection at a given depth (Phase 7.6 - Rule 14.2).
  /// Returns 0.0-1.0 representing the probability.
  ///
  /// At deeper depths, Spell Learn nodes may offer:
  /// - ★★ versions of existing spells
  /// - Or a Rare spell with 1 modifier
  static double getStarUpgradeChance(int depth) {
    if (depth <= 6) return 0.0;
    if (depth == 7) return 0.15;
    if (depth == 8) return 0.25;
    if (depth >= 9) return 0.35;
    return 0.0;
  }

  /// Gets available rarities at a given depth.
  static List<SpellRarity> getAvailableRarities(int depth) {
    final maxRarity = getMaxRarityForDepth(depth);
    final rarities = <SpellRarity>[];

    for (final rarity in SpellRarity.values) {
      // Signature spells are never offered at spell learn nodes
      if (rarity == SpellRarity.signature) continue;

      rarities.add(rarity);

      if (rarity == maxRarity) break;
    }

    return rarities;
  }

  /// Gets rarity weights for selection at a given depth.
  /// Higher tiers have lower weights to make them feel special.
  static Map<SpellRarity, double> getRarityWeights(int depth) {
    final weights = <SpellRarity, double>{};
    final available = getAvailableRarities(depth);

    for (final rarity in available) {
      switch (rarity) {
        case SpellRarity.common:
          // Common weight decreases as depth increases
          weights[rarity] = depth <= 2 ? 1.0 : (depth <= 4 ? 0.6 : 0.4);
          break;
        case SpellRarity.uncommon:
          weights[rarity] = depth <= 4 ? 0.4 : 0.35;
          break;
        case SpellRarity.rare:
          weights[rarity] = 0.25;
          break;
        case SpellRarity.signature:
          // Never offered at spell learn nodes
          break;
      }
    }

    return weights;
  }
}

/// Manages spell selection for Spell Learn nodes with depth-based tier scaling.
class SpellLearnSelector {
  final Random _random;

  SpellLearnSelector({int? seed})
    : _random = seed != null ? Random(seed) : Random();

  /// Selects spell choices for a Spell Learn node.
  ///
  /// [depth] - Current run depth (1-indexed)
  /// [availableSpells] - Pool of all possible spells
  /// [startingElement] - Player's starting element (for bias)
  /// [weaknessElement] - Player's weakness element (for penalty)
  /// [count] - Number of spell choices to offer (default: 3)
  List<Spell> selectSpellChoices({
    required int depth,
    required List<Spell> availableSpells,
    Element? startingElement,
    Element? weaknessElement,
    int count = 3,
  }) {
    if (availableSpells.isEmpty) return [];

    // Filter spells by available rarities at this depth
    final availableRarities = SpellTierConfig.getAvailableRarities(depth);
    final eligibleSpells = availableSpells
        .where((s) => availableRarities.contains(s.rarity))
        .toList();

    if (eligibleSpells.isEmpty) return [];

    // Calculate weights for each spell (Phase 7.6 - Rule 14.3)
    final weightedSpells = <Spell, double>{};

    for (final spell in eligibleSpells) {
      double weight = 1.0;

      // Base weight from rarity
      final rarityWeights = SpellTierConfig.getRarityWeights(depth);
      weight *= rarityWeights[spell.rarity] ?? 1.0;

      // Starting type bias (Phase 7.6.1: 1.2x weight for starting element)
      if (startingElement != null && spell.element == startingElement) {
        weight *= 1.2;
      }

      // Depth tier bias (favor higher tiers at deeper depths)
      if (depth >= 5 && spell.rarity == SpellRarity.rare) {
        weight += 0.15;
      }
      if (depth >= 3 && spell.rarity == SpellRarity.uncommon) {
        weight += 0.1;
      }

      // Weakness penalty (Phase 7.6 - Rule 14.3: never reduces to zero)
      if (weaknessElement != null && spell.element == weaknessElement) {
        weight = (weight * 0.5).clamp(0.1, double.infinity);
      }

      weightedSpells[spell] = weight;
    }

    // Select spells using weighted random
    final selected = <Spell>[];
    final remaining = Map<Spell, double>.from(weightedSpells);

    for (int i = 0; i < count && remaining.isNotEmpty; i++) {
      final spell = _weightedRandomSelect(remaining);
      if (spell != null) {
        // Check for star upgrade (Phase 7.6 - Rule 14.2)
        final starUpgradeChance = SpellTierConfig.getStarUpgradeChance(depth);
        if (spell.starLevel < 2 && _random.nextDouble() < starUpgradeChance) {
          // Upgrade to ★★ version
          selected.add(spell.upgrade());
        } else {
          selected.add(spell);
        }
        remaining.remove(spell);
      }
    }

    return selected;
  }

  /// Performs weighted random selection from a map of items with weights.
  Spell? _weightedRandomSelect(Map<Spell, double> weightedItems) {
    if (weightedItems.isEmpty) return null;

    final totalWeight = weightedItems.values.fold(0.0, (a, b) => a + b);
    if (totalWeight <= 0) return weightedItems.keys.first;

    double roll = _random.nextDouble() * totalWeight;

    for (final entry in weightedItems.entries) {
      roll -= entry.value;
      if (roll <= 0) return entry.key;
    }

    return weightedItems.keys.last;
  }
}

/// Extension to get display information for spell tiers at Spell Learn nodes.
extension SpellLearnDisplay on SpellRarity {
  /// Gets the tier badge text for UI display.
  String get tierBadge {
    switch (this) {
      case SpellRarity.common:
        return 'Common';
      case SpellRarity.uncommon:
        return 'Uncommon';
      case SpellRarity.rare:
        return 'Rare';
      case SpellRarity.signature:
        return 'Signature';
    }
  }

  /// Gets the badge color for UI display (as hex).
  int get badgeColorHex {
    switch (this) {
      case SpellRarity.common:
        return 0xFF8b949e; // Gray
      case SpellRarity.uncommon:
        return 0xFF3fb950; // Green
      case SpellRarity.rare:
        return 0xFF58a6ff; // Blue
      case SpellRarity.signature:
        return 0xFFf0b429; // Gold
    }
  }
}
