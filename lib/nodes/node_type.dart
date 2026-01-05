/// Types of nodes in the game.
enum NodeType {
  combat,
  spellLearn,
  enhancementShrine,
  shop,
  rest,
  elite,
  randomEvent,
  bossCombat;

  /// Display name for the node type.
  String get displayName {
    switch (this) {
      case NodeType.combat:
        return 'Combat';
      case NodeType.spellLearn:
        return 'Spell Shrine';
      case NodeType.enhancementShrine:
        return 'Enhancement Shrine';
      case NodeType.shop:
        return 'Shop';
      case NodeType.rest:
        return 'Rest Site';
      case NodeType.elite:
        return 'Elite Combat';
      case NodeType.randomEvent:
        return 'Random Event';
      case NodeType.bossCombat:
        return 'Boss Battle';
    }
  }

  /// Description of what happens at this node type.
  String get description {
    switch (this) {
      case NodeType.combat:
        return 'Battle against elemental creatures.';
      case NodeType.spellLearn:
        return 'Learn a new spell from the arcane pool.';
      case NodeType.enhancementShrine:
        return 'Upgrade one of your spells.';
      case NodeType.shop:
        return 'Trade resources for powerful items.';
      case NodeType.rest:
        return 'Rest and recover HP.';
      case NodeType.elite:
        return 'Face a powerful foe for great rewards.';
      case NodeType.randomEvent:
        return 'Something unexpected awaits...';
      case NodeType.bossCombat:
        return 'Face the elemental guardian!';
    }
  }

  /// Icon representing this node type.
  String get icon {
    switch (this) {
      case NodeType.combat:
        return '⚔️';
      case NodeType.spellLearn:
        return '📖';
      case NodeType.enhancementShrine:
        return '⭐';
      case NodeType.shop:
        return '🏪';
      case NodeType.rest:
        return '🛏️';
      case NodeType.elite:
        return '💀';
      case NodeType.randomEvent:
        return '❓';
      case NodeType.bossCombat:
        return '👹';
    }
  }

  /// Whether this node type involves combat.
  bool get isCombat =>
      this == NodeType.combat ||
      this == NodeType.elite ||
      this == NodeType.bossCombat;

  /// Whether this node type is a reward/utility node.
  bool get isUtility =>
      this == NodeType.spellLearn ||
      this == NodeType.enhancementShrine ||
      this == NodeType.shop ||
      this == NodeType.rest;

  /// Whether this node type is non-combat (Phase 7.6).
  /// Used for pre-elite and pre-boss path safety checks.
  bool get isNonCombat =>
      this == NodeType.rest ||
      this == NodeType.shop ||
      this == NodeType.enhancementShrine ||
      this == NodeType.randomEvent ||
      this == NodeType.spellLearn;

  /// Whether this node type is allowed before elites/bosses (Phase 7.6).
  /// These are guaranteed prep nodes. Includes non-hostile events.
  bool get isAllowedBeforeEliteOrBoss =>
      this == NodeType.rest ||
      this == NodeType.shop ||
      this == NodeType.enhancementShrine ||
      this == NodeType.spellLearn ||
      this == NodeType.randomEvent; // Non-hostile events allowed

  /// Whether this node type is a high-danger encounter.
  bool get isEliteOrBoss =>
      this == NodeType.elite || this == NodeType.bossCombat;
}
