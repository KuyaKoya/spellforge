---
description: Phase X - Room-Based Exploration Flow Implementation
---

# PHASE X: ROOM-BASED EXPLORATION OVERHAUL

## Overview

Replace text/node flow with room-based, sprite-driven exploration inspired by Dicey Elementalist.

## Core Principles

- Combat is NEVER automatic
- All transitions require explicit player confirmation
- UI is mostly icon-driven
- Director reacts contextually
- Old systems function inside new flow

---

## IMPLEMENTATION PHASES

### Phase X.1: Interactable Component System

1. Create base `InteractableComponent` class
   - Properties: type, triggerRadius, previewData, interactionState
   - States: idle → preview → confirmed
   - Abstract methods: onApproach(), onConfirm(), onCancel()

2. Implement specific interactables:
   - `EnemyInteractable`: Shows enemy preview, confirms to combat
   - `DoorInteractable`: Shows destination, confirms to navigate
   - `ShopInteractable`: Shows shopkeeper preview
   - `EventInteractable`: Shows event tone preview
   - `ShrineInteractable`: Shows enhancement options

### Phase X.2: Preview Panel System

1. Create unified `PreviewPanel` base widget
   - Title, Icon(s), Key Stats
   - Risk Hint (optional)
   - Director Line (optional)
   - Confirm/Cancel buttons

2. Specialized preview panels:
   - `EnemyPreviewPanel`: Name, Element, HP/MP bars, Passive Traits, Elite indicator
   - `DoorPreviewPanel`: Destination type, Locked state, Breadcrumb hint
   - `ShopPreviewPanel`: Shopkeeper icon, Item count, Currency
   - `EventPreviewPanel`: Title, Tone indicator, Director reaction

### Phase X.3: Game Flow Integration

1. Modify `GameState.enterCurrentNode()`:
   - For combat nodes: Enter exploration first, NOT direct combat
   - Combat starts only via EnemyPreviewPanel confirm

2. Create `ExplorationController`:
   - Manages room state
   - Handles interactable callbacks
   - Triggers world transitions

3. Update `GameLoop`:
   - Add exploration → combat transition
   - Add room → room navigation
   - Preserve combat rewards flow

### Phase X.4: Exploration HUD

1. Compact status display:
   - HP/Mana bars (bottom)
   - Spell icons (4 slots)
   - Director indicator (idle animation)

2. Breadcrumb bar (top):
   - Already implemented in NodeBreadcrumbs
   - Shows room progress

### Phase X.5: Director Integration

1. Director event triggers:
   - onEnterRoom(roomType)
   - onApproachEnemy(enemy, retreated: bool)
   - onAvoidEnemy(count)
   - onEliteEncounter(elite)
   - onLowHPDecision(hpPercent)
   - onRunRepetition(runNumber)

2. Director output:
   - Short text line (subtitle overlay)
   - Icon animation (optional)
   - Silence (intentional for certain moments)

---

## FILE STRUCTURE

```
lib/game/exploration/
├── components/
│   ├── interactable_component.dart
│   ├── enemy_interactable.dart
│   ├── door_interactable.dart
│   ├── shop_interactable.dart
│   ├── event_interactable.dart
│   └── shrine_interactable.dart
├── exploration_controller.dart
└── room_generator.dart

lib/ui/exploration/
├── preview_panels/
│   ├── preview_panel.dart
│   ├── enemy_preview_panel.dart
│   ├── door_preview_panel.dart
│   ├── shop_preview_panel.dart
│   └── event_preview_panel.dart
├── exploration_hud.dart
├── exploration_screen.dart (enhanced)
├── exploration_room_world.dart (enhanced)
└── room_components.dart (enhanced)
```

---

## MIGRATION NOTES

### Old → New Mapping

| Old System | New System |
|------------|------------|
| Node | Room |
| Node Type | Room Metadata |
| Text Choice | Physical Interaction |
| Auto Combat | Confirmed Combat |
| Node Map | Breadcrumb Bar |

### Text Events → Event Rooms

- Event text becomes Preview + Modal
- Outcomes unchanged
- Director lines preserved

### Old Battle Trigger → Enemy Interactable

- Same enemy data
- New entry point (EnemyPreviewPanel)
- Same combat resolution

---

## ACCEPTANCE CRITERIA

Phase is complete when:

- [ ] Player physically moves in rooms
- [ ] No combat starts without confirmation
- [ ] Enemy stats are visible before battle
- [ ] UI is mostly icon-driven
- [ ] Spell inspection works via interaction
- [ ] Director reacts contextually
- [ ] Old systems function inside new flow

---

## COMMANDS

// turbo-all

```bash
# Run the app
flutter run -d windows
```

```bash
# Run tests
flutter test
```

```bash
# Analyze code
flutter analyze
```
