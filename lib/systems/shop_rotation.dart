import 'dart:math';
import '../data/item_definitions.dart';

/// Manages the daily shop rotation for relics.
class ShopRotation {
  /// Get today's rotating relic offers based on date seed.
  /// Returns 2-3 relics that change daily.
  static List<RelicItem> getDailyRelics(
    DateTime date,
    List<String> ownedRelics,
  ) {
    // Create a seed from the date (same seed = same relics for the day)
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final random = Random(seed);

    // Filter out already owned relics
    final available = ItemRegistry.relics
        .where((r) => !ownedRelics.contains(r.id))
        .toList();

    if (available.isEmpty) return [];

    // Shuffle with the seeded random
    available.shuffle(random);

    // Return 2-3 relics, varying by day
    final count = 2 + (seed % 2); // 2 or 3 relics
    return available.take(count).toList();
  }

  /// Get the crystal cost for a relic based on rarity.
  static int getRelicCost(RelicItem relic) {
    switch (relic.rarity) {
      case 1: // Common
        return 50;
      case 2: // Uncommon
        return 90;
      case 3: // Rare
        return 150;
      default:
        return 60;
    }
  }

  /// Check if the shop should refresh (new day).
  static bool shouldRefresh(DateTime lastVisit, DateTime now) {
    return lastVisit.year != now.year ||
        lastVisit.month != now.month ||
        lastVisit.day != now.day;
  }
}
