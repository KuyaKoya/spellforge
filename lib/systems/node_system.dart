import 'dart:math';
import '../data/enemy_definitions.dart';
import '../data/spell_definitions.dart';
import '../domain/mage.dart';
import '../domain/spell.dart';

/// Types of nodes in the game.
enum NodeType {
  combat,
  spellLearn,
  enhancementShrine,
  rest,
  randomEvent,
  bossCombat;

  String get displayName {
    switch (this) {
      case NodeType.combat:
        return 'Combat';
      case NodeType.spellLearn:
        return 'Spell Shrine';
      case NodeType.enhancementShrine:
        return 'Enhancement Shrine';
      case NodeType.rest:
        return 'Rest Site';
      case NodeType.randomEvent:
        return 'Random Event';
      case NodeType.bossCombat:
        return 'Boss Battle';
    }
  }

  String get description {
    switch (this) {
      case NodeType.combat:
        return 'Battle against elemental creatures.';
      case NodeType.spellLearn:
        return 'Learn a new spell from the arcane pool.';
      case NodeType.enhancementShrine:
        return 'Upgrade one of your spells.';
      case NodeType.rest:
        return 'Rest and recover HP.';
      case NodeType.randomEvent:
        return 'Something unexpected awaits...';
      case NodeType.bossCombat:
        return 'Face the elemental guardian!';
    }
  }

  String get icon {
    switch (this) {
      case NodeType.combat:
        return '⚔️';
      case NodeType.spellLearn:
        return '📖';
      case NodeType.enhancementShrine:
        return '⭐';
      case NodeType.rest:
        return '🛏️';
      case NodeType.randomEvent:
        return '❓';
      case NodeType.bossCombat:
        return '👹';
    }
  }
}

/// Represents a single node in the run.
class GameNode {
  final int index;
  final NodeType type;
  bool isCompleted;

  GameNode({required this.index, required this.type, this.isCompleted = false});

  String get displayText =>
      '${type.icon} Node ${index + 1}: ${type.displayName}';
}

/// Manages node sequencing and progression.
class NodeSystem {
  final List<GameNode> _nodes;
  int _currentNodeIndex;

  NodeSystem() : _nodes = [], _currentNodeIndex = 0;

  /// Current node.
  GameNode? get currentNode =>
      _currentNodeIndex < _nodes.length ? _nodes[_currentNodeIndex] : null;

  /// Current node index.
  int get currentNodeIndex => _currentNodeIndex;

  /// Total nodes in the run.
  int get totalNodes => _nodes.length;

  /// Whether the run is complete.
  bool get isRunComplete => _currentNodeIndex >= _nodes.length;

  /// All nodes.
  List<GameNode> get nodes => List.unmodifiable(_nodes);

  /// Generates a new run with the fixed progression pattern.
  /// Pattern: Combat -> Spell -> Combat -> Combat -> Random -> Combat -> Combat -> Rest+Enhance -> Boss
  void generateRun({int nodeCount = 10}) {
    _nodes.clear();
    _currentNodeIndex = 0;

    // Fixed progression pattern:
    // 0: Combat (intro battle)
    // 1: Spell Learn (first spell reward)
    // 2: Combat
    // 3: Combat
    // 4: Random Event
    // 5: Combat
    // 6: Combat (extra battle)
    // 7: Rest (prepare for boss)
    // 8: Enhancement Shrine (final upgrade)
    // 9: Boss Combat

    final pattern = <NodeType>[
      NodeType.combat, // 0: Intro battle
      NodeType.spellLearn, // 1: First spell reward
      NodeType.combat, // 2: Second battle
      NodeType.combat, // 3: Third battle
      NodeType.randomEvent, // 4: Random event
      NodeType.combat, // 5: Fourth battle
      NodeType.combat, // 6: Fifth battle
      NodeType.rest, // 7: Rest before boss
      NodeType.enhancementShrine, // 8: Final upgrade
      NodeType.bossCombat, // 9: Boss battle
    ];

    for (int i = 0; i < pattern.length; i++) {
      _nodes.add(GameNode(index: i, type: pattern[i]));
    }
  }

  /// Advances to the next node.
  void completeCurrentNode() {
    if (_currentNodeIndex < _nodes.length) {
      _nodes[_currentNodeIndex].isCompleted = true;
      _currentNodeIndex++;
    }
  }

  /// Gets a preview of upcoming nodes.
  List<GameNode> getUpcomingNodes({int count = 3}) {
    final start = _currentNodeIndex;
    final end = (start + count).clamp(0, _nodes.length);
    return _nodes.sublist(start, end);
  }

  /// Resets the node system for a new run.
  void reset() {
    _nodes.clear();
    _currentNodeIndex = 0;
  }
}

/// Handles node-specific encounters and rewards.
class NodeResolver {
  NodeResolver._();

  /// Generates a combat encounter for the given node index.
  static List<dynamic> generateCombatEncounter(int nodeIndex) {
    final difficulty = 1 + (nodeIndex ~/ 3);
    final maxEnemies = (nodeIndex < 3) ? 2 : 3;

    return EnemyDefinitions.generateEncounter(
      minEnemies: 1,
      maxEnemies: maxEnemies,
      difficultyLevel: difficulty,
    );
  }

  /// Generates a boss encounter.
  static List<dynamic> generateBossEncounter(int nodeIndex) {
    // For now, generate a tougher encounter as "boss"
    // TODO: Add actual boss enemies
    return EnemyDefinitions.generateEncounter(
      minEnemies: 1,
      maxEnemies: 2,
      difficultyLevel: 3,
    );
  }

  /// Generates spell choices for a spell learn node.
  static List<Spell> generateSpellChoices(Mage mage, int nodeIndex) {
    // Determine max rarity based on progress
    SpellRarity maxRarity;
    if (nodeIndex < 3) {
      maxRarity = SpellRarity.common;
    } else if (nodeIndex < 6) {
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

  /// Generates a random event. Returns the event type and details.
  static Map<String, dynamic> generateRandomEvent(Mage mage, int nodeIndex) {
    final random = Random();
    final eventTypes = ['treasure', 'challenge', 'merchant', 'blessing'];

    final eventType = eventTypes[random.nextInt(eventTypes.length)];

    switch (eventType) {
      case 'treasure':
        final fragments = 20 + random.nextInt(30);
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
        final fragments = 30 + random.nextInt(20);
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

  /// Gets upgrade cost for a spell.
  static int getUpgradeCost(Spell spell) {
    // Cost based on current star level
    switch (spell.starLevel) {
      case 1:
        return 50; // ★ → ★★
      case 2:
        return 100; // ★★ → ★★★
      default:
        return 0; // Already max
    }
  }

  /// Gets the HP restored at a rest node.
  static int getRestHealAmount(Mage mage) {
    // Heal 30% of max HP
    return (mage.maxHP * 0.3).round();
  }
}
