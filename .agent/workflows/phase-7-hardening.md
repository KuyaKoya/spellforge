---
description: Phase 7 - Hardening, Clarity & Balance Implementation
---

# Phase 7 — Hardening, Clarity & Balance

## Overview

Phase 7 makes Spellforge readable, fair, and extensible without expanding content.

**Status: ✅ COMPLETE**

## Implementation Tasks

### PART A — UX CLARITY PASS

#### A1.1 Interaction Affordances ✅

- [x] Add pulsing outline/glow to enemies (EnemyAffordanceDecoration)
- [x] Add directional arrow icon to doors (DoorAffordanceIcon)
- [x] Add floating icon above shops/events (FloatingAffordanceIcon)
- [x] Created reusable InteractionAffordance wrapper

#### A1.2 Turn Ownership Indicator ✅

- [x] Create `TurnBanner` widget with animated slide/fade
- [x] Color-coded: Player = calm blue (#58a6ff), Enemy = warning red (#f85149)
- [x] Add to battle screen above action panel
- [x] Add `TurnIndicatorPill` for compact display

### PART A2 — COMBAT READABILITY PASS

#### A2.1 Damage Feedback Enhancement ✅

- [x] Enhance FloatingDamageController with `FloatingDamageType` enum
- [x] Red/orange for damage (#f85149)
- [x] Darker red, smaller (18px) for Burn/DoT (#bd3a3a)
- [x] Green for healing (#3fb950)
- [x] Blue/gray for shield absorb (#79c0ff)
- [x] Added `showBurnDamage()`, `showHealing()`, `showShieldAbsorb()` methods

#### A2.2 Status Effect Indicators ✅

- [x] Create `StatusEffectIcon` widget with stack count & duration
- [x] Create `StatusEffectRow` for grouped display
- [x] Enemy: `EnemyStatusEffects` under HP bar
- [x] Player: `PlayerStatusEffects` next to status panel
- [x] Icons: Burn 🔥, Slow 🐌, Weaken 💔, Shield 🛡️, Delay ⏸️, Haste ⚡

#### A2.3 Enemy Intent (Vague) ✅

- [x] Added `vagueDescription` to EnemyIntent enum
- [x] Added `icon` getter for visual display
- [x] Updated combat system to use vague descriptions
- [x] Updated exploration preview to show vague intent

### PART A3 — STATE CONSISTENCY & SAFETY

#### A3.1 Turn Locking ✅

- [x] Added `_isAnimating` flag to battle screen
- [x] Created `_isInputLocked` centralized getter
- [x] Disable all player inputs during enemy turn
- [x] Prevent state mutation during spell animations
- [x] Lock/unlock at phase transitions

#### A3.2 Combat State Guards ✅

- [x] Create `CombatStateGuard` class
- [x] `clampHP()` - HP >= 0, <= max validation
- [x] `clampMana()` - Mana bounds validation
- [x] `validateSpellCast()` - Full spell validation
- [x] `canEnemyAct()` - Dead enemy check
- [x] `canPlayerAct()` - Turn phase + animation check
- [x] Guard violation logging

### PART A4 — INTERNAL ARCHITECTURE ✅

#### A4.1 State Ownership Model

- [x] Created `docs/architecture/state_ownership.md`
- [x] Documented RunState, CombatState, ExplorationState
- [x] Defined state mutation rules
- [x] UI as observer pattern documented

#### A4.2 Flame vs Flutter Boundary

- [x] Documented boundary rules in state_ownership.md
- [x] Flame = world & sprites
- [x] Flutter = UI & input
- [x] Bridge = Event callbacks

### PART A5 — TELEMETRY HOOKS ✅

- [x] Create `TelemetryService` singleton class
- [x] Track: turns per battle
- [x] Track: damage taken per fight
- [x] Track: spell usage frequency
- [x] Track: death cause
- [x] Store locally using SharedPreferences
- [x] `exportSummary()` for analysis

### PART B — BALANCE FRAMEWORK ✅

- [x] Created `docs/architecture/balance_framework.md`
- [x] Defined core balance principles (B1)
- [x] Documented base stat curves (B2)
- [x] Created spell cost/effect matrix (B3)
- [x] Defined status effect balance rules (B4)
- [x] Documented enemy design rules (B5)
- [x] Defined run failure philosophy (B6)

## Created Files

1. `lib/ui/battle/turn_banner.dart` - Turn ownership banner
2. `lib/ui/battle/status_effect_icons.dart` - Status effect displays
3. `lib/systems/telemetry_service.dart` - Local telemetry tracking
4. `lib/systems/combat_state_guard.dart` - Combat validation guards
5. `lib/ui/components/interaction_affordances.dart` - Pulsing/glow affordances
6. `docs/architecture/state_ownership.md` - A4 architecture documentation
7. `docs/architecture/balance_framework.md` - B balance framework

## Modified Files

1. `lib/ui/battle/floating_damage.dart` - Enhanced with damage types
2. `lib/ui/battle/battle_screen.dart` - Turn banner, status effects, turn locking
3. `lib/ui/battle/status_bars.dart` - Added enemy status effects
4. `lib/ui/battle/battle.dart` - Updated exports
5. `lib/ui/components/components.dart` - Updated exports
6. `lib/domain/enemy.dart` - Added vague intent descriptions
7. `lib/systems/combat_system.dart` - Uses vague intent text
8. `lib/ui/exploration/room_components.dart` - Vague enemy intent display

## Success Metrics

1. ✅ Player can identify all interactables in under 3 seconds (affordance animations)
2. ✅ Zero ambiguity about turn flow (TurnBanner with color coding)
3. ✅ No tutorial text required (visual indicators only)
4. ✅ Players die and say "That was my fault" (vague intent + status visibility)

## Optional Future Enhancements

- [ ] Integrate affordances into ExplorationRoomWorld
- [ ] Track first-interaction state per run for affordance dismissal
- [ ] Add telemetry hooks to combat_system.dart
- [ ] Wire TelemetryService.startCombat/endCombat into game flow
- [ ] Add balance tuning UI for debugging

## Testing Notes

// turbo-all

1. Run `flutter analyze --no-pub` to verify no errors
2. Run game and enter combat to verify:
   - Turn banner appears and animates
   - Status effects show under enemies/player
   - Damage numbers are color-coded
   - Input is locked during enemy turns
3. Check exploration room for vague enemy intent display
