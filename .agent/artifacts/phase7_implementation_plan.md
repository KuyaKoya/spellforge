# Phase 7: Hardening, Clarity & Balance — Implementation Plan

## Mission Statement
>
> Phase 7 exists to make Spellforge readable, fair, and extensible without expanding content.
> If Phase 5 proved the game works, Phase 7 proves it can scale.

---

## Current State Analysis

### Already Implemented ✅

- **Status Effects**: `EffectType` enum with burn, slow, weaken, armor, actionGain, delay
- **Floating Damage**: Basic `FloatingDamageController` with red damage and gray status text
- **Enemy Intent**: `EnemyIntent` enum (attack, defend, debuff) — currently shows exact intent
- **Interactable Components**: `InteractableComponent` base with `GlowEffect` mixin for visual affordances
- **Combat System**: `CombatSystem` with phases, spell casting, turn management
- **Pokemon-style Status Bars**: `PokemonEnemyStatusPanel` and `PokemonPlayerStatusPanel`

### Needs Implementation 🔧

1. **A1.1** - Interaction Affordances (first-interaction tracking)
2. **A1.2** - Turn Ownership Indicator Banner
3. **A2.1** - Enhanced Damage Feedback (type-colored, directional)
4. **A2.2** - Status Effect Icons (visible icons with stack counts)
5. **A2.3** - Vague Enemy Intent (category descriptions, not exact)
6. **A3.1** - Turn Locking (disable inputs during enemy turn/animations)
7. **A3.2** - Combat State Guards (validation checks)
8. **A4.1** - State Ownership Model (documented, enforced boundaries)
9. **A4.2** - Flame vs Flutter Boundary (already mostly enforced)
10. **A5** - Telemetry Hooks (local JSON logging)
11. **B1-B6** - Balance Framework (constants, scalers, documentation)

---

## Implementation Roadmap

### Phase 7.1: UX Clarity Pass (A1)

#### 7.1.1: Interaction Affordances Enhancement

**Files to modify:**

- `lib/game/exploration/components/interactable_component.dart`
- `lib/game/exploration/components/enemy_interactable.dart`
- `lib/game/exploration/components/door_interactable.dart`
- `lib/game/exploration/exploration_controller.dart` (track first interactions)

**Implementation:**

1. Add `hasBeenInteractedOnce` tracking per interactable type per run
2. Add visual indicators:
   - Enemy: Pulsing outline (already has `GlowEffect`, enhance it)
   - Door: Directional arrow icon floating above
   - Shop/Event: Icon floating above anchor

**Acceptance:** All interactables visually distinguishable in <3 seconds

#### 7.1.2: Turn Ownership Indicator

**Files to create:**

- `lib/ui/battle/turn_banner.dart`

**Files to modify:**

- `lib/ui/battle/battle_screen.dart`

**Implementation:**

1. Create `TurnBanner` widget with animated slide/fade
2. Color-coded: Player = calm blue/green, Enemy = warning red/orange
3. Position above action panel

**Acceptance:** Zero ambiguity about turn flow

---

### Phase 7.2: Combat Readability Pass (A2)

#### 7.2.1: Enhanced Damage Feedback

**Files to modify:**

- `lib/ui/battle/floating_damage.dart`

**Implementation:**

1. Add damage type enum: `DamageType { direct, burn, healing, shield }`
2. Color mapping:
   - Damage: red/orange (based on source element)
   - Burn/DoT: darker red, smaller font
   - Healing: green
   - Shield absorb: blue/gray
3. Add directional movement based on source

**Acceptance:** Every HP change produces appropriately colored floating number

#### 7.2.2: Status Effect Icons

**Files to create:**

- `lib/ui/battle/status_icons.dart`

**Files to modify:**

- `lib/ui/battle/status_bars.dart` (add icons under enemy HP, next to player panel)

**Implementation:**

1. Create `StatusIcon` widget with:
   - Icon for effect type (🔥 Burn, 🐌 Slow, 💔 Weaken, 🛡️ Shield)
   - Stack count badge
   - Duration indicator (optional)
2. Position under enemy HP bars
3. Position next to player status panel

**Acceptance:** All buffs/debuffs visible with stack counts

#### 7.2.3: Vague Enemy Intent

**Files to modify:**

- `lib/domain/enemy.dart` (add `getVagueIntentText()`)
- `lib/ui/battle/battle_screen.dart` (use vague text in dialog)

**Implementation:**

1. Map intent to vague descriptions:
   - attack → "Preparing a heavy attack" / "Gathering energy"
   - defend → "Defensive stance" / "Bracing for impact"
   - debuff → "Dark energy swirls..." / "Preparing a curse"
2. Remove exact intent display from battle dialog

**Acceptance:** Strategic planning enabled without revealing exact moves

---

### Phase 7.3: State Consistency & Safety (A3)

#### 7.3.1: Turn Locking

**Files to modify:**

- `lib/ui/battle/battle_screen.dart`
- `lib/ui/battle/battle_action_menu.dart`

**Implementation:**

1. Add `_isInputLocked` state flag
2. During enemy turn: all player buttons disabled
3. During animations: no state mutation allowed
4. Add visual feedback (button opacity, loading indicator)

**Acceptance:** No spurious inputs during enemy/animation phases

#### 7.3.2: Combat State Guards

**Files to create:**

- `lib/systems/combat_guards.dart`

**Files to modify:**

- `lib/systems/combat_system.dart`
- `lib/domain/mage.dart`
- `lib/domain/enemy.dart`

**Implementation:**

1. Guard functions:
   - `validateHP(int hp, int max)` - clamp to [0, max]
   - `validateMP(int mp, int max)` - clamp to [0, max]
   - `canCastSpell(Mage mage, Spell spell)` - verify resources
   - `canEnemyAct(Enemy enemy)` - verify alive
2. Failing guards:
   - Log error with context
   - Return safe default / skip action
   - Never crash combat

**Acceptance:** Combat never crashes from invalid state

---

### Phase 7.4: Internal Architecture Stabilization (A4)

#### 7.4.1: State Ownership Model Documentation

**Files to create:**

- `lib/core/state_model.dart` (type definitions for state ownership)
- Update `README.md` or create `docs/architecture.md`

**Implementation:**

1. Document state hierarchy:

   ```
   RunState
   ├── MetaProgressionState (persistent)
   ├── ExplorationState (room-scoped)
   └── CombatState (battle-scoped)
   ```

2. Add JSDoc comments to existing state classes
3. UI components marked as observers (no direct mutation)

**Acceptance:** Clear separation documented and enforced

#### 7.4.2: Flame vs Flutter Boundary

**Already enforced.** Document and add assertions if needed.

---

### Phase 7.5: Telemetry Hooks (A5)

**Files to create:**

- `lib/systems/telemetry.dart`

**Implementation:**

1. Metrics to capture:
   - Turns per battle
   - Damage taken per fight
   - Spell usage frequency
   - Death cause (enemy / burn / misplay)
2. Storage: JSON file in app data directory
3. Optional: Console logging during debug

**Acceptance:** Run analytics available for balance tuning

---

### Phase 7.6: Balance Framework (B1-B6)

**Files to create:**

- `lib/data/balance_constants.dart`
- `lib/docs/balance_guide.md`

**Implementation:**

#### Balance Constants File

```dart
/// B2: Base Stat Curves
class BalanceConstants {
  // Player leveling
  static const int playerHPPerLevel = 10; // midpoint of 8-12
  static const int playerMPPerLevel = 2;  // midpoint of 2-3
  
  // Enemy scaling (Act 1)
  static const double enemyHPRatio = 1.0; // × player HP
  static const double enemyDamageRatio = 0.20; // × player HP per turn
  
  // B3: Spell Cost Matrix
  static const Map<String, SpellCostTier> spellTiers = {
    'basic': SpellCostTier(manaCost: 1, damageBase: 8),
    'core': SpellCostTier(manaCost: 3, damageBase: 18),
    'heavy': SpellCostTier(manaCost: 5, damageBase: 30),
    'utility': SpellCostTier(manaCost: 3, damageBase: 0),
  };
  
  // B4: Status Effect Balance
  static const int burnDamagePerTurn = 2;
  static const int slowActionReduction = 1;
  static const int weakenPercent = 25;
}
```

#### Balance Guide Document

Document the principles:

1. No Perfect Spell - every spell has trade-offs
2. Mana Is Strategic - tight early, flexible mid-fight
3. Predictable Damage - variance from effects/behavior, not RNG
4. Enemy Design Rules - teach mechanic, punish mistake, weak to strategy
5. Run Failure Philosophy - player fault, not random spikes

---

## File Summary

### New Files

1. `lib/ui/battle/turn_banner.dart` - Turn ownership indicator
2. `lib/ui/battle/status_icons.dart` - Status effect icon widgets
3. `lib/systems/combat_guards.dart` - Combat validation functions
4. `lib/systems/telemetry.dart` - Local analytics logging
5. `lib/data/balance_constants.dart` - Balance framework values
6. `docs/balance_guide.md` - Balance philosophy documentation
7. `docs/architecture.md` - State ownership documentation

### Modified Files

1. `lib/ui/battle/floating_damage.dart` - Enhanced damage types/colors
2. `lib/ui/battle/status_bars.dart` - Add status icons
3. `lib/ui/battle/battle_screen.dart` - Turn banner, input locking, vague intent
4. `lib/ui/battle/battle_action_menu.dart` - Input locking states
5. `lib/domain/enemy.dart` - Vague intent method
6. `lib/domain/mage.dart` - Guard validations
7. `lib/systems/combat_system.dart` - Guards, telemetry hooks
8. `lib/game/exploration/components/interactable_component.dart` - Enhanced affordances
9. `lib/game/exploration/exploration_controller.dart` - First-interaction tracking

---

## Success Metrics

Phase 7 is complete when:

- ✅ You can explain combat without words (visual clarity)
- ✅ You can add a new spell without fear (balance framework)
- ✅ You can add a new enemy in <30 minutes (extensibility)
- ✅ Players die and say "That was my fault" (fair failure)

---

## Implementation Order

1. **A3: State Safety** (foundation - prevent crashes)
2. **A2.1: Damage Feedback** (most visible improvement)
3. **A2.2: Status Icons** (readability)
4. **A1.2: Turn Banner** (clarity)
5. **A2.3: Vague Intent** (strategy)
6. **A3.1: Turn Locking** (polish)
7. **A1.1: Affordances** (exploration)
8. **B1-B6: Balance Framework** (documentation + constants)
9. **A5: Telemetry** (analytics)
10. **A4: Documentation** (finalize)
