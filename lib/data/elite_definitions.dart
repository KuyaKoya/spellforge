import 'dart:math';
import '../domain/element.dart';
import '../domain/elite_enemy.dart';
import '../domain/enemy_passive.dart';
import '../systems/meta_difficulty.dart';
import '../systems/difficulty_scaler.dart';
import 'passive_definitions.dart';

/// Pre-defined elite encounter templates for the game.
class EliteDefinitions {
  EliteDefinitions._();

  // ==================== ELITE ENEMIES ====================

  /// Burnward Colossus - Earth elite, resistant to Fire.
  /// Strategy: Use Air or Water control builds
  static EliteEnemy burnwardColossus() => EliteEnemy(
    id: 'burnwardColossus',
    name: 'Burnward Colossus',
    element: Element.earth,
    currentHP: 60,
    maxHP: 60,
    attackDamage: 8,
    armorGain: 12,
    modifiers: [EliteModifier.resistant, EliteModifier.empowered],
    resistantElement: Element.fire,
  );

  /// Tempest Twins - Air elite pair with bonus actions.
  /// Strategy: Earth defenses or Freeze
  static EliteEnemy tempestTwinA() => EliteEnemy(
    id: 'tempestTwinA',
    name: 'Tempest Twin (Storm)',
    element: Element.air,
    currentHP: 35,
    maxHP: 35,
    attackDamage: 5,
    armorGain: 4,
    modifiers: [EliteModifier.relentless],
  );

  static EliteEnemy tempestTwinB() => EliteEnemy(
    id: 'tempestTwinB',
    name: 'Tempest Twin (Gale)',
    element: Element.air,
    currentHP: 35,
    maxHP: 35,
    attackDamage: 5,
    armorGain: 4,
    modifiers: [EliteModifier.relentless],
  );

  /// Glacial Executioner - Water elite that freezes slowed targets.
  /// Strategy: Burst damage or cleanse
  static EliteEnemy glacialExecutioner() => EliteEnemy(
    id: 'glacialExecutioner',
    name: 'Glacial Executioner',
    element: Element.water,
    currentHP: 55,
    maxHP: 55,
    attackDamage: 12,
    armorGain: 6,
    modifiers: [EliteModifier.empowered],
  );

  /// Infernal Warlord - Fire elite with adaptive resistance.
  /// Strategy: Varied elemental attacks
  static EliteEnemy infernalWarlord() => EliteEnemy(
    id: 'infernalWarlord',
    name: 'Infernal Warlord',
    element: Element.fire,
    currentHP: 50,
    maxHP: 50,
    attackDamage: 10,
    armorGain: 5,
    modifiers: [EliteModifier.adaptive],
  );

  /// Stone Sentinel - Earth elite with high armor.
  /// Strategy: Status effects and sustained damage
  static EliteEnemy stoneSentinel() => EliteEnemy(
    id: 'stoneSentinel',
    name: 'Stone Sentinel',
    element: Element.earth,
    currentHP: 70,
    maxHP: 70,
    attackDamage: 7,
    armorGain: 15,
    modifiers: [EliteModifier.resistant],
    resistantElement: Element.air,
  );

  /// Typhoon Herald - Air elite with relentless attacks.
  /// Strategy: High burst to end fight quickly
  static EliteEnemy typhoonHerald() => EliteEnemy(
    id: 'typhoonHerald',
    name: 'Typhoon Herald',
    element: Element.air,
    currentHP: 40,
    maxHP: 40,
    attackDamage: 9,
    armorGain: 3,
    modifiers: [EliteModifier.relentless, EliteModifier.adaptive],
  );

  /// All elite encounter generators.
  static List<List<EliteEnemy> Function()> get allEliteEncounters => [
    () => [burnwardColossus()],
    () => [tempestTwinA(), tempestTwinB()],
    () => [glacialExecutioner()],
    () => [infernalWarlord()],
    () => [stoneSentinel()],
    () => [typhoonHerald()],
  ];

  /// Generates a random elite encounter scaled by depth.
  /// Phase 7.6.3: [biasElement] can be used to prevent unfair matchups at low depths.
  static List<EliteEnemy> generateEliteEncounter({
    required int depth,
    int? seed,
    Element? biasElement,
  }) {
    final random = seed != null ? Random(seed) : Random();

    // Choose an encounter
    var generators = List.from(allEliteEncounters);

    // Filter unfair matchups at lower depths
    if (biasElement != null && depth < 6) {
      generators = generators.where((gen) {
        final dummyList = gen();
        final dummy = dummyList.first;
        // Avoid Resistant to player's element
        if (dummy.hasModifier(EliteModifier.resistant) &&
            dummy.resistantElement == biasElement) {
          return false;
        }
        // Avoid Adaptive at low levels (hard counter to mono-element)
        if (dummy.hasModifier(EliteModifier.adaptive)) {
          return false;
        }
        return true;
      }).toList();

      // Fallback if we filtered everything out (unlikely but safe)
      if (generators.isEmpty) {
        generators = List.from(allEliteEncounters);
      }
    }

    final encounter = generators[random.nextInt(generators.length)]();

    // Scale by depth (depths 4+)
    final depthBonus = (depth - 4).clamp(0, 6);

    for (final elite in encounter) {
      // HP scaling: +10% per depth after 4
      final hpBonus = (elite.maxHP * 0.1 * depthBonus).round();
      elite.currentHP = elite.maxHP + hpBonus;

      // Attack scaling: +1 per 2 depths
      // (readonly fields, so we create scaled versions in factory)
    }

    return encounter;
  }

  /// Gets an elite encounter with proper scaling.
  /// Phase 7.6.3: Supports [biasElement].
  /// Phase 7.9: Supports [metaMods] for anti-snowball difficulty scaling.
  static List<EliteEnemy> getScaledEliteEncounter({
    required int depth,
    int? encounterIndex,
    Element? biasElement,
    MetaDifficultyModifiers? metaMods,
  }) {
    final random = Random();

    // Get meta difficulty modifiers (use tier 0 if not provided)
    final mods = metaMods ?? MetaDifficultySystem.getModifiers(0);

    List<List<EliteEnemy> Function()> generators;
    if (encounterIndex != null) {
      generators = [allEliteEncounters[encounterIndex]];
    } else {
      generators = List.from(allEliteEncounters);

      // Phase 7.6.3: Filter unfair matchups at lower depths
      if (biasElement != null && depth < 6) {
        generators = generators.where((gen) {
          final dummyList = gen();
          final dummy = dummyList.first;
          // Avoid Resistant to player's element
          if (dummy.hasModifier(EliteModifier.resistant) &&
              dummy.resistantElement == biasElement) {
            return false;
          }
          // Avoid Adaptive at low levels
          if (dummy.hasModifier(EliteModifier.adaptive)) {
            return false;
          }
          return true;
        }).toList();

        if (generators.isEmpty) {
          generators = List.from(allEliteEncounters);
        }
      }
    }

    final index = random.nextInt(generators.length);
    final baseEncounter = generators[index]();

    // Phase 7.9: Calculate passive count (may add extra from meta tier)
    final passiveCount = DifficultyScaler.getElitePassiveCount(depth, mods);

    return baseEncounter.map((elite) {
      // Phase 7.9: Apply depth + meta scaling
      final scaledHP = DifficultyScaler.calculateFinalHP(
        baseHP: elite.maxHP,
        depth: depth,
        metaMods: mods,
      );
      final scaledDamage = DifficultyScaler.calculateFinalAttack(
        baseAttack: elite.attackDamage,
        depth: depth,
        metaMods: mods,
      );

      // Phase 7.9: Handle extra passives
      var passives = PassiveDefinitions.getPassivesForEnemy(elite.id);
      if (passives.length < passiveCount) {
        // Need to add extra passives
        final extraNeeded = passiveCount - passives.length;
        final genericPool = List<EnemyPassive>.from(
          PassiveDefinitions.getGenericPassives(),
        );
        genericPool.shuffle(random);

        // Add unique generic passives
        for (var i = 0; i < extraNeeded && i < genericPool.length; i++) {
          final passive = genericPool[i];
          // Ensure we don't duplicate logic
          if (!passives.any((p) => p.id == passive.id)) {
            passives = [...passives, passive]; // Create new list
          }
        }
      }

      return EliteEnemy(
        id: elite.id,
        name: elite.name,
        element: elite.element,
        currentHP: scaledHP,
        maxHP: scaledHP,
        attackDamage: scaledDamage,
        armorGain: elite.armorGain,
        modifiers: elite.modifiers,
        resistantElement: elite.resistantElement,
        passives: passives, // Phase 7.9: Explicit passives with extras
      );
    }).toList();
  }

  /// Gets the encounter info for display.
  static Map<String, dynamic> getEliteEncounterInfo(List<EliteEnemy> enemies) {
    return {
      'enemies': enemies
          .map(
            (e) => {
              'name': e.name,
              'element': e.element.displayName,
              'hp': e.maxHP,
              'modifiers': e.modifierDescriptions,
            },
          )
          .toList(),
      'warningText': _getWarningText(enemies),
    };
  }

  /// Generates warning text for elite encounters.
  static String _getWarningText(List<EliteEnemy> enemies) {
    final warnings = <String>[];

    for (final enemy in enemies) {
      if (enemy.hasModifier(EliteModifier.resistant) &&
          enemy.resistantElement != null) {
        warnings.add(
          '⚠️ ${enemy.name}: ${enemy.resistantElement!.displayName} damage reduced',
        );
      }
      if (enemy.hasModifier(EliteModifier.empowered)) {
        warnings.add('⚠️ ${enemy.name}: Increased damage output');
      }
      if (enemy.hasModifier(EliteModifier.relentless)) {
        warnings.add('⚠️ ${enemy.name}: Acts twice every 3 turns');
      }
      if (enemy.hasModifier(EliteModifier.adaptive)) {
        warnings.add('⚠️ ${enemy.name}: Adapts to repeated elements');
      }
    }

    return warnings.join('\n');
  }
}
