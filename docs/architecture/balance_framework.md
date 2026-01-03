# Spellforge Balance Framework — Phase 7

## PART B — CRITICAL BALANCE RULES

This document defines the balance principles that ensure Spellforge is fair,
predictable in variance, and scalable for future content.

---

## B1. Core Balance Principles

### Principle 1: No Perfect Spell

Every spell must have:

- A **strength** (what it's good at)
- A **weakness** (what it's bad at)
- A **reason not to cast every turn** (cost, situational, cooldown)

**Example:**

- Fireball: High damage, but costs 3 mana and doesn't work well against Fire enemies
- Shield: Great defense, but costs a turn that could be used for damage

### Principle 2: Mana Is a Strategic Resource

- **Early fight:** Mana is tight, must choose wisely
- **Mid fight:** Mana becomes flexible, can combo
- **Never:** Infinite mana, spam best spell every turn

**Regeneration:** 1-2 mana per turn is the sweet spot

### Principle 3: Damage Is Predictable, Outcomes Are Not

Variance comes from:

- ✅ Status effect interactions
- ✅ Enemy behavior patterns
- ✅ Player decisions and timing
- ❌ NOT from raw damage RNG (no "miss" or "critical" on basic attacks)

---

## B2. Base Stat Curves

### Player (Per Level)

| Stat | Base (Lv1) | Per Level | Notes |
|------|------------|-----------|-------|
| HP | 50 | +8-12 | Scales with difficulty |
| Max Mana | 8 | +2-3 | Tight early, flexible late |
| Actions/Turn | 1 | +1 every 3 levels | Max 3-4 by endgame |

### Enemy Scaling (Act 1)

| Metric | Formula | Purpose |
|--------|---------|---------|
| Enemy HP | Player HP × 0.8-1.2 | Fights last 3-5 turns |
| Enemy Damage | Player HP × 0.15-0.25 per turn | 4-6 hits to kill player |
| Armor Gain | 2-4 | Extends fights without burst |

### XP Requirements

| Level | XP Required | Cumulative |
|-------|-------------|------------|
| 1 | 10 | 10 |
| 2 | 15 | 25 |
| 3 | 22 | 47 |
| 4 | 30 | 77 |
| 5 | 40 | 117 |
| 6+ | +12/level | Scales |

---

## B3. Spell Cost vs Effect Matrix

| Spell Type | Mana Cost | Damage | Status Effect | Example |
|------------|-----------|--------|---------------|---------|
| **Basic** | 1-2 | Low (8-15) | None/Setup | Spark, Gust |
| **Core** | 3-4 | Medium (15-25) | Single status | Fireball, Ice Shard |
| **Heavy** | 5-6 | High (25-40) | Conditional | Meteor, Tsunami |
| **Utility** | 2-4 | None | Control | Shield, Slow |

### Rules

- **Heavy spells never spammable** (cost ≥ 50% max mana)
- **Utility spells always situationally strong** (clear counter-play)
- **Basic spells always castable** (cost ≤ mana regen)

### Element Effectiveness

| Attacker | Strong vs | Weak vs |
|----------|-----------|---------|
| Fire 🔥 | Earth 🌍 | Water 💧 |
| Water 💧 | Fire 🔥 | Air 💨 |
| Air 💨 | Water 💧 | Earth 🌍 |
| Earth 🌍 | Air 💨 | Fire 🔥 |

**Damage Multipliers:**

- Super Effective: ×1.5
- Not Effective: ×0.5
- Neutral: ×1.0

---

## B4. Status Effect Balance

### Burn 🔥

- **Damage:** 2-3 per turn
- **Stacking:** Slow (max 3 stacks)
- **Best against:** High HP enemies (percentage damage)
- **Counter:** Low HP enemies die before burn matters

### Slow 🐌

- **Effect:** Reduces action frequency (-1 action/turn)
- **Damage:** None
- **Best against:** Multi-action enemies
- **Counter:** Single-action enemies unaffected

### Weaken 💔

- **Effect:** % damage reduction (10-20%)
- **Duration:** 2-3 turns
- **Best against:** Early game (flat reduction)
- **Counter:** Late game scales poorly

### Shield 🛡️

- **Effect:** Absorbs X damage before HP
- **Duration:** Until depleted or combat ends
- **Best against:** Predictable burst damage
- **Counter:** DoT bypasses shield

---

## B5. Enemy Design Rules

### Every Enemy Must

1. **Teach one mechanic** (new players learn something)
2. **Punish one mistake** (repeated failure = player error)
3. **Be weak to one strategy** (counter-play exists)

### Enemy Archetypes

| Type | Teaches | Punishes | Weak To |
|------|---------|----------|---------|
| **Brute** | Damage racing | Over-extending | Burn/DoT |
| **Defender** | Patience | Impatience | Status effects |
| **Caster** | Interrupts | Ignoring intent | Burst damage |
| **Swarm** | AoE usage | Single-target focus | AoE spells |

### Gatekeeper Bosses

- **Test:** Composition, not raw damage
- **Require:** Adaptation, not grinding
- **Reward:** Clear progression signal

**Bad Boss Design:**
❌ Requires specific spell to beat
❌ One-shots player without warning
❌ Immune to all status effects

**Good Boss Design:**
✅ Multiple viable strategies
✅ Clear intent telegraphing
✅ Status effects reduce phase difficulty

---

## B6. Run Failure Philosophy

### Player Dies Because

✅ Misunderstood risk (didn't read intent)
✅ Overcommitted resources (spent too much mana)
✅ Ignored signals (didn't react to enemy pattern)

### Player NEVER Dies Because

❌ Random unavoidable spike (no counterplay)
❌ Hidden mechanic (first-time death is unfair)
❌ UI ambiguity (didn't understand turn order)

### The "Fair Death" Test

After every death, the player should be able to say:
> "I could have avoided that if I had done X differently."

If they can't identify X, the death is unfair.

---

## Implementation Checklist

### Spell Review

- [ ] Verify all spells fit the cost/effect matrix
- [ ] Ensure no spell is always-cast
- [ ] Verify element effectiveness works both ways

### Enemy Review

- [ ] Each enemy teaches a mechanic
- [ ] Each enemy has a clear weakness
- [ ] Damage-per-turn matches B2 formula

### Telemetry Monitoring

Track these metrics to validate balance:

- **Turns per battle:** Target 3-6
- **Spell usage frequency:** No spell > 40% of casts
- **Death causes:** Distributed, not clustered on one enemy

---

## Balance Tuning Process

1. **Collect telemetry** (spell usage, turns, deaths)
2. **Identify outliers** (overused spells, unfair deaths)
3. **Adjust one variable** (damage, cost, or duration)
4. **Re-test with fresh runs**
5. **Repeat until metrics normalize**

**Never change multiple variables at once.**

---

## Quick Reference

```
Mana Economy:
  Start: 8 mana
  Regen: 1-2/turn
  Cost range: 1-6
  
Combat Duration:
  Target: 3-6 turns
  Player HP: 50 + 10/level
  Enemy DPS: 15-25% of player HP
  
Status Effects:
  Burn: 2-3 dmg/turn
  Slow: -1 action
  Weaken: -15% damage
  Shield: absorb X damage
```
