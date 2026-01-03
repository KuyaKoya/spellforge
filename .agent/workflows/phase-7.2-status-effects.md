---
description: Phase 7.2 - Status Effect System Implementation
---

# Phase 7.2 — STATUS EFFECT SYSTEM

## Overview

Implement a deterministic, extensible status effect system that integrates cleanly
into the turn-based combat loop and is visible, fair, and predictable.

**Status: ✅ COMPLETE**

## Implementation Tasks

### PART A — STATUS EFFECT MODEL

#### A1. Status Effect Core Interface ✅

- [x] Create `StatusEffect` class with required fields:
  - id, name, type (Buff/Debuff), duration, stacks, maxStacks, source
- [x] Lifecycle hooks: onApply(), onTurnStart(), onTurnEnd(), onExpire()
- [x] No direct UI mutation - all effects mutate CombatState only

#### Files Created

- `lib/domain/status_effect.dart` - Core StatusEffect class with factories
- `lib/domain/status_effect_manager.dart` - Lifecycle management

### PART B — TURN ORDER INTEGRATION

#### B1. Turn Phase Breakdown ✅

- [x] Phase 1: Turn Start Effects (burn damage, regen healing)
- [x] Phase 2: Action Phase (damage modifiers)
- [x] Phase 3: Turn End Effects (duration tick)
- [x] Phase 4: Cleanup / Expiration

#### Files Modified

- `lib/domain/mage.dart` - Added StatusEffectManager, processTurnStartEffects()
- `lib/domain/enemy.dart` - Added StatusEffectManager, processTurnStartEffects()

### PART C — CORE STATUS EFFECTS

#### C1. BURN ✅

- [x] Trigger: Start of affected character's turn
- [x] Damage Type: Fire (ignores shields)
- [x] Stackable: Yes (max 3 stacks)
- [x] damagePerStack: 2-3
- [x] Factory: `StatusEffect.burn()`

#### C2. SLOW ✅

- [x] Trigger: Turn order calculation
- [x] Stackable: No (binary effect)
- [x] priorityModifier: -1
- [x] Factory: `StatusEffect.slow()`

#### C3. SHIELD ✅

- [x] Trigger: On damage taken
- [x] Stackable: Yes (numeric additive)
- [x] Absorbs damage first, then expires when depleted
- [x] Does NOT reduce status damage (burn, poison)
- [x] Factory: `StatusEffect.shield()`

### PART D — OPTIONAL STATUS EFFECTS

#### Implemented

- [x] WEAKEN - Reduces outgoing damage by %
- [x] REGEN - Heals at turn end

#### Reserved for future

- [ ] VULNERABLE - Increases incoming damage
- [ ] POISON - Similar to burn but different element

### PART E — STATUS STACKING RULES ✅

| Effect | Stack Type | Implementation |
|--------|------------|----------------|
| Burn | Intensity + Duration | addStacks() + refreshDuration() |
| Slow | No stacking | refreshDuration() only |
| Shield | Numeric additive | value += newValue |
| Weaken | Duration only | refreshDuration() only |

### PART F — COMBAT UI REQUIREMENTS ✅

- [x] Status effect icons in `status_effect_icons.dart`
- [x] Stack count overlay
- [x] Duration display
- [x] Tooltip on long-press (name, effect, duration)
- [x] Enemy placement: under HP bar
- [x] Player placement: near status panel

### PART G — SPELL INTEGRATION

- [x] Spells can apply StatusEffect via `applyNewStatusEffect()`
- [ ] Update spell definitions to use new format (optional, legacy still works)

## Created Files

1. `lib/domain/status_effect.dart`
   - StatusEffectCategory enum
   - StatusPhase enum
   - StatusSource enum
   - StatusEffectType enum (with icons, categories, phases)
   - StatusEffect class (with factories for Burn, Slow, Shield, Weaken, Regen)
   - TurnEffectResult class
   - DamageAbsorption class

2. `lib/domain/status_effect_manager.dart`
   - StatusEffectManager class
   - Turn phase lifecycle methods
   - Stacking rule enforcement
   - TurnStartResult class

## Modified Files

1. `lib/domain/mage.dart`
   - Added StatusEffectManager
   - Updated takeDamage() for shield absorption
   - Added takeBurnDamage() (ignores shields)
   - Added processTurnStartEffects(), processTurnEndEffects()
   - Added applyNewStatusEffect()

2. `lib/domain/enemy.dart`
   - Added StatusEffectManager
   - Updated takeDamage() for shield absorption
   - Added takeBurnDamage() (ignores shields)
   - Added applyNewStatusEffect()
   - Updated processStatusEffects() for new system

## Acceptance Criteria

- [x] Burn ticks reliably every turn start
- [x] Slow consistently affects turn order (priorityModifier)
- [x] Shields absorb damage correctly (before HP reduction)
- [x] Status icons display accurately (existing UI works)
- [x] No status persists past intended duration
- [x] Combat behavior matches player expectations

## Common Pitfalls Avoided

- ✅ Status damage applied at turn START, not action phase
- ✅ UI does not drive effect logic
- ✅ Duration clamped to never go negative
- ✅ Shield values clamped appropriately

## Testing

// turbo-all

1. Run `dart analyze lib/domain/status_effect.dart lib/domain/status_effect_manager.dart`
2. Run `dart analyze lib/domain/mage.dart lib/domain/enemy.dart`
3. Test in game:
   - Cast a burn spell, verify damage at turn start
   - Apply shield, verify damage absorption
   - Check status icons display correctly
