import 'dart:math';
import '../data/enemy_definitions.dart';
import '../data/elite_definitions.dart';
import '../data/spell_definitions.dart';
import '../domain/element.dart';
import '../domain/enemy.dart';
import '../domain/elite_enemy.dart';
import '../domain/mage.dart';
import '../domain/spell.dart';
import '../nodes/spell_tier_scaling.dart';
import 'difficulty_scaler.dart';
import 'meta_difficulty.dart';
import 'shop_system.dart';
import '../data/passive_definitions.dart';
import '../domain/boss_enemy.dart';

/// Handles resolving node encounters, generating content, and rewards.
class NodeResolver {
  NodeResolver._();

  // ==================== COMBAT GENERATION ====================

  /// Generates a standard combat encounter for the given depth.
  /// Phase 7.6.3: Accepts [startingElement] for biased generation.
  /// Phase 7.9: Accepts [metaMods] for anti-snowball difficulty scaling.
  /// Phase 7.10: Now scales all stats (HP, damage, attack, defense, speed).
  static List<Enemy> generateCombatEncounter(
    int depth, {
    Element? startingElement,
    MetaDifficultyModifiers? metaMods,
  }) {
    final minEnemies = DifficultyScaler.getMinEnemies(depth);
    final maxEnemies = DifficultyScaler.getMaxEnemies(depth);

    final enemies = EnemyDefinitions.generateEncounter(
      minEnemies: minEnemies,
      maxEnemies: maxEnemies,
      difficultyLevel: 1,
      biasElement: startingElement,
    );

    // Get meta difficulty modifiers (use tier 0 if not provided)
    final mods = metaMods ?? MetaDifficultySystem.getModifiers(0);

    // Phase 7.10: Apply depth + meta scaling to ALL stats
    return enemies.map((enemy) {
      final scaledHP = DifficultyScaler.calculateFinalHP(
        baseHP: enemy.maxHP,
        depth: depth,
        metaMods: mods,
      );
      final scaledDamage = DifficultyScaler.calculateFinalAttack(
        baseAttack: enemy.attackDamage,
        depth: depth,
        metaMods: mods,
      );
      final scaledDefense = DifficultyScaler.calculateFinalDefense(
        baseDefense: enemy.defense,
        depth: depth,
        metaMods: mods,
      );
      final scaledAttack = DifficultyScaler.calculateFinalAttack(
        baseAttack: enemy.attack,
        depth: depth,
        metaMods: mods,
      );
      final scaledSpeed = DifficultyScaler.calculateFinalSpeed(
        baseSpeed: enemy.speed,
        metaMods: mods,
      );

      // Scale armor gain with depth for more defensive enemies
      final scaledArmorGain = enemy.armorGain + (depth ~/ 2);

      return Enemy(
        id: enemy.id,
        name: enemy.name,
        element: enemy.element,
        currentHP: scaledHP,
        maxHP: scaledHP,
        attackDamage: scaledDamage,
        attack: scaledAttack,
        defense: scaledDefense,
        speed: scaledSpeed,
        armorGain: scaledArmorGain,
        spellLoadout: enemy.spellLoadout,
        maxMana: enemy.maxMana,
      );
    }).toList();
  }

  /// Generates an elite encounter for the given depth.
  /// Phase 7.6.3: Accepts [startingElement] for filtered generation.
  /// Phase 7.9: Accepts [metaMods] for anti-snowball difficulty scaling.
  static List<EliteEnemy> generateEliteEncounter(
    int depth, {
    Element? startingElement,
    MetaDifficultyModifiers? metaMods,
  }) {
    return EliteDefinitions.getScaledEliteEncounter(
      depth: depth,
      biasElement: startingElement,
      metaMods: metaMods,
    );
  }

  /// Generates a boss encounter for the final depth.
  /// For Act 1, this is the Twin Gatekeepers.
  /// Phase 7.9: Accepts [metaMods] for anti-snowball difficulty scaling.
  /// Phase 7.10: Moderately increased boss stats for better challenge.
  static List<Enemy> generateBossEncounter(
    int depth, {
    MetaDifficultyModifiers? metaMods,
  }) {
    // Twin Gatekeepers: Fire+Earth and Water+Air
    // They are silent, mechanistic, a barrier not a villain.

    final difficultyLevel = (depth / 3).ceil().clamp(1, 3);
    final mods = metaMods ?? MetaDifficultySystem.getModifiers(0);

    // Phase 7.10: Balanced boss stats - challenging but fair
    // Gatekeeper of Pyre (Fire + Earth aspects) - TANKY BRUISER
    final basePyreHp = 80 + (difficultyLevel * 12);
    final basePyreDamage = 10 + difficultyLevel;
    final pyreHp = DifficultyScaler.calculateFinalHP(
      baseHP: basePyreHp,
      depth: depth,
      metaMods: mods,
    );
    final pyreDamage = DifficultyScaler.calculateFinalAttack(
      baseAttack: basePyreDamage,
      depth: depth,
      metaMods: mods,
    );

    // Gatekeeper of Tide (Water + Air aspects) - FAST CONTROLLER
    final baseTideHp = 70 + (difficultyLevel * 10);
    final baseTideDamage = 8 + difficultyLevel;
    final tideHp = DifficultyScaler.calculateFinalHP(
      baseHP: baseTideHp,
      depth: depth,
      metaMods: mods,
    );
    final tideDamage = DifficultyScaler.calculateFinalAttack(
      baseAttack: baseTideDamage,
      depth: depth,
      metaMods: mods,
    );

    final pyreBoss = BossEnemy(
      id: 'gatekeeper_pyre',
      name: 'Gatekeeper of Pyre',
      title: 'The Eternal Flame',
      element: Element.fire,
      currentHP: pyreHp,
      maxHP: pyreHp,
      attackDamage: pyreDamage,
      armorGain: 12,
      modifiers: [EliteModifier.resistant], // Removed empowered
      resistantElement: Element.fire, // Fire+Earth -> Fire resistant
      passives: PassiveDefinitions.gatekeeperPyrePassives(),
      maxMana: 22,
      spellLoadout: [SpellDefinitions.blazeStrike, SpellDefinitions.inferno],
    );

    final tideBoss = BossEnemy(
      id: 'gatekeeper_tide',
      name: 'Gatekeeper of Tide',
      title: 'The Unyielding Wave',
      element: Element.water,
      currentHP: tideHp,
      maxHP: tideHp,
      attackDamage: tideDamage,
      armorGain: 8,
      modifiers: [EliteModifier.resistant], // Removed empowered
      resistantElement: Element.water, // Water+Air -> Water resistant
      passives: PassiveDefinitions.gatekeeperTidePassives(),
      maxMana: 22,
      spellLoadout: [SpellDefinitions.tidalWave, SpellDefinitions.frostArmor],
    );

    // Phase 7.9: Boss Phase Skip (Tier 4+)
    if (mods.bossExtraPhases > 0) {
      // Start 3 turns in (assuming patterns cycle or start simple)
      pyreBoss.patternTurn = 3;
      tideBoss.patternTurn = 3;
    }

    return [pyreBoss, tideBoss];
  }

  // ==================== SPELL GENERATION ====================

  /// Generates spell choices for a spell learn node.
  /// Phase 7.6: Uses depth-based tier scaling, star upgrade injection,
  /// and starting element bias.
  static List<Spell> generateSpellChoices(Mage mage, int depth, {int? seed}) {
    // Get IDs of current loadout to exclude
    final excludeIds = mage.spellLoadout.map((s) => s.id).toSet();

    // Get all available spells (base pool)
    final allSpells = SpellDefinitions.allSpells
        .where((s) => !excludeIds.contains(s.id))
        .toList();

    if (allSpells.isEmpty) {
      return [];
    }

    // Use the Phase 7.6 SpellLearnSelector for weighted selection
    final selector = SpellLearnSelector(seed: seed);

    // Determine weakness element (opposite of primary)
    // Fire <-> Water, Earth <-> Air
    Element? weaknessElement;
    switch (mage.primaryElement) {
      case Element.fire:
        weaknessElement = Element.water;
        break;
      case Element.water:
        weaknessElement = Element.fire;
        break;
      case Element.earth:
        weaknessElement = Element.air;
        break;
      case Element.air:
        weaknessElement = Element.earth;
        break;
    }

    return selector.selectSpellChoices(
      depth: depth,
      availableSpells: allSpells,
      startingElement: mage.primaryElement,
      weaknessElement: weaknessElement,
      count: 3,
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
  /// Phase 7.6.5: Guarantees a higher-tier spell of the player's starting type.
  ///
  /// [depth] - Current run depth for scaling
  /// [startingElement] - Player's chosen starting element (Phase 7.6.1)
  static Map<String, dynamic> generateEliteRewards(
    int depth, {
    Element? startingElement,
    Element? eliteElement,
  }) {
    // Generate 3 reward options, player chooses 1
    final rewards = <Map<String, dynamic>>[];

    // Option 1: Guaranteed higher-tier spell of elite's element (or starting element)
    Spell? guaranteedSpell;
    final targetElement = eliteElement ?? startingElement;

    if (targetElement != null) {
      // Get uncommon or rare spells of the target element
      final elementSpells = SpellDefinitions.getByElement(targetElement)
          .where(
            (s) =>
                s.rarity == SpellRarity.uncommon ||
                s.rarity == SpellRarity.rare,
          )
          .toList();

      if (elementSpells.isNotEmpty) {
        // Prefer rare spells at higher depths
        final rareSpells = elementSpells
            .where((s) => s.rarity == SpellRarity.rare)
            .toList();
        if (depth >= 5 && rareSpells.isNotEmpty) {
          rareSpells.shuffle();
          guaranteedSpell = rareSpells.first;
        } else {
          elementSpells.shuffle();
          guaranteedSpell = elementSpells.first;
        }
      }
    }

    if (guaranteedSpell != null) {
      rewards.add({
        'type': 'spell',
        'name':
            '${guaranteedSpell.displayName} (${targetElement!.displayName})',
        'icon': guaranteedSpell.elementIcon,
        'description':
            'A powerful ${targetElement.displayName} spell awaits you.',
        'spell': guaranteedSpell,
        'isGuaranteed': true, // Mark as the guaranteed element reward
      });
    } else {
      // Fallback: random rare spell if no element match found
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
    }

    // Option 2: Spell Crystal
    rewards.add({
      'type': 'crystal',
      'name': 'Spell Crystal',
      'icon': '✨',
      'description': 'A rare crystal with immense magical power.',
      'value': 1,
    });

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
  /// Phase 7.9: Uses new EXP system with enemy-type-based values.
  static Map<String, int> calculateCombatReward({
    required int depth,
    required int enemiesDefeated,
    bool isElite = false,
    bool isBoss = false,
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
        isBoss: isBoss,
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
