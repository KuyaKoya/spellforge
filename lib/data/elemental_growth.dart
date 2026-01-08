import '../domain/element.dart';

/// Phase 7.9.4: Elemental Growth Tables
///
/// Defines explicit EXP thresholds and per-element stat growth per level.
/// All values are immutable and must not be procedurally inferred.
class ElementalGrowth {
  ElementalGrowth._();

  // ==================== EXP THRESHOLDS ====================

  /// Explicit EXP required to reach the next level.
  /// Key: current level, Value: EXP needed for next level.
  static const Map<int, int> expThresholds = {
    1: 40, // Level 1 → 2
    2: 60, // Level 2 → 3
    3: 90, // Level 3 → 4
    4: 130, // Level 4 → 5
    5: 180, // Level 5 → 6
    6: 250, // Level 6 → 7
    7: 340, // Level 7 → 8
    8: 450, // Level 8 → 9
    9: 600, // Level 9 → 10
  };

  /// Maximum player level.
  static const int maxLevel = 10;

  /// Gets EXP required to level up from the given level.
  /// Returns 0 if at max level.
  static int expToNextLevel(int level) {
    if (level >= maxLevel) return 0;
    return expThresholds[level] ?? 0;
  }

  /// Gets total EXP required to reach a target level from level 1.
  static int totalExpForLevel(int targetLevel) {
    if (targetLevel <= 1) return 0;
    int total = 0;
    for (int lvl = 1; lvl < targetLevel && lvl < maxLevel; lvl++) {
      total += expThresholds[lvl] ?? 0;
    }
    return total;
  }

  /// Calculates what level corresponds to a given total EXP earned.
  static int levelForTotalExp(int totalExp) {
    int level = 1;
    int accum = 0;
    while (level < maxLevel) {
      final needed = expThresholds[level] ?? 0;
      if (needed == 0 || accum + needed > totalExp) break;
      accum += needed;
      level++;
    }
    return level;
  }

  // ==================== GROWTH TABLES ====================

  /// Per-level stat growth by element.
  /// Fire: High attack, low survivability
  /// Water: High HP/mana, balanced
  /// Earth: Very high HP/defense, minimal speed
  /// Air: High speed, low HP/defense
  static const Map<Element, LevelGrowth> growthTables = {
    Element.fire: LevelGrowth(hp: 3, mana: 2, attack: 4, defense: 1, speed: 2),
    Element.water: LevelGrowth(hp: 5, mana: 4, attack: 2, defense: 2, speed: 1),
    Element.earth: LevelGrowth(hp: 6, mana: 1, attack: 2, defense: 4, speed: 0),
    Element.air: LevelGrowth(hp: 2, mana: 2, attack: 3, defense: 1, speed: 4),
  };

  /// Gets the growth table for an element.
  static LevelGrowth getGrowth(Element element) {
    return growthTables[element] ?? const LevelGrowth();
  }

  /// Calculates accumulated stats from leveling.
  /// [fromLevel]: Starting level (exclusive)
  /// [toLevel]: Ending level (inclusive)
  static LevelGrowth calculateAccumulatedGrowth(
    Element element,
    int fromLevel,
    int toLevel,
  ) {
    if (toLevel <= fromLevel) return const LevelGrowth();

    final growth = getGrowth(element);
    final levels = toLevel - fromLevel;

    return LevelGrowth(
      hp: growth.hp * levels,
      mana: growth.mana * levels,
      attack: growth.attack * levels,
      defense: growth.defense * levels,
      speed: growth.speed * levels,
    );
  }
}

/// Stat growth values per level for an element.
class LevelGrowth {
  final int hp;
  final int mana;
  final int attack;
  final int defense;
  final int speed;

  const LevelGrowth({
    this.hp = 0,
    this.mana = 0,
    this.attack = 0,
    this.defense = 0,
    this.speed = 0,
  });

  @override
  String toString() =>
      'LevelGrowth(hp: +$hp, mana: +$mana, atk: +$attack, def: +$defense, spd: +$speed)';
}
