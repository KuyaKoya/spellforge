import '../progression/core_path.dart';
import '../progression/node_modifier.dart';

/// Initializes the core path with all node definitions.
/// Call this at app startup before accessing the core path.
void initializeCorePath() {
  if (CorePathRegistry.isInitialized) return;

  CorePathRegistry.register(_createCorePath());
}

CorePath _createCorePath() {
  return CorePath(
    nodes: [
      // =================================================================
      // TIER 1: FRAGMENTS (Affordable early-game progression)
      // =================================================================
      CoreNode(
        index: 0,
        cost: CoreNodeCostScale.getCost(0),
        name: 'Inner Strength',
        effectDescription: '+3% all damage',
        benefit: NodeModifier.benefit(
          type: ModifierType.damagePercent,
          value: 3,
          description: '+3% all damage',
        ),
      ),
      CoreNode(
        index: 1,
        cost: CoreNodeCostScale.getCost(1),
        name: 'Vitality',
        effectDescription: '+5% max HP',
        benefit: NodeModifier.benefit(
          type: ModifierType.maxHPPercent,
          value: 5,
          description: '+5% max HP',
        ),
      ),
      CoreNode(
        index: 2,
        cost: CoreNodeCostScale.getCost(2),
        name: 'Quick Mind',
        effectDescription: '+3% speed',
        benefit: NodeModifier.benefit(
          type: ModifierType.speedPercent,
          value: 3,
          description: '+3% speed',
        ),
      ),

      // =================================================================
      // TIER 2: CRYSTALS (Mid-game investment)
      // =================================================================
      CoreNode(
        index: 3,
        cost: CoreNodeCostScale.getCost(3),
        name: 'Power Surge',
        effectDescription: '+5% all damage',
        benefit: NodeModifier.benefit(
          type: ModifierType.damagePercent,
          value: 5,
          description: '+5% all damage',
        ),
      ),
      CoreNode(
        index: 4,
        cost: CoreNodeCostScale.getCost(4),
        name: 'Thick Skin',
        effectDescription: '+5 armor at battle start',
        benefit: NodeModifier.benefit(
          type: ModifierType.battleStartArmor,
          value: 5,
          description: '+5 armor at battle start',
        ),
      ),
      CoreNode(
        index: 5,
        cost: CoreNodeCostScale.getCost(5),
        name: 'Precision',
        effectDescription: '+5% crit chance',
        benefit: NodeModifier.benefit(
          type: ModifierType.critChance,
          value: 5,
          description: '+5% crit chance',
        ),
      ),

      // =================================================================
      // TIER 3: CRYSTALS (Late-game power)
      // =================================================================
      CoreNode(
        index: 6,
        cost: CoreNodeCostScale.getCost(6),
        name: 'Devastation',
        effectDescription: '+8% all damage',
        benefit: NodeModifier.benefit(
          type: ModifierType.damagePercent,
          value: 8,
          description: '+8% all damage',
        ),
      ),
      CoreNode(
        index: 7,
        cost: CoreNodeCostScale.getCost(7),
        name: 'Fortitude',
        effectDescription: '+8% max HP',
        benefit: NodeModifier.benefit(
          type: ModifierType.maxHPPercent,
          value: 8,
          description: '+8% max HP',
        ),
      ),
      CoreNode(
        index: 8,
        cost: CoreNodeCostScale.getCost(8),
        name: 'Mana Efficiency',
        effectDescription: 'All spells cost -1 mana',
        benefit: NodeModifier.benefit(
          type: ModifierType.manaCostFlat,
          value: 1,
          description: 'All spells cost -1 mana',
        ),
      ),
      CoreNode(
        index: 9,
        cost: CoreNodeCostScale.getCost(9),
        name: 'Apex Predator',
        effectDescription: '+10% all damage, +5% crit damage',
        benefit: NodeModifier.benefit(
          type: ModifierType.damagePercent,
          value: 10,
          description: '+10% damage, +5% crit damage',
        ),
        isCapstone: true,
      ),
    ],
  );
}
