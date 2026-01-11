import '../data/spell_definitions.dart';
import '../domain/spell.dart';
import '../domain/mage.dart';
import '../progression/spell_pool_manager.dart';
import '../progression/account_unlocks.dart';
import '../domain/element.dart';

/// Result of resolving rewards for elite/boss combat.
class RewardResult {
  /// Currency rewards
  final int fragments;
  final int crystals;

  /// Healing amount (percentage of max HP)
  final double healPercent;

  /// Spell choices for learning/enhancement
  final List<Spell> spellChoices;

  /// Legendary spell unlocked (boss first clear only)
  final Spell? legendaryUnlock;

  /// Whether this is a first clear bonus
  final bool isFirstClear;

  /// Description for display
  final String description;

  const RewardResult({
    required this.fragments,
    this.crystals = 0,
    this.healPercent = 0.0,
    this.spellChoices = const [],
    this.legendaryUnlock,
    this.isFirstClear = false,
    this.description = '',
  });
}

/// Resolves guaranteed rewards for elite and boss encounters.
///
/// Phase 7.9.5: Implements guaranteed reward structure:
/// - Elites: Flat % heal + currency + spell progression (learn or enhance)
/// - Bosses: Full/near-full heal + large currency + guaranteed spell outcome + legendary unlock (first clear)
class RewardResolver {
  // ==================== ELITE REWARDS ====================

  /// Resolve elite rewards.
  ///
  /// Elite defeated:
  /// - 15% HP heal
  /// - 50-75 fragments (scaled by depth)
  /// - Spell choice: learn new spell OR enhance existing (player chooses)
  static RewardResult resolveEliteRewards({
    required Mage mage,
    required int depth,
    required String eliteId,
    Element? preferElement,
  }) {
    // Record the defeat
    AccountUnlocks.instance.recordEliteDefeat();

    // Calculate fragment reward (50 base + 5 per depth)
    final fragments = 50 + (depth * 5);

    // Heal percentage
    const healPercent = 0.15; // 15% of max HP

    // Generate spell choices for learning
    final knownSpellIds = mage.spellLoadout.map((s) => s.id).toSet();
    final availableSpells = SpellPoolManager.instance
        .getAvailableSpellsForLearning(excludeIds: knownSpellIds.toList());

    // Select up to 3 spells, prioritizing player's element or preferred element
    List<Spell> spellChoices = [];
    final priorityElement = preferElement ?? mage.primaryElement;

    if (availableSpells.isNotEmpty) {
      // Prioritize same element
      final sameElement = availableSpells
          .where((s) => s.element == priorityElement)
          .toList();
      final otherElement = availableSpells
          .where((s) => s.element != priorityElement)
          .toList();

      sameElement.shuffle();
      otherElement.shuffle();

      // Take 1-2 same element + 1 other element
      spellChoices = [...sameElement.take(2), ...otherElement.take(1)];

      if (spellChoices.isEmpty) {
        spellChoices = availableSpells.take(3).toList();
      }
    }

    return RewardResult(
      fragments: fragments,
      crystals: 0,
      healPercent: healPercent,
      spellChoices: spellChoices,
      description: 'Elite defeated! Choose your reward.',
    );
  }

  // ==================== BOSS REWARDS ====================

  /// Resolve boss rewards.
  ///
  /// Boss defeated:
  /// - 75% HP heal
  /// - 100-150 fragments (scaled by depth)
  /// - 1-2 crystals
  /// - Legendary spell unlock (first clear only)
  /// - Spell choice: guaranteed high-tier spell
  static Future<RewardResult> resolveBossRewards({
    required Mage mage,
    required int depth,
    required String bossId,
  }) async {
    // Record the defeat
    await AccountUnlocks.instance.recordBossDefeat();

    // Check for first clear legendary unlock
    final legendaryUnlock = await SpellPoolManager.instance
        .recordBossFirstClear(bossId);
    final isFirstClear = legendaryUnlock != null;

    // Calculate rewards
    final fragments = 100 + (depth * 10);
    final crystals = isFirstClear ? 2 : 1; // Bonus crystal for first clear

    // Heal percentage (higher for boss)
    const healPercent = 0.75; // 75% of max HP

    // Generate high-tier spell choices
    final knownSpellIds = mage.spellLoadout.map((s) => s.id).toSet();

    // For boss rewards, offer rare spells or signature spells
    List<Spell> spellChoices = [];
    final rareSpells = SpellDefinitions.rareSpells
        .where((s) => !knownSpellIds.contains(s.id))
        .toList();
    final signatureSpells = SpellDefinitions.signatureSpells
        .where(
          (s) =>
              !knownSpellIds.contains(s.id) &&
              SpellPoolManager.instance.isSpellUnlocked(s.id),
        )
        .toList();

    rareSpells.shuffle();
    signatureSpells.shuffle();

    spellChoices = [...signatureSpells.take(1), ...rareSpells.take(2)];

    // If we got a legendary unlock, add it to choices
    if (legendaryUnlock != null) {
      spellChoices.insert(0, legendaryUnlock);
    }

    String description = isFirstClear
        ? '🏆 FIRST CLEAR! Legendary spell unlocked!'
        : 'Boss defeated! The threshold opens.';

    return RewardResult(
      fragments: fragments,
      crystals: crystals,
      healPercent: healPercent,
      spellChoices: spellChoices,
      legendaryUnlock: legendaryUnlock,
      isFirstClear: isFirstClear,
      description: description,
    );
  }

  // ==================== UTILITY ====================

  /// Calculate actual heal amount from percentage
  static int calculateHealAmount(int maxHP, double healPercent) {
    return (maxHP * healPercent).round();
  }

  /// Get reward tier display name
  static String getRewardTierName(bool isElite, bool isBoss) {
    if (isBoss) return '🏆 Boss Victory';
    if (isElite) return '⚔️ Elite Victory';
    return '✓ Victory';
  }
}
