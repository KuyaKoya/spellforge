import 'dart:math';
import '../data/enemy_definitions.dart';
import '../data/elite_definitions.dart';
import '../data/spell_definitions.dart';
import '../domain/enemy.dart';
import '../domain/elite_enemy.dart';
import '../domain/mage.dart';
import '../domain/spell.dart';
import 'difficulty_scaler.dart';
import 'shop_system.dart';

/// Handles resolving node encounters, generating content, and rewards.
class NodeResolver {
  NodeResolver._();

  // ==================== COMBAT GENERATION ====================

  /// Generates a standard combat encounter for the given depth.
  static List<Enemy> generateCombatEncounter(int depth) {
    final minEnemies = DifficultyScaler.getMinEnemies(depth);
    final maxEnemies = DifficultyScaler.getMaxEnemies(depth);
    final hpMultiplier = DifficultyScaler.getHPMultiplier(depth);
    final damageBonus = DifficultyScaler.getDamageBonus(depth);

    final enemies = EnemyDefinitions.generateEncounter(
      minEnemies: minEnemies,
      maxEnemies: maxEnemies,
      difficultyLevel: 1,
    );

    // Apply depth scaling
    return enemies.map((enemy) {
      final scaledHP = (enemy.maxHP * hpMultiplier).round();
      final scaledDamage = enemy.attackDamage + damageBonus;

      return Enemy(
        id: enemy.id,
        name: enemy.name,
        element: enemy.element,
        currentHP: scaledHP,
        maxHP: scaledHP,
        attackDamage: scaledDamage,
        armorGain: enemy.armorGain,
      );
    }).toList();
  }

  /// Generates an elite encounter for the given depth.
  static List<EliteEnemy> generateEliteEncounter(int depth) {
    return EliteDefinitions.getScaledEliteEncounter(depth: depth);
  }

  /// Generates a boss encounter for the final depth.
  static List<Enemy> generateBossEncounter(int depth) {
    // Generate a tough encounter with boss-level stats
    final baseEnemies = EnemyDefinitions.generateEncounter(
      minEnemies: 1,
      maxEnemies: 2,
      difficultyLevel: 3,
    );

    return baseEnemies.map((enemy) {
      return Enemy(
        id: '${enemy.id}_boss',
        name: '${enemy.name} Guardian',
        element: enemy.element,
        currentHP: (enemy.maxHP * 2.0).round(),
        maxHP: (enemy.maxHP * 2.0).round(),
        attackDamage: enemy.attackDamage + 3,
        armorGain: enemy.armorGain + 5,
      );
    }).toList();
  }

  // ==================== SPELL GENERATION ====================

  /// Generates spell choices for a spell learn node.
  static List<Spell> generateSpellChoices(Mage mage, int depth) {
    // Determine max rarity based on depth
    SpellRarity maxRarity;
    if (depth < 3) {
      maxRarity = SpellRarity.common;
    } else if (depth < 6) {
      maxRarity = SpellRarity.uncommon;
    } else {
      maxRarity = SpellRarity.rare;
    }

    // Get IDs of current loadout to exclude
    final excludeIds = mage.spellLoadout.map((s) => s.id).toList();

    return SpellDefinitions.getRandomSelection(
      count: 3,
      maxRarity: maxRarity,
      excludeIds: excludeIds,
    );
  }

  // ==================== SHOP GENERATION ====================

  /// Generates a shop for the given depth.
  static ShopSystem generateShop(Mage mage, int depth) {
    final knownSpellIds = mage.spellLoadout.map((s) => s.id).toList();

    return ShopSystem.generateShop(depth: depth, knownSpellIds: knownSpellIds);
  }

  // ==================== ENHANCEMENT SHRINE ====================

  /// Gets upgrade cost for a spell.
  static int getUpgradeCost(Spell spell) {
    switch (spell.starLevel) {
      case 1:
        return 50; // ★ → ★★
      case 2:
        return 100; // ★★ → ★★★
      default:
        return 0; // Already max
    }
  }

  /// Gets reroll cost based on depth.
  static int getRerollCost(int depth) {
    return 20 + (depth * 5);
  }

  /// Gets modifier removal cost.
  static int getModifierRemovalCost() {
    return 30;
  }

  /// Gets fragment to crystal conversion rate.
  static int getFragmentToCrystalCost() {
    return 100; // 100 fragments = 1 crystal
  }

  // ==================== REST NODE ====================

  /// Gets the HP restored at a rest node.
  static int getRestHealAmount(Mage mage) {
    // Heal 30% of max HP
    return (mage.maxHP * 0.3).round();
  }

  // ==================== RANDOM EVENTS ====================

  /// Generates a random event. Returns the event type and details.
  static Map<String, dynamic> generateRandomEvent(Mage mage, int depth) {
    final random = Random();
    final eventTypes = ['treasure', 'challenge', 'merchant', 'blessing'];

    final eventType = eventTypes[random.nextInt(eventTypes.length)];

    switch (eventType) {
      case 'treasure':
        final fragments = 20 + random.nextInt(30) + (depth * 5);
        return {
          'type': 'treasure',
          'title': '💎 Treasure Found!',
          'description': 'You discover a hidden cache of spell fragments.',
          'reward': fragments,
          'choices': [
            {
              'key': '1',
              'text': 'Take the treasure (+$fragments fragments)',
              'action': 'take',
            },
          ],
        };

      case 'challenge':
        final hpCost = (mage.maxHP * 0.15).round();
        final fragments = 30 + random.nextInt(20) + (depth * 5);
        return {
          'type': 'challenge',
          'title': '⚔️ Trial of Flames',
          'description': 'A mystical trial offers power at a cost.',
          'choices': [
            {
              'key': '1',
              'text': 'Accept trial (-$hpCost HP, +$fragments fragments)',
              'action': 'accept',
              'hpCost': hpCost,
              'reward': fragments,
            },
            {'key': '2', 'text': 'Decline', 'action': 'decline'},
          ],
        };

      case 'merchant':
        final spellCost = 40;
        return {
          'type': 'merchant',
          'title': '🧙 Wandering Merchant',
          'description': 'A mysterious trader offers their wares.',
          'choices': [
            {
              'key': '1',
              'text': 'Buy a random spell ($spellCost fragments)',
              'action': 'buy_spell',
              'cost': spellCost,
            },
            {'key': '2', 'text': 'Leave', 'action': 'leave'},
          ],
        };

      case 'blessing':
      default:
        final healAmount = (mage.maxHP * 0.2).round();
        return {
          'type': 'blessing',
          'title': '✨ Ancient Blessing',
          'description': 'A shrine emanates healing energy.',
          'choices': [
            {
              'key': '1',
              'text': 'Receive blessing (+$healAmount HP)',
              'action': 'heal',
              'healAmount': healAmount,
            },
          ],
        };
    }
  }

  // ==================== ELITE REWARDS ====================

  /// Generates elite rewards (guaranteed).
  static Map<String, dynamic> generateEliteRewards(int depth) {
    // depth is used for potential future scaling
    final _ = depth;

    // Generate 3 reward options, player chooses 1
    final rewards = <Map<String, dynamic>>[];

    // Option 1: Spell Crystal
    rewards.add({
      'type': 'crystal',
      'name': 'Spell Crystal',
      'icon': '✨',
      'description': 'A rare crystal with immense magical power.',
      'value': 1,
    });

    // Option 2: Rare Spell Offer
    final rareSpells = SpellDefinitions.getRandomSelection(
      count: 1,
      maxRarity: SpellRarity.rare,
    );
    if (rareSpells.isNotEmpty) {
      final spell = rareSpells.first;
      rewards.add({
        'type': 'spell',
        'name': spell.displayName,
        'icon': spell.elementIcon,
        'description': 'Learn this powerful spell.',
        'spell': spell,
      });
    } else {
      rewards.add({
        'type': 'fragments',
        'name': 'Fragment Hoard',
        'icon': '💎',
        'description': 'A large pile of spell fragments.',
        'value': 75,
      });
    }

    // Option 3: Free spell upgrade
    rewards.add({
      'type': 'upgrade',
      'name': 'Free Upgrade',
      'icon': '⭐',
      'description': 'Upgrade one of your spells for free.',
      'value': 1,
    });

    return {'rewards': rewards, 'description': 'Choose your reward:'};
  }

  // ==================== COMBAT REWARDS ====================

  /// Calculates combat rewards.
  static Map<String, int> calculateCombatReward({
    required int depth,
    required int enemiesDefeated,
    bool isElite = false,
  }) {
    return {
      'fragments': DifficultyScaler.calculateFragmentReward(
        depth: depth,
        enemiesDefeated: enemiesDefeated,
        isElite: isElite,
      ),
      'experience': DifficultyScaler.calculateExpReward(
        depth: depth,
        enemiesDefeated: enemiesDefeated,
        isElite: isElite,
      ),
    };
  }

  /// Checks if a spell crystal drop should occur (small chance after depth 4).
  static bool shouldDropSpellCrystal(int depth) {
    if (depth < 4) return false;

    final random = Random();
    final chance = 0.05 + ((depth - 4) * 0.02); // 5% base + 2% per depth
    return random.nextDouble() < chance;
  }

  /// Checks if a spell learning opportunity occurs.
  static bool shouldOfferSpellLearn(int depth) {
    final random = Random();
    final chance = 0.15 + (depth * 0.02); // 15% base + 2% per depth
    return random.nextDouble() < chance;
  }
}
