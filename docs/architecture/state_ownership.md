# Spellforge Architecture — State Ownership Model

## A4.1 State Ownership Boundaries

### Core Principle

**UI must observe state and never mutate directly.**

State changes flow through dedicated systems (CombatSystem, GameState) which validate
and apply mutations. UI widgets receive read-only snapshots and trigger actions via callbacks.

---

## State Categories

### 1. RunState (GameState)

**Owner:** `lib/game/game_state.dart`
**Scope:** Single run lifecycle (start → death/victory)
**Contains:**

- Current screen (`GameScreen` enum)
- Current mage (player character)
- Current combat system reference
- Current enemies list
- Exploration state (current room, visited nodes)
- Run statistics (turns, damage taken)
- Temporary buffs

**Mutators:**

- `startRun()` - Initialize new run
- `enterCurrentNode()` - Transition to new node
- `startCombatDirectly()` - Begin combat
- `completeNode()` - Mark node as completed

**UI Access:** Read-only via widget props. Never call mutators directly from build().

---

### 2. CombatState (CombatSystem)

**Owner:** `lib/systems/combat_system.dart`
**Scope:** Single combat encounter
**Contains:**

- Combat phase (`CombatPhase` enum)
- Mage reference
- Enemies list with HP/status
- Combat log
- Turn counter

**Mutators:**

- `startCombat()` - Initialize encounter
- `castSpell()` - Execute player spell
- `endPlayerTurn()` - Process end-of-turn effects
- Internal: `_executeEnemyTurn()`, `_resolveStatusEffects()`

**Invariants (A3.2 Guards):**

- HP cannot go below 0
- Mana cannot exceed max
- Dead enemies cannot act
- Spells cannot cast without resources

---

### 3. ExplorationState

**Owner:** `lib/game/game_state.dart` (via currentNode, visitedNodes)
**Scope:** Room-based exploration within a run
**Contains:**

- Current room layout (doors, enemy presence)
- Player position in room
- Interacted objects this room

**Flame Components:**

- `ExplorationRoomWorld` renders the 2D room
- Player component handles movement input

**Flutter Overlays:**

- Door confirmation panels
- Enemy preview panels
- Interaction prompts

---

### 4. MetaProgressionState

**Owner:** `lib/game/game_state.dart` (persistent via SharedPreferences)
**Scope:** Cross-run unlocks and stats
**Contains:**

- Total runs completed
- Best depth reached
- Unlocked spells/mages
- Achievement flags

---

## A4.2 Flame vs Flutter Boundary

### Rule: Flame handles world & sprites. Flutter handles UI & input

| Layer | Responsibility | Examples |
|-------|----------------|----------|
| **Flame** | Visual world rendering | Room tiles, enemy sprites, player movement |
| **Flutter** | Decisions & information | Action menus, status bars, dialog boxes |
| **Bridge** | Event callbacks | `onInteract`, `onDamageDealt`, `onCombatEnd` |

### Boundary Enforcement

**Flame → Flutter:**

```dart
// In BattleScene (Flame)
void onDamageDealt(int index, int damage, bool isPlayer) {
  // Callback to Flutter layer
  _onDamageCallback?.call(index, damage, isPlayer);
}
```

**Flutter → Flame:**

```dart
// In BattleScreen (Flutter)
void _executePlayerSpell(...) {
  _battleScene.playMageCast(); // Tell Flame to animate
}
```

### Forbidden Patterns

❌ Flame component directly calling `setState()`
❌ Flutter widget directly manipulating game entities
❌ UI reading from component.position during build
❌ Game logic in animation controllers

### Allowed Patterns

✅ Flame emits events via callbacks
✅ Flutter passes actions via dedicated methods
✅ State changes propagate through GameState/CombatSystem
✅ UI rebuilds on notifyListeners/setState

---

## Turn Locking (A3.1)

### Input Lock States

The `_isInputLocked` getter centralizes input blocking:

```dart
bool get _isInputLocked {
  if (_phase == CombatPhase.enemyAction) return true;
  if (_isAnimating) return true;
  if (_phase == CombatPhase.combatEnd) return true;
  if (_phase == CombatPhase.turnTransition) return true;
  return false;
}
```

### Animation Lock Flow

1. Player selects spell → `_isAnimating = true`
2. Spell animation plays → state mutation occurs
3. Animation completes → `_isAnimating = false`
4. UI re-enabled for next action

Same pattern applies to enemy turns.

---

## State Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        GameState                            │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ RunState    │  │ CombatState  │  │ ExplorationState │   │
│  │ (mage, map) │  │ (enemies,hp) │  │ (room, doors)    │   │
│  └──────┬──────┘  └──────┬───────┘  └────────┬─────────┘   │
└─────────┼────────────────┼───────────────────┼─────────────┘
          │                │                   │
          ▼                ▼                   ▼
    ┌─────────────────────────────────────────────────────┐
    │                    UI Layer                          │
    │  ┌────────────┐  ┌────────────┐  ┌───────────────┐  │
    │  │ StatusBars │  │ActionMenu  │  │ Exploration   │  │
    │  │ (read-only)│  │(callbacks) │  │ (read-only)   │  │
    │  └────────────┘  └────────────┘  └───────────────┘  │
    └─────────────────────────────────────────────────────┘
```

---

## File Reference

| File | State Type | Role |
|------|------------|------|
| `game_state.dart` | RunState, ExplorationState | Central orchestrator |
| `combat_system.dart` | CombatState | Combat logic |
| `combat_state_guard.dart` | Validation | State invariants |
| `telemetry_service.dart` | Metrics | Local analytics |
| `battle_screen.dart` | UI State | View orchestration |
