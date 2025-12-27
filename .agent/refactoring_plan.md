# Spellforge Code Cleanup - Refactoring Plan

## Status: Phase 1-5 Complete ✅

Last Updated: 2025-12-27

---

## Completed Refactors

### ✅ Phase 1: Nodes Module

**Status: COMPLETE**

Extracted node logic from `systems/node_map_system.dart` into a dedicated `nodes/` module.

```plaintext
lib/nodes/
├── nodes.dart              # Barrel export
├── node_type.dart          # NodeType enum with display properties
├── map_node.dart           # MapNode class
├── depth_level.dart        # DepthLevel class
├── node_selector.dart      # Node selection/weighting logic
└── node_map_system.dart    # Simplified orchestrator
```

**Benefits:**

- Data-driven node weights and availability
- Clean separation of concerns
- Better testability

---

### ✅ Phase 2: Encounters Module

**Status: COMPLETE**

Separated encounter generation from combat execution.

```plaintext
lib/encounters/
├── encounters.dart          # Barrel export
├── encounter.dart           # Encounter class and EncounterType enum
├── encounter_generator.dart # Generates encounters by type/depth
└── combat_rewards.dart      # CombatResultDTO and CombatRewards
```

**Benefits:**

- Centralized encounter generation logic
- Structured combat result DTOs
- Easy to add new encounter types

---

### ✅ Phase 3: Progression Separation

**Status: COMPLETE**

Separated run-transient state from persistent meta state.

```plaintext
lib/progression/
├── progression.dart        # Barrel export
├── run_state.dart          # Transient per-run state
├── meta_state.dart         # Persistent progression
└── leveling_service.dart   # XP/level calculations
```

**Benefits:**

- Clear distinction between run and meta data
- Pure functions for leveling logic
- Easier save/load implementation

---

### ✅ Phase 4: Data-Driven JSON Definitions

**Status: PARTIAL - Infrastructure Complete**

Created JSON data files and loader infrastructure.

```plaintext
assets/data/
├── enemies.json            # Enemy definitions
└── mages.json              # Mage definitions

lib/data/
├── data_loader.dart        # JSON loading service
├── spell_definitions.dart  # (still hardcoded, ready for migration)
├── enemy_definitions.dart  # (still hardcoded, ready for migration)
├── elite_definitions.dart  # (still hardcoded, ready for migration)
└── mage_definitions.dart   # (still hardcoded, ready for migration)
```

**Benefits:**

- External JSON files created for enemies and mages
- DataLoader service with caching
- Assets configured in pubspec.yaml

**Remaining Work:**

- [ ] Convert spell_definitions.dart to use JSON
- [ ] Migrate enemy_definitions.dart to use DataLoader
- [ ] Migrate mage_definitions.dart to use DataLoader
- [ ] Create elite_definitions.json

---

### ✅ Phase 5: UI Layer Separation

**Status: PARTIAL - Components Extracted**

Extracted reusable UI components from text_renderer.dart.

```plaintext
lib/ui/
├── text_renderer.dart      # Main widget (to be simplified)
└── components/
    ├── components.dart     # Barrel export
    ├── common_widgets.dart # StatusChip, ActionButton, ResourceItem
    ├── log_view.dart       # LogLine, LogView
    └── screen_info.dart    # Screen-to-display mapping
```

**Benefits:**

- Reusable UI components
- Centralized log styling
- Screen info utility

**Remaining Work:**

- [ ] Refactor text_renderer.dart to use extracted components
- [ ] Create screen-specific widgets
- [ ] Add more component extraction

---

## Pending Refactors

### Phase 6: Events System

**Status: NOT STARTED**

Create a data-driven event registry.

```plaintext
lib/events/
├── event.dart              # Base event interface
├── random_event.dart       # Random event implementation
├── event_resolver.dart     # Resolves event outcomes
└── event_definitions.dart  # Event registry
```

---

### Phase 7: Testing Infrastructure

**Status: NOT STARTED**

Add unit test coverage for core systems.

```plaintext
test/
├── domain/
│   ├── element_test.dart
│   ├── spell_test.dart
│   └── enemy_test.dart
├── nodes/
│   └── node_selector_test.dart
├── encounters/
│   └── encounter_generator_test.dart
└── progression/
    └── leveling_service_test.dart
```

---

## Current Project Structure

```plaintext
lib/
├── main.dart
├── data/                   # Game definitions
│   ├── data_loader.dart    # NEW: JSON loading service
│   ├── spell_definitions.dart
│   ├── enemy_definitions.dart
│   ├── elite_definitions.dart
│   └── mage_definitions.dart
├── domain/                 # Core domain models
│   ├── effect.dart
│   ├── element.dart
│   ├── elite_enemy.dart
│   ├── enemy.dart
│   ├── mage.dart
│   └── spell.dart
├── encounters/             # NEW: Encounter module
│   ├── encounters.dart
│   ├── encounter.dart
│   ├── encounter_generator.dart
│   └── combat_rewards.dart
├── game/                   # Game orchestration
│   ├── game_loop.dart
│   ├── game_state.dart
│   └── spellforge_game.dart
├── nodes/                  # NEW: Node module
│   ├── nodes.dart
│   ├── node_type.dart
│   ├── map_node.dart
│   ├── depth_level.dart
│   ├── node_selector.dart
│   └── node_map_system.dart
├── progression/            # NEW: Progression module
│   ├── progression.dart
│   ├── run_state.dart
│   ├── meta_state.dart
│   └── leveling_service.dart
├── systems/                # Game systems
│   ├── combat_system.dart
│   ├── difficulty_scaler.dart
│   ├── node_resolver.dart
│   ├── progression_system.dart
│   ├── shop_system.dart
│   └── spell_system.dart
└── ui/                     # UI layer
    ├── text_renderer.dart
    └── components/         # NEW: Reusable components
        ├── components.dart
        ├── common_widgets.dart
        ├── log_view.dart
        └── screen_info.dart

assets/
└── data/                   # NEW: JSON data files
    ├── enemies.json
    └── mages.json
```

---

## Next Steps

1. **Continue JSON Migration**: Migrate remaining hardcoded definitions to JSON
2. **Refactor text_renderer**: Use the extracted UI components
3. **Add Events Module**: Create data-driven event system
4. **Add Unit Tests**: Start with leveling_service and node_selector
5. **Integration**: Update game_state.dart to use new modules more fully

---

## Notes

- All phases analyze cleanly with `flutter analyze`
- Existing game functionality is preserved
- New modules are additive - old code paths still work
- Ready for incremental migration to new modules
