---
description: Phase 7.8 - Character Tab, Crystal Progression, and Elemental Node Paths Implementation
---

# Phase 7.8 Implementation Plan

## Overview

This phase introduces a permanent meta-progression system for SpellForge that uses Crystals as a long-term currency and allows players to specialize in one or more elemental paths with meaningful tradeoffs.

## Core Components

### 1. Data Models (`lib/progression/`)

#### 1.1 Create `character_progress.dart`

File: `lib/progression/character_progress.dart`

```dart
// CharacterProgress - Persistent meta-progression for elemental nodes
// - int crystals (accessed from ProgressionSystem)
// - Map<Element, int> unlockedNodes (Fire: 0-10, Water: 0-10, etc.)
// - Methods: unlockNextNode(Element), getCost(Element, nodeIndex), getUnlockedModifiers()
```

#### 1.2 Create `elemental_node.dart`

File: `lib/progression/elemental_node.dart`

```dart
// ElementalNode - Individual node definition
// - int tier (1-3)
// - int index (0-9)
// - int cost (Crystal cost)
// - String effect (benefit description)
// - String tradeoff (penalty description)
// - NodeModifier modifier (actual game effect)
```

#### 1.3 Create `elemental_path.dart`  

File: `lib/progression/elemental_path.dart`

```dart
// ElementalPath - Path definitions for each element
// - Element element
// - List<ElementalNode> nodes (10 per element)
// - String theme
// - Getters for unlocked/locked nodes
```

#### 1.4 Create `node_modifier.dart`

File: `lib/progression/node_modifier.dart`

```dart
// NodeModifier - Affects combat stats
// - ModifierType type (damageBonus, maxHPBonus, armorBonus, manaCost, etc.)
// - Element? targetElement (null = all elements)
// - int value (percentage or flat bonus)
// - bool isPositive (benefit or tradeoff)

// enum ModifierType { damagePercent, maxHPPercent, armorFlat, manaCostFlat, 
//   burnDuration, healingPercent, speedPercent, critChance, drawCards, etc. }
```

---

### 2. Node Definitions (`lib/data/`)

#### 2.1 Create `elemental_paths_data.dart`

File: `lib/data/elemental_paths_data.dart`

Defines all 40 nodes (10 per element) with:

- Fire Path: Destruction & Risk theme
- Water Path: Control & Endurance theme  
- Earth Path: Fortification & Attrition theme
- Wind Path: Speed & Precision theme

Cost scaling:

- Tier 1 (Nodes 1-3): 10, 15, 20 crystals
- Tier 2 (Nodes 4-6): 30, 40, 50 crystals
- Tier 3 (Nodes 7-10): 75, 90, 105, 120 crystals

---

### 3. Integration with Existing Systems

#### 3.1 Update `ProgressionSystem`

File: `lib/systems/progression_system.dart`

- Add `CharacterProgress characterProgress`
- Load/save character progress with SharedPreferences
- Expose methods: `unlockNode()`, `getActiveModifiers()`

#### 3.2 Update `Mage` class

File: `lib/domain/mage.dart`

- Add optional `List<NodeModifier> elementalModifiers`
- Apply modifiers in damage calculation, healing, etc.
- Constructor accepts modifiers from CharacterProgress

#### 3.3 Update `GameState`

File: `lib/game/game_state.dart`

- When starting a run, apply active elemental modifiers to the mage

---

### 4. UI Implementation (`lib/ui/`)

#### 4.1 Create `character_tab.dart`

File: `lib/ui/exploration/overlays/character_tab.dart`

Layout:

```
[ Character Tab Header ]
Crystals: XXXX ✨

═══════════════════════════
   ELEMENTAL ASCENSION
═══════════════════════════

        [ 🌟 Core ] (info node)
      /    |    |    \
   🔥    💧    🪨    💨
   Fire  Water Earth Wind
   [3]   [0]   [1]   [0]   <- unlocked count

(Tap an element to expand its path)
```

#### 4.2 Create `elemental_path_view.dart`

File: `lib/ui/exploration/overlays/elemental_path_view.dart`

Shows:

- Vertical path of 10 nodes
- Unlocked nodes: colored, glowing
- Locked but available: dimmed, shows cost
- Locked (prerequisite not met): greyed out
- Node preview on tap
- Confirm purchase on hold/double-tap

#### 4.3 Create `node_preview_dialog.dart`

File: `lib/ui/exploration/overlays/node_preview_dialog.dart`

Shows:

- Node name and tier
- Effect (benefit)
- Tradeoff (penalty)
- Cost
- Purchase/Cancel buttons

---

### 5. Enable Character Tab in Main Menu

#### 5.1 Update `main_menu_overlay.dart`

File: `lib/ui/exploration/overlays/main_menu_overlay.dart`

- Remove "coming soon" snackbar for Character tab
- Add case for `_selectedIndex == 0` to show `CharacterTab`
- Pass `progressionSystem` to `CharacterTab`

---

### 6. Persistence

#### 6.1 SharedPreferences Keys

- `character_fire_nodes`: int (0-10)
- `character_water_nodes`: int (0-10)
- `character_earth_nodes`: int (0-10)  
- `character_air_nodes`: int (0-10)

---

## Implementation Order

### Step 1: Core Data Models

1. Create `lib/progression/node_modifier.dart`
2. Create `lib/progression/elemental_node.dart`
3. Create `lib/progression/elemental_path.dart`
4. Create `lib/progression/character_progress.dart`

### Step 2: Node Data Definitions

1. Create `lib/data/elemental_paths_data.dart` with all 40 nodes

### Step 3: System Integration

1. Update `lib/systems/progression_system.dart` to load/save character progress
2. Update `lib/domain/mage.dart` to apply modifiers
3. Update `lib/game/game_state.dart` to pass modifiers on run start

### Step 4: UI Components

1. Create `lib/ui/exploration/overlays/node_preview_dialog.dart`
2. Create `lib/ui/exploration/overlays/elemental_path_view.dart`
3. Create `lib/ui/exploration/overlays/character_tab.dart`

### Step 5: Main Menu Integration

1. Update `lib/ui/exploration/overlays/main_menu_overlay.dart` to enable Character tab

### Step 6: Testing & Polish

1. Run the app and test node unlocking
2. Test that modifiers apply correctly in combat
3. Verify persistence across app restarts

---

## Acceptance Criteria

- [x] Character tab accessible from home (index 0 in bottom nav)
- [x] Crystals displayed and deducted correctly
- [x] Node unlocks persist between runs
- [x] Effects apply immediately to future runs (fully integrated)
- [x] UI supports expansion beyond 10 nodes (scrollable)
- [x] Each element has 10 nodes with correct costs
- [x] Tradeoffs are visible alongside benefits
- [x] Path themes are clearly communicated

---

## Technical Notes

### Modifier Application Points

1. **Damage Calculation**: In combat resolution, check for `damagePercent` modifiers
2. **Mana Cost**: In spell cast validation, apply `manaCostFlat` modifiers
3. **Max HP**: On mage creation, apply `maxHPPercent` modifiers
4. **Armor**: On battle start, apply `armorFlat` modifiers
5. **Burn Duration**: In effect application, modify duration
6. **Healing**: In heal() method, apply `healingPercent` modifiers

### UI Color Scheme

- Fire: `Colors.orange` (#FF9800)
- Water: `Colors.blue` (#2196F3)  
- Earth: `Colors.brown` (#795548)
- Wind: `Colors.teal` (#009688)
- Locked: `Colors.grey.shade700`
- Crystal: `Colors.amber` (✨)

### Animation Ideas (Nice to Have)

- Pulse animation on available nodes
- Glow effect on unlocked path
- Particle effect on node purchase
- Smooth scroll to unlocked position
