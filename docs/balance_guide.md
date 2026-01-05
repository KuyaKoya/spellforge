# Spellforge Balance Guide

> Phase 7 — B1-B6: Balance Framework
>
> This framework ensures your numbers feel good now and scale later.

---

## Core Balance Principles (B1)

### Principle 1 — No Perfect Spell

Every spell must have:

- **A strength** — what it excels at
- **A weakness** — when it underperforms
- **A reason not to cast it every turn** — opportunity cost

| Tier | Strength | Weakness | Skip When |
|------|----------|----------|-----------|
| Basic | Cheap | Low impact | Better options exist |
| Core | Reliable | Not spectacular | Need burst/utility |
| Heavy | Big damage | Expensive | Low mana / overkill |
| Utility | Control | No damage | Need to kill fast |

### Principle 2 — Mana Is a Strategic Resource

Mana should:

- Be **tight early** — first few turns feel constrained
- Become **flexible mid-fight** — options open up
- **Never be infinite** — always a consideration

Design implications:

- Starting mana: 10 (enough for 2-3 basic spells or 1 heavy + 1 basic)
- No passive mana regeneration during combat
- MP potions are rare and expensive
- End-of-combat mana restoration is partial

### Principle 3 — Damage Is Predictable, Outcomes Are Not

Variance comes from:

- **Status effects** — burn, slow, weaken create emergent situations
- **Enemy behavior** — intent system creates tactical decisions
- **Player decisions** — spell selection, targeting, resource management

*Not* from:

- Raw damage RNG
- Random miss chances
- Arbitrary critical hits

---

## Base Stat Curves (B2)

### Player (Per Level)

| Stat | Per Level | Rationale |
|------|-----------|-----------|
| HP | +8-12 (avg 10) | Meaningful survivability increase |
| MP | +2-3 (avg 2) | Opens up one extra spell cast |
| Action | +1 per 3 levels | Major power spike, spaced out |

**Starting Stats (Level 1):**

- HP: 50
- MP: 10
- Actions: 1

### Enemy Scaling (Act 1)

| Metric      | Formula             | Example (Player 50 HP) |
|-------------|---------------------|------------------------|
| Enemy HP    | Player HP × 0.8-1.2 | 40-60 HP               |
| Damage/Turn | Player HP × 15-25%  | 8-13 damage            |

This creates:

- 4-6 turn average fights (tactical depth)
- 15-40% HP loss per encounter (meaningful attrition)
- Room for player mistakes without instant death

---

## Spell Cost vs Effect Matrix (B3)

| Spell Type | Mana Cost | Damage         | Extra Effect   |
|------------|-----------|----------------|----------------|
| Basic      | 1-2       | Low (8-12)     | None / setup   |
| Core       | 3-4       | Medium (18-24) | Single status  |
| Heavy      | 5-6       | High (30-40)   | Conditional    |
| Utility    | 2-4       | None           | Control        |

### Design Rules

1. **Heavy spells must never be spammable**
   - Cost 5+ mana
   - May require conditions (low HP target, status on target)
   - Opening with Heavy = all-in strategy

2. **Utility spells must always be situationally strong**
   - Clear use case (crowd control, buff, debuff)
   - Trade damage for tactical advantage
   - Shine in specific encounters

3. **Basic spells are never dead cards**
   - Always castable
   - Enable synergies
   - Emergency options when low on mana

---

## Status Effect Balance (B4)

### Burn 🔥

- **Damage:** 2-3 per turn
- **Stacking:** Slow (max 3 stacks)
- **Strategy:** Best against high HP enemies
- **Duration:** 2-3 turns

*Design note: Burn rewards patience. Stack it up against the boss, not trash mobs.*

### Slow 🐌

- **Effect:** Reduces action frequency
- **Damage:** None
- **Strategy:** Enables control playstyles
- **Duration:** 2 turns

*Design note: Slow doesn't deal damage but reduces enemy threat output significantly.*

### Weaken 💔

- **Effect:** Reduces damage dealt by target (15-25%)
- **Application:** Strong against high-damage enemies
- **Duration:** 2-3 turns

*Design note: Weaken is insurance. Cast it before the big attack comes.*

### Shield/Armor 🛡️

- **Effect:** Absorbs damage
- **Value:** 5-10 per application
- **Duration:** Until depleted or 2 turns

*Design note: Shields are reactive. Best cast when you know damage is incoming.*

---

## Enemy Design Rules (B5)

### Every Enemy Must

1. **Teach one mechanic**
   - Slime → basic combat flow
   - Fire Elemental → elemental weaknesses
   - Armored Knight → dealing with shields

2. **Punish one mistake**
   - Slime → ignoring basic attacks
   - Fire Elemental → wrong element usage
   - Armored Knight → attacking shields head-on

3. **Be weak to one strategy**
   - Slime → any focused damage
   - Fire Elemental → water spells, patience
   - Armored Knight → status effects, waiting out shield

### Gatekeeper Bosses

- **Test composition, not damage**
  - Require 2+ elements in loadout
  - Require both damage and utility
  - Punish one-dimensional builds

- **Require adaptation, not grinding**
  - Beatable at expected level
  - Demand understanding of mechanics
  - Can be defeated with clever play

---

## Elite & Boss Passive Systems (Phase 7.5)

### Passive Power Levels

| Enemy Type | Passives | Power Level      |
|------------|----------|------------------|
| Normal     | 0        | None             |
| Elite      | 2        | Run-defining     |
| Boss       | 3        | Pattern-defining |

### Design Principles

1. **Passives Define Identity**
   - Each passive tells you *who* the enemy is
   - Not just stat buffs — mechanical changes
   - Create tactical puzzle for the player

2. **Visibility & Readability**
   - Boss passives are always visible
   - Elite passives visible in inspection panel
   - Trigger conditions clearly communicated

3. **Synergy Over Isolation**
   - Passives interact with spells and AI
   - Never standalone stat bonuses
   - Create emergent gameplay

### Elite Passives Reference

| Elite               | Passive 1 (Elemental)                                     | Passive 2 (Behavioral)                                        |
|---------------------|-----------------------------------------------------------|---------------------------------------------------------------|
| Burnward Colossus   | 🔱 Molten Carapace: Fire damage → +3 Armor                | 💥 Earthen Retaliation: Armor break → Burn immunity + shockwave|
| Tempest Twin A      | 🌪 Cyclone Momentum: +10% damage per consecutive action  | 🔗 Twin Synchrony: +1 priority if twin acts                   |
| Tempest Twin B      | 🌬 Gale Veil: First hit each turn deals 50% damage       | 🔗 Twin Synchrony: +1 priority if twin acts                   |
| Glacial Executioner | ❄️ Permafrost Edge: Slowed targets get Frozen           | 🎯 Cold Precision: +20% damage vs <50% HP                     |
| Infernal Warlord    | 🔥 Blazing Adaptation: Resistance to repeated elements    | ⚔️ War Temper: Burn ticks → +1 damage (stacking)              |
| Stone Sentinel      | 🗿 Immutable Form: Max 20% HP loss per turn               | 🛡️ Bastion Protocol: 50% Armor → HP at turn start             |
| Typhoon Herald      | 🌊 Riptide Casting: Spells apply Slow                     | ⚡ Tempest Flow: Extra action every 4 turns if >50% HP        |

### Boss Systemic Passives

| Boss               | Modifiers                   | Systemic Passive                                     |
|--------------------|-----------------------------|------------------------------------------------------|
| Gatekeeper of Pyre | Burn Immune, Fire Resistant | 🔨 Forge of Endurance: Armor gain → +1 permanent damage|
| Gatekeeper of Tide | Slow Immune, Water Resistant| 🌀 Tidal Reversal: First spell each turn -50% effect |

### AI Integration

- AI must prioritize spells that trigger passives
- Passive-triggering spells gain +20 priority score
- Bosses never waste turns violating their passive identity

---

## Run Failure Philosophy (B6)

### A Run Should End Because

✅ **Player misunderstood risk**
> "I didn't realize that enemy was about to attack"
> → Intent system showed warning, player ignored it

✅ **Player overcommitted resources**
> "I spent all my mana on damage and couldn't heal"
> → Resource management failure, not RNG

✅ **Player ignored signals**
> "The elite warning was there, but I engaged anyway"
> → Risk assessment failure

### A Run Should NEVER End Because

❌ **Random unavoidable spike**
> No enemy should one-shot from hidden intent

❌ **Hidden mechanic**
> All boss mechanics should be learnable through telegraphing

❌ **UI ambiguity**
> Player should always know:
>
> - Whose turn it is
> - What enemy intends
> - Whether they can afford spells

---

## Phase 7 Success Metrics

Phase 7 is complete when:

✅ **You can explain combat without words**

- Visual affordances make interactions clear
- Turn ownership is unambiguous
- Status effects are visible

✅ **You can add a new spell without fear**

- Spell tier system guides cost/effect
- Clear trade-offs in every design
- Balance constants are centralized

✅ **You can add a new enemy in <30 minutes**

- Teach/Punish/Weakness framework
- Scaling formulas handle numbers
- Intent system handles behavior

✅ **Players die and say "That was my fault"**

- Deaths are traceable to decisions
- No cheap shots or RNG deaths
- Clear signals were given

---

## Phase 7.6: Pre-Elite & Pre-Boss Path Safety

### Guaranteed Non-Combat Path Before Elites (13.1)

**Rule**: Before every Elite node, the Director ensures at least one adjacent non-combat node is reachable.

**Allowed Non-Combat Nodes**:

- Rest
- Shop
- Enhancement Shrine
- Event (non-hostile)
- Spell Learn

**Design Intent**:

- Gives players agency before a difficulty spike
- Enables preparation instead of brute forcing
- Reduces frustration from sudden elite encounters

### Guaranteed Non-Combat Before Boss (13.2)

**Rule**: The node immediately before the Boss is always non-combat.

This node:

- Cannot be rerolled into combat
- Is visible on breadcrumbs
- Is narratively framed as "calm before the gate"

**Recommended Node Types** (in priority order):

1. Enhancement Shrine (preferred)
2. Rest Node
3. Spell Learn
4. Shop

### Director Enforcement Logic (13.3)

Director validates node placement at generation time:

```text
If next node is Elite:
  ensure previous node != Combat

If next node is Boss:
  enforce previous node = Non-Combat
```

Failure to satisfy forces reroll of the preceding node.

---

## Phase 7.6: Spell Learn Node Tier Scaling

### Dynamic Spell Tier Advancement (14.1)

Spell Learn nodes no longer offer flat rarity. Maximum tier increases with depth:

| Run Depth | Max Spell Tier            |
|-----------|---------------------------|
| 1–2       | Common                    |
| 3–4       | Uncommon                  |
| 5–6       | Rare                      |
| 7+        | Rare + Star Upgrade Chance|

### Star Upgrade Injection (14.2)

At deeper depths, Spell Learn nodes may offer:

- ★★ versions of existing spells
- Or a Rare spell with 1 modifier

**Star Upgrade Chance by Depth**:

| Depth | Chance |
|-------|--------|
| ≤6    | 0%     |
| 7     | 15%    |
| 8     | 25%    |
| 9+    | 35%    |

This replaces raw power creep with build refinement.

### Director + Starting Type Bias Integration (14.3)

Spell Learn weighting now stacks:

```text
Final Weight =
  Base Weight
  + Starting Type Bias
  + Depth Tier Bias
```

Weakness penalties still apply but never reduce availability to zero.

---

## Phase 7.6: UI Updates

### Spell Learn Node UI (15)

Spell Learn UI must:

- Display tier badge clearly (Common / Rare / ★★)
- Animate higher-tier offerings distinctly (glow effect)
- Indicate rarity through color coding

### Breadcrumb Visualization Updates (16)

Breadcrumbs visually show:

- **Elite nodes**: Red danger tint
- **Guaranteed non-combat nodes**: Faint blue protective glow
- **Boss gate**: Calm visual motif (muted blue)
- **Before boss**: Thicker calm-colored connector

---

## Phase 7.6 Completion Criteria

✅ Player always has prep before elites
✅ Boss approach feels deliberate
✅ Spell progression matches run depth
✅ Learn nodes feel exciting, not filler
✅ Breadcrumbs communicate danger and safety
