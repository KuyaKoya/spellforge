import '../domain/element.dart';
import '../progression/elemental_path.dart';
import '../progression/elemental_node.dart';
import '../progression/node_modifier.dart';

/// Initializes all elemental path definitions.
/// Call this at app startup before accessing paths.
void initializeElementalPaths() {
  if (ElementalPathRegistry.isInitialized) return;

  ElementalPathRegistry.register(_createFirePath());
  ElementalPathRegistry.register(_createWaterPath());
  ElementalPathRegistry.register(_createEarthPath());
  ElementalPathRegistry.register(_createAirPath());
}

// =============================================================================
// 🔥 FIRE PATH - Destruction & Risk
// =============================================================================

ElementalPath _createFirePath() {
  return ElementalPath(
    element: Element.fire,
    theme: 'Destruction & Risk',
    description:
        'High damage at the cost of self-exposure. '
        'Fire mages burn bright and fast.',
    nodes: [
      // Tier 1: Nodes 0-2 (Cost: 10, 15, 20)
      ElementalNode(
        element: Element.fire,
        index: 0,
        cost: NodeCostScale.getCost(0),
        name: 'Ember Spark',
        effectDescription: '+5% Fire damage',
        tradeoffDescription: '−2% max HP',
        benefit: NodeModifier.benefit(
          type: ModifierType.damagePercent,
          value: 5,
          targetElement: Element.fire,
          description: '+5% Fire damage',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.maxHPPercent,
          value: 2,
          description: '−2% max HP',
        ),
      ),
      ElementalNode(
        element: Element.fire,
        index: 1,
        cost: NodeCostScale.getCost(1),
        name: 'Lasting Flames',
        effectDescription: 'Burn lasts +1 turn',
        tradeoffDescription: 'Burn deals −10% damage',
        benefit: NodeModifier.benefit(
          type: ModifierType.burnDuration,
          value: 1,
          description: 'Burn lasts +1 turn',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.burnDamagePercent,
          value: 10,
          description: 'Burn deals −10% damage',
        ),
      ),
      ElementalNode(
        element: Element.fire,
        index: 2,
        cost: NodeCostScale.getCost(2),
        name: 'Efficient Blaze',
        effectDescription: 'Fire spells cost −1 mana',
        tradeoffDescription: 'Non-fire spells cost +1 mana',
        benefit: NodeModifier.benefit(
          type: ModifierType.manaCostFlat,
          value: 1,
          targetElement: Element.fire,
          description: 'Fire spells cost −1 mana',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.manaCostFlat,
          value: 1,
          description: 'Non-fire spells cost +1 mana',
        ),
      ),
      // Tier 2: Nodes 3-5 (Cost: 30, 40, 50)
      ElementalNode(
        element: Element.fire,
        index: 3,
        cost: NodeCostScale.getCost(3),
        name: 'Pyromaniac',
        effectDescription: '+10% damage vs Burning enemies',
        tradeoffDescription: '−5 armor',
        benefit: NodeModifier.benefit(
          type: ModifierType.damagePercent,
          value: 10,
          description: '+10% damage vs Burning enemies',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.armorFlat,
          value: 5,
          description: '−5 armor',
        ),
      ),
      ElementalNode(
        element: Element.fire,
        index: 4,
        cost: NodeCostScale.getCost(4),
        name: 'Spreading Fire',
        effectDescription: 'Burn stacks deal splash damage',
        tradeoffDescription: 'Burn expires 1 turn faster',
        benefit: NodeModifier.benefit(
          type: ModifierType.splashOnBurn,
          value: 1,
          description: 'Burn deals splash damage',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.burnDuration,
          value: 1,
          description: 'Burn expires 1 turn faster',
        ),
      ),
      ElementalNode(
        element: Element.fire,
        index: 5,
        cost: NodeCostScale.getCost(5),
        name: 'Critical Combustion',
        effectDescription: 'Fire spells crit +5%',
        tradeoffDescription: 'Crits deal 3 self-damage',
        benefit: NodeModifier.benefit(
          type: ModifierType.critChance,
          value: 5,
          targetElement: Element.fire,
          description: 'Fire spells crit +5%',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.damagePercent,
          value: 3,
          description: 'Crits deal 3 self-damage',
        ),
      ),
      // Tier 3: Nodes 6-9 (Cost: 75, 90, 105, 120)
      ElementalNode(
        element: Element.fire,
        index: 6,
        cost: NodeCostScale.getCost(6),
        name: 'Piercing Heat',
        effectDescription: 'Burn ignores shields',
        tradeoffDescription: 'Enemies gain +5% burn resist',
        benefit: NodeModifier.benefit(
          type: ModifierType.burnIgnoresShield,
          value: 1,
          description: 'Burn ignores shields',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.resistancePercent,
          value: 5,
          targetElement: Element.fire,
          description: 'Enemies gain +5% burn resist',
        ),
      ),
      ElementalNode(
        element: Element.fire,
        index: 7,
        cost: NodeCostScale.getCost(7),
        name: 'Inferno Mastery',
        effectDescription: '+15% Fire damage',
        tradeoffDescription: '−10% Water resistance',
        benefit: NodeModifier.benefit(
          type: ModifierType.damagePercent,
          value: 15,
          targetElement: Element.fire,
          description: '+15% Fire damage',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.resistancePercent,
          value: 10,
          targetElement: Element.water,
          description: '−10% Water resistance',
        ),
      ),
      ElementalNode(
        element: Element.fire,
        index: 8,
        cost: NodeCostScale.getCost(8),
        name: 'Death Pyre',
        effectDescription: 'Burns trigger on enemy kill',
        tradeoffDescription: 'Burn damage −5%',
        benefit: NodeModifier.benefit(
          type: ModifierType.burnDuration,
          value: 1,
          description: 'Burn triggers on kill',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.burnDamagePercent,
          value: 5,
          description: 'Burn damage −5%',
        ),
      ),
      ElementalNode(
        element: Element.fire,
        index: 9,
        cost: NodeCostScale.getCost(9),
        name: 'Infernal Momentum',
        effectDescription: 'Fire spells gain +3% damage each turn',
        tradeoffDescription: 'Lose all stacks when hit',
        benefit: NodeModifier.benefit(
          type: ModifierType.damagePercent,
          value: 3,
          targetElement: Element.fire,
          description: 'Fire damage ramps each turn',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.damagePercent,
          value: 0,
          description: 'Lose stacks when hit',
        ),
        isPassive: true,
        passiveName: 'Infernal Momentum',
      ),
    ],
  );
}

// =============================================================================
// 💧 WATER PATH - Control & Endurance
// =============================================================================

ElementalPath _createWaterPath() {
  return ElementalPath(
    element: Element.water,
    theme: 'Control & Endurance',
    description:
        'Tempo manipulation and sustain. '
        'Water mages outlast their enemies.',
    nodes: [
      // Tier 1: Nodes 0-2
      ElementalNode(
        element: Element.water,
        index: 0,
        cost: NodeCostScale.getCost(0),
        name: 'Tidal Wave',
        effectDescription: '+5% Water damage',
        tradeoffDescription: '−5% Fire damage',
        benefit: NodeModifier.benefit(
          type: ModifierType.damagePercent,
          value: 5,
          targetElement: Element.water,
          description: '+5% Water damage',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.damagePercent,
          value: 5,
          targetElement: Element.fire,
          description: '−5% Fire damage',
        ),
      ),
      ElementalNode(
        element: Element.water,
        index: 1,
        cost: NodeCostScale.getCost(1),
        name: 'Lingering Chill',
        effectDescription: 'Slow lasts +1 turn',
        tradeoffDescription: 'Slow reduces damage −5% less',
        benefit: NodeModifier.benefit(
          type: ModifierType.slowDuration,
          value: 1,
          description: 'Slow lasts +1 turn',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.damagePercent,
          value: 5,
          description: 'Slow reduction weakened',
        ),
      ),
      ElementalNode(
        element: Element.water,
        index: 2,
        cost: NodeCostScale.getCost(2),
        name: 'Armored Tide',
        effectDescription: '+5 armor at battle start',
        tradeoffDescription: '−5% speed',
        benefit: NodeModifier.benefit(
          type: ModifierType.battleStartArmor,
          value: 5,
          description: '+5 armor at battle start',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.speedPercent,
          value: 5,
          description: '−5% speed',
        ),
      ),
      // Tier 2: Nodes 3-5
      ElementalNode(
        element: Element.water,
        index: 3,
        cost: NodeCostScale.getCost(3),
        name: 'Restorative Waters',
        effectDescription: 'Healing effects +10%',
        tradeoffDescription: '−3% max HP',
        benefit: NodeModifier.benefit(
          type: ModifierType.healingPercent,
          value: 10,
          description: 'Healing effects +10%',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.maxHPPercent,
          value: 3,
          description: '−3% max HP',
        ),
      ),
      ElementalNode(
        element: Element.water,
        index: 4,
        cost: NodeCostScale.getCost(4),
        name: 'Freezing Priority',
        effectDescription: 'Slowed enemies act last',
        tradeoffDescription: 'Slow less effective on elites',
        benefit: NodeModifier.benefit(
          type: ModifierType.slowDuration,
          value: 1,
          description: 'Slowed enemies act last',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.slowDuration,
          value: 1,
          description: 'Slow weaker on elites',
        ),
      ),
      ElementalNode(
        element: Element.water,
        index: 5,
        cost: NodeCostScale.getCost(5),
        name: 'Efficient Flow',
        effectDescription: 'Water spells cost −1 mana',
        tradeoffDescription: 'Wind spells cost +1 mana',
        benefit: NodeModifier.benefit(
          type: ModifierType.manaCostFlat,
          value: 1,
          targetElement: Element.water,
          description: 'Water spells cost −1 mana',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.manaCostFlat,
          value: 1,
          targetElement: Element.air,
          description: 'Wind spells cost +1 mana',
        ),
      ),
      // Tier 3: Nodes 6-9
      ElementalNode(
        element: Element.water,
        index: 6,
        cost: NodeCostScale.getCost(6),
        name: 'Barrier Surge',
        effectDescription: 'Shield gain +15%',
        tradeoffDescription: 'Shields decay 1 turn faster',
        benefit: NodeModifier.benefit(
          type: ModifierType.shieldPercent,
          value: 15,
          description: 'Shield gain +15%',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.shieldDecay,
          value: 1,
          description: 'Shields decay faster',
        ),
      ),
      ElementalNode(
        element: Element.water,
        index: 7,
        cost: NodeCostScale.getCost(7),
        name: 'Ocean Mastery',
        effectDescription: '+15% Water damage',
        tradeoffDescription: '−10% Wind resistance',
        benefit: NodeModifier.benefit(
          type: ModifierType.damagePercent,
          value: 15,
          targetElement: Element.water,
          description: '+15% Water damage',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.resistancePercent,
          value: 10,
          targetElement: Element.air,
          description: '−10% Wind resistance',
        ),
      ),
      ElementalNode(
        element: Element.water,
        index: 8,
        cost: NodeCostScale.getCost(8),
        name: 'Purification',
        effectDescription: 'Cleanse one debuff on battle start',
        tradeoffDescription: '+1 turn debuff cooldown',
        benefit: NodeModifier.benefit(
          type: ModifierType.healingPercent,
          value: 1,
          description: 'Cleanse debuff on battle start',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.slowDuration,
          value: 1,
          description: 'Longer debuff cooldown',
        ),
      ),
      ElementalNode(
        element: Element.water,
        index: 9,
        cost: NodeCostScale.getCost(9),
        name: 'Tidal Control',
        effectDescription: 'First enemy always acts second',
        tradeoffDescription: 'Bosses gain +5% speed',
        benefit: NodeModifier.benefit(
          type: ModifierType.enemyActSecond,
          value: 1,
          description: 'First enemy acts second',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.speedPercent,
          value: 5,
          description: 'Bosses gain speed',
        ),
        isPassive: true,
        passiveName: 'Tidal Control',
      ),
    ],
  );
}

// =============================================================================
// 🪨 EARTH PATH - Fortification & Attrition
// =============================================================================

ElementalPath _createEarthPath() {
  return ElementalPath(
    element: Element.earth,
    theme: 'Fortification & Attrition',
    description:
        'Armor, endurance, and inevitability. '
        'Earth mages cannot be moved.',
    nodes: [
      // Tier 1: Nodes 0-2
      ElementalNode(
        element: Element.earth,
        index: 0,
        cost: NodeCostScale.getCost(0),
        name: 'Stone Skin',
        effectDescription: '+10 armor at battle start',
        tradeoffDescription: '−5% damage',
        benefit: NodeModifier.benefit(
          type: ModifierType.battleStartArmor,
          value: 10,
          description: '+10 armor at battle start',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.damagePercent,
          value: 5,
          description: '−5% damage',
        ),
      ),
      ElementalNode(
        element: Element.earth,
        index: 1,
        cost: NodeCostScale.getCost(1),
        name: 'Fortified Wall',
        effectDescription: 'Shield values +10%',
        tradeoffDescription: 'Shields decay each turn',
        benefit: NodeModifier.benefit(
          type: ModifierType.shieldPercent,
          value: 10,
          description: 'Shield values +10%',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.shieldDecay,
          value: 1,
          description: 'Shields decay each turn',
        ),
      ),
      ElementalNode(
        element: Element.earth,
        index: 2,
        cost: NodeCostScale.getCost(2),
        name: 'Efficient Quake',
        effectDescription: 'Earth spells cost −1 mana',
        tradeoffDescription: 'Fire spells cost +1 mana',
        benefit: NodeModifier.benefit(
          type: ModifierType.manaCostFlat,
          value: 1,
          targetElement: Element.earth,
          description: 'Earth spells cost −1 mana',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.manaCostFlat,
          value: 1,
          targetElement: Element.fire,
          description: 'Fire spells cost +1 mana',
        ),
      ),
      // Tier 2: Nodes 3-5
      ElementalNode(
        element: Element.earth,
        index: 3,
        cost: NodeCostScale.getCost(3),
        name: 'Ironclad',
        effectDescription: '+5% damage per 10 armor',
        tradeoffDescription: '−5% speed',
        benefit: NodeModifier.benefit(
          type: ModifierType.damagePercent,
          value: 5,
          description: '+5% damage per armor tier',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.speedPercent,
          value: 5,
          description: '−5% speed',
        ),
      ),
      ElementalNode(
        element: Element.earth,
        index: 4,
        cost: NodeCostScale.getCost(4),
        name: 'Regenerating Stone',
        effectDescription: 'Gain +3 armor each turn',
        tradeoffDescription: 'Armor caps at 30',
        benefit: NodeModifier.benefit(
          type: ModifierType.armorPerTurn,
          value: 3,
          description: 'Gain +3 armor each turn',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.armorFlat,
          value: 30,
          description: 'Armor caps at 30',
        ),
      ),
      ElementalNode(
        element: Element.earth,
        index: 5,
        cost: NodeCostScale.getCost(5),
        name: 'Crushing Weight',
        effectDescription: 'Earth spells apply weaken',
        tradeoffDescription: 'Weaken duration −1 turn',
        benefit: NodeModifier.benefit(
          type: ModifierType.slowDuration,
          value: 1,
          description: 'Earth spells weaken',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.slowDuration,
          value: 1,
          description: 'Weaken duration −1',
        ),
      ),
      // Tier 3: Nodes 6-9
      ElementalNode(
        element: Element.earth,
        index: 6,
        cost: NodeCostScale.getCost(6),
        name: 'Absolute Defense',
        effectDescription: 'Armor mitigates true damage (50%)',
        tradeoffDescription: 'Healing reduced by 20%',
        benefit: NodeModifier.benefit(
          type: ModifierType.armorFlat,
          value: 50,
          description: 'Armor blocks true damage',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.healingPercent,
          value: 20,
          description: 'Healing reduced 20%',
        ),
      ),
      ElementalNode(
        element: Element.earth,
        index: 7,
        cost: NodeCostScale.getCost(7),
        name: 'Mountain Mastery',
        effectDescription: '+15% Earth damage',
        tradeoffDescription: '−10% Air resistance',
        benefit: NodeModifier.benefit(
          type: ModifierType.damagePercent,
          value: 15,
          targetElement: Element.earth,
          description: '+15% Earth damage',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.resistancePercent,
          value: 10,
          targetElement: Element.air,
          description: '−10% Air resistance',
        ),
      ),
      ElementalNode(
        element: Element.earth,
        index: 8,
        cost: NodeCostScale.getCost(8),
        name: 'Persistent Barrier',
        effectDescription: 'Shields persist between rooms (50%)',
        tradeoffDescription: 'Shield cap lowered by 20%',
        benefit: NodeModifier.benefit(
          type: ModifierType.shieldPersist,
          value: 50,
          description: 'Shields persist (50%)',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.shieldPercent,
          value: 20,
          description: 'Shield cap −20%',
        ),
      ),
      ElementalNode(
        element: Element.earth,
        index: 9,
        cost: NodeCostScale.getCost(9),
        name: 'Unyielding',
        effectDescription: 'First lethal hit leaves you at 1 HP',
        tradeoffDescription: 'Once per run only',
        benefit: NodeModifier.benefit(
          type: ModifierType.lethalSurvive,
          value: 1,
          description: 'Survive first lethal hit',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.lethalSurvive,
          value: 0,
          description: 'Once per run',
        ),
        isPassive: true,
        passiveName: 'Unyielding',
      ),
    ],
  );
}

// =============================================================================
// 💨 WIND PATH - Speed & Precision
// =============================================================================

ElementalPath _createAirPath() {
  return ElementalPath(
    element: Element.air,
    theme: 'Speed & Precision',
    description:
        'Turn control and spell frequency. '
        'Wind mages strike before you blink.',
    nodes: [
      // Tier 1: Nodes 0-2
      ElementalNode(
        element: Element.air,
        index: 0,
        cost: NodeCostScale.getCost(0),
        name: 'Swift Breeze',
        effectDescription: '+5% speed',
        tradeoffDescription: '−5 armor',
        benefit: NodeModifier.benefit(
          type: ModifierType.speedPercent,
          value: 5,
          description: '+5% speed',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.armorFlat,
          value: 5,
          description: '−5 armor',
        ),
      ),
      ElementalNode(
        element: Element.air,
        index: 1,
        cost: NodeCostScale.getCost(1),
        name: 'Priority Strike',
        effectDescription: 'Wind spells +1 priority',
        tradeoffDescription: 'Wind damage −5%',
        benefit: NodeModifier.benefit(
          type: ModifierType.speedPercent,
          value: 1,
          targetElement: Element.air,
          description: 'Wind spells have priority',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.damagePercent,
          value: 5,
          targetElement: Element.air,
          description: 'Wind damage −5%',
        ),
      ),
      ElementalNode(
        element: Element.air,
        index: 2,
        cost: NodeCostScale.getCost(2),
        name: 'Opening Gust',
        effectDescription: '+1 card draw first turn',
        tradeoffDescription: 'Max hand size −1',
        benefit: NodeModifier.benefit(
          type: ModifierType.firstTurnDraw,
          value: 1,
          description: '+1 draw first turn',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.maxHand,
          value: 1,
          description: 'Max hand −1',
        ),
      ),
      // Tier 2: Nodes 3-5
      ElementalNode(
        element: Element.air,
        index: 3,
        cost: NodeCostScale.getCost(3),
        name: 'Efficient Gale',
        effectDescription: 'Wind spells cost −1 mana',
        tradeoffDescription: 'Earth spells cost +1 mana',
        benefit: NodeModifier.benefit(
          type: ModifierType.manaCostFlat,
          value: 1,
          targetElement: Element.air,
          description: 'Wind spells cost −1 mana',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.manaCostFlat,
          value: 1,
          targetElement: Element.earth,
          description: 'Earth spells cost +1 mana',
        ),
      ),
      ElementalNode(
        element: Element.air,
        index: 4,
        cost: NodeCostScale.getCost(4),
        name: 'Quick Reflexes',
        effectDescription: 'Act first if speed is higher',
        tradeoffDescription: 'Act last if speed is tied',
        benefit: NodeModifier.benefit(
          type: ModifierType.actFirst,
          value: 1,
          description: 'Act first if faster',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.actFirst,
          value: 0,
          description: 'Act last if tied',
        ),
      ),
      ElementalNode(
        element: Element.air,
        index: 5,
        cost: NodeCostScale.getCost(5),
        name: 'Precision Focus',
        effectDescription: '+10% crit chance',
        tradeoffDescription: 'Crit damage −10%',
        benefit: NodeModifier.benefit(
          type: ModifierType.critChance,
          value: 10,
          description: '+10% crit chance',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.critDamage,
          value: 10,
          description: 'Crit damage −10%',
        ),
      ),
      // Tier 3: Nodes 6-9
      ElementalNode(
        element: Element.air,
        index: 6,
        cost: NodeCostScale.getCost(6),
        name: 'Evasive Maneuver',
        effectDescription: 'Evade the first hit each battle',
        tradeoffDescription: '3 turn cooldown per battle',
        benefit: NodeModifier.benefit(
          type: ModifierType.evadeFirstHit,
          value: 1,
          description: 'Evade first hit',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.evadeFirstHit,
          value: 3,
          description: '3 turn cooldown',
        ),
      ),
      ElementalNode(
        element: Element.air,
        index: 7,
        cost: NodeCostScale.getCost(7),
        name: 'Storm Mastery',
        effectDescription: '+15% Wind damage',
        tradeoffDescription: '−10% Earth resistance',
        benefit: NodeModifier.benefit(
          type: ModifierType.damagePercent,
          value: 15,
          targetElement: Element.air,
          description: '+15% Wind damage',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.resistancePercent,
          value: 10,
          targetElement: Element.earth,
          description: '−10% Earth resistance',
        ),
      ),
      ElementalNode(
        element: Element.air,
        index: 8,
        cost: NodeCostScale.getCost(8),
        name: 'Momentum Kill',
        effectDescription: 'Extra action on kill (once per battle)',
        tradeoffDescription: 'Gain fatigue debuff for 1 turn',
        benefit: NodeModifier.benefit(
          type: ModifierType.extraActionOnKill,
          value: 1,
          description: 'Extra action on kill',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.speedPercent,
          value: 10,
          description: 'Fatigue debuff',
        ),
      ),
      ElementalNode(
        element: Element.air,
        index: 9,
        cost: NodeCostScale.getCost(9),
        name: 'Perfect Tempo',
        effectDescription: 'First 2 turns always yours',
        tradeoffDescription: 'Turns 3+ are 20% slower',
        benefit: NodeModifier.benefit(
          type: ModifierType.actFirst,
          value: 2,
          description: 'First 2 turns guaranteed',
        ),
        tradeoff: NodeModifier.tradeoff(
          type: ModifierType.speedPercent,
          value: 20,
          description: 'Turns 3+ slower',
        ),
        isPassive: true,
        passiveName: 'Perfect Tempo',
      ),
    ],
  );
}
