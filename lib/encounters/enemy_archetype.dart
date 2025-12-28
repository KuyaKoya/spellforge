import '../domain/enemy.dart';
import '../domain/element.dart';
import '../core/seeded_random.dart';

/// Enemy archetype that defines behavior patterns.
enum EnemyArchetype {
  /// Aggressive - focuses on attack
  aggressive,

  /// Defensive - alternates between attack and defend
  defensive,

  /// Debuffer - uses debuffs frequently
  debuffer,

  /// Balanced - even distribution of actions
  balanced,

  /// Berserker - all-out attack, never defends
  berserker,

  /// Tank - heavy defense, slow attacks
  tank;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}

/// Intent probability table for an archetype.
class IntentProbabilities {
  final double attack;
  final double defend;
  final double debuff;

  const IntentProbabilities({
    required this.attack,
    required this.defend,
    required this.debuff,
  });

  /// Gets the intent based on a random roll.
  EnemyIntent getIntent(SeededRandom random) {
    final roll = random.nextDouble();
    if (roll < attack) return EnemyIntent.attack;
    if (roll < attack + defend) return EnemyIntent.defend;
    return EnemyIntent.debuff;
  }

  /// Gets probabilities for an archetype.
  static IntentProbabilities forArchetype(EnemyArchetype archetype) {
    switch (archetype) {
      case EnemyArchetype.aggressive:
        return const IntentProbabilities(attack: 0.7, defend: 0.2, debuff: 0.1);
      case EnemyArchetype.defensive:
        return const IntentProbabilities(
          attack: 0.4,
          defend: 0.45,
          debuff: 0.15,
        );
      case EnemyArchetype.debuffer:
        return const IntentProbabilities(
          attack: 0.35,
          defend: 0.25,
          debuff: 0.4,
        );
      case EnemyArchetype.balanced:
        return const IntentProbabilities(attack: 0.5, defend: 0.3, debuff: 0.2);
      case EnemyArchetype.berserker:
        return const IntentProbabilities(
          attack: 0.95,
          defend: 0.0,
          debuff: 0.05,
        );
      case EnemyArchetype.tank:
        return const IntentProbabilities(attack: 0.3, defend: 0.6, debuff: 0.1);
    }
  }
}

/// Information about enemy weaknesses.
class WeaknessPattern {
  /// Element the enemy is weak to.
  final Element? weakElement;

  /// Element the enemy is resistant to.
  final Element? resistElement;

  /// Status effects the enemy is vulnerable to.
  final List<String> vulnerableEffects;

  const WeaknessPattern({
    this.weakElement,
    this.resistElement,
    this.vulnerableEffects = const [],
  });

  /// Gets the standard weakness pattern for an element.
  static WeaknessPattern forElement(Element element) {
    return WeaknessPattern(
      weakElement: element.weakAgainst,
      resistElement: element.strongAgainst,
    );
  }
}

/// Synergy rules between enemy archetypes.
class ArchetypeSynergy {
  /// Archetypes that work well together.
  static const Map<EnemyArchetype, List<EnemyArchetype>> synergies = {
    EnemyArchetype.aggressive: [EnemyArchetype.debuffer, EnemyArchetype.tank],
    EnemyArchetype.defensive: [
      EnemyArchetype.debuffer,
      EnemyArchetype.berserker,
    ],
    EnemyArchetype.debuffer: [
      EnemyArchetype.aggressive,
      EnemyArchetype.berserker,
    ],
    EnemyArchetype.balanced: [
      EnemyArchetype.aggressive,
      EnemyArchetype.defensive,
    ],
    EnemyArchetype.berserker: [EnemyArchetype.defensive, EnemyArchetype.tank],
    EnemyArchetype.tank: [EnemyArchetype.aggressive, EnemyArchetype.debuffer],
  };

  /// Gets synergy score for a group of archetypes (0.0 to 1.0).
  static double calculateSynergyScore(List<EnemyArchetype> archetypes) {
    if (archetypes.length <= 1) return 0.0;

    int synergyCount = 0;
    int possibleSynergies = 0;

    for (int i = 0; i < archetypes.length; i++) {
      for (int j = i + 1; j < archetypes.length; j++) {
        possibleSynergies++;
        final synergiesForI = synergies[archetypes[i]] ?? [];
        if (synergiesForI.contains(archetypes[j])) {
          synergyCount++;
        }
      }
    }

    return possibleSynergies > 0 ? synergyCount / possibleSynergies : 0.0;
  }
}

/// Resolves enemy intents based on archetypes and game state.
class EnemyIntentResolver {
  /// Gets the next intent for an enemy based on archetype.
  static EnemyIntent resolveIntent({
    required Enemy enemy,
    required EnemyArchetype archetype,
    required SeededRandom random,
    EnemyIntent? previousIntent,
  }) {
    final probs = IntentProbabilities.forArchetype(archetype);
    var intent = probs.getIntent(random);

    // Avoid same intent three times in a row (for balance)
    // This is still deterministic because it uses the seeded random
    if (previousIntent != null && intent == previousIntent) {
      // Roll again with adjusted weights
      intent = probs.getIntent(random);
    }

    return intent;
  }

  /// Generates an archetype for an enemy based on element and depth.
  static EnemyArchetype generateArchetype({
    required Element element,
    required int depth,
    required SeededRandom random,
  }) {
    // Element-based tendencies
    final elementTendencies = <EnemyArchetype, double>{
      EnemyArchetype.aggressive: 0.2,
      EnemyArchetype.defensive: 0.2,
      EnemyArchetype.debuffer: 0.2,
      EnemyArchetype.balanced: 0.2,
      EnemyArchetype.berserker: 0.1,
      EnemyArchetype.tank: 0.1,
    };

    // Adjust based on element
    switch (element) {
      case Element.fire:
        elementTendencies[EnemyArchetype.aggressive] = 0.35;
        elementTendencies[EnemyArchetype.berserker] = 0.2;
        break;
      case Element.water:
        elementTendencies[EnemyArchetype.debuffer] = 0.35;
        elementTendencies[EnemyArchetype.balanced] = 0.25;
        break;
      case Element.earth:
        elementTendencies[EnemyArchetype.defensive] = 0.35;
        elementTendencies[EnemyArchetype.tank] = 0.25;
        break;
      case Element.air:
        elementTendencies[EnemyArchetype.aggressive] = 0.3;
        elementTendencies[EnemyArchetype.balanced] = 0.3;
        break;
    }

    // Depth adjustments - later depths have more extreme archetypes
    if (depth >= 7) {
      elementTendencies[EnemyArchetype.berserker] =
          (elementTendencies[EnemyArchetype.berserker] ?? 0) + 0.1;
      elementTendencies[EnemyArchetype.tank] =
          (elementTendencies[EnemyArchetype.tank] ?? 0) + 0.1;
    }

    return random.nextWeighted(elementTendencies);
  }

  /// Selects enemy archetypes for a group with optional synergy bias.
  static List<EnemyArchetype> selectGroupArchetypes({
    required List<Enemy> enemies,
    required int depth,
    required SeededRandom random,
    double synergyBias = 0.5,
  }) {
    if (enemies.isEmpty) return [];

    final archetypes = <EnemyArchetype>[];

    // Generate first archetype
    archetypes.add(
      generateArchetype(
        element: enemies.first.element,
        depth: depth,
        random: random,
      ),
    );

    // Generate remaining archetypes with synergy consideration
    for (int i = 1; i < enemies.length; i++) {
      final baseArchetype = generateArchetype(
        element: enemies[i].element,
        depth: depth,
        random: random,
      );

      // Check if we should bias toward synergy
      if (random.nextDouble() < synergyBias) {
        // Try to find a synergistic archetype
        final existingSynergies = archetypes
            .expand((a) => ArchetypeSynergy.synergies[a] ?? <EnemyArchetype>[])
            .toSet();

        if (existingSynergies.contains(baseArchetype)) {
          archetypes.add(baseArchetype);
        } else if (existingSynergies.isNotEmpty) {
          // Pick a synergistic one
          archetypes.add(random.nextElement(existingSynergies.toList()));
        } else {
          archetypes.add(baseArchetype);
        }
      } else {
        archetypes.add(baseArchetype);
      }
    }

    return archetypes;
  }
}
