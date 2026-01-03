# Spellforge - Pokémon-Style Elemental Roguelike

A turn-based roguelike built with Flutter + Flame featuring Pokémon-inspired combat, elemental spell system, and room-based exploration.

## 🎮 Phase 1 Demo Features

### Combat System (Pokémon-Style)

Experience turn-based combat inspired by Pokémon Emerald:

- **Sequential turn flow** - "Mage used Fireball!" → Animation → "It's super effective!" → Damage
- **Elemental effectiveness** - Text color indicates effectiveness (Green = super effective, Red = not effective)
- **Dialog box narration** - All actions explained in the classic text box
- **Enemy turn visibility** - Watch each enemy's action play out one at a time

### Exploration System

Room-based exploration with interactive elements:

- **Spatial rooms** - Move through rooms and interact with objects
- **Combat encounters** - Engage enemies when you choose
- **Non-combat interactables** - Campfires for healing, shrines for upgrades
- **Door navigation** - Preview what's behind each door before entering

### Core Gameplay

- **4 Elemental mages** - Pyromancer, Hydromancer, Geomancer, Aeromancer
- **Spell loadout** - Manage up to 4 spells
- **Spell upgrades** - Upgrade from ★ to ★★★
- **Leveling system** - Gain EXP, level up, increase stats
- **Random events** - Treasure, trials, merchants, blessings

### Elemental System

Fire > Earth > Air > Water > Fire (cyclic effectiveness)

| Matchup | Damage | Text Color |
|---------|--------|------------|
| ✅ Strong | 1.5× | Green |
| ❌ Weak | 0.75× | Red |
| ⚡ Mixed | Varies | Yellow |
| ➖ Neutral | 1.0× | White |

## 🎨 UI Layout

### Battle Screen (Pokémon-Style Zones)

```
┌─────────────────────────────────────┐
│     ENEMY STATUS PANEL              │  Zone 1 (35%)
│        [Enemy Sprite]               │
├─────────────────────────────────────┤
│                                     │  Zone 2 (25%)
│     [Player Sprite]                 │
│                      [HP/MP Bar] ──►│  Zone 3 (15%)
├───────────────────┬─────────────────┤
│ Dialog Box        │ Action Buttons  │  Zone 4 (25%)
│ "What will Mage   │ ┌─────┐┌─────┐  │
│  do?"             │ │SPELL││ END │  │
│                   │ └─────┘└─────┘  │
└───────────────────┴─────────────────┘
```

### Spell Selection (Full Width)

```
┌───────────┬───────────┬──────┐
│    🔥     │    💧     │      │
│ Fireball  │ Water Bolt│      │
├───────────┼───────────┤ BACK │
│    🪨     │    💨     │      │
│ Rock Throw│ Wind Slash│      │
└───────────┴───────────┴──────┘
```

## 🎯 Controls

### Touch/Click Controls

| Area | Action |
|------|--------|
| Spell Button | Cast spell |
| Target Button | Select target |
| Dialog Box | Tap to continue |
| BACK Button | Return to previous menu |

### Keyboard Controls

| Key | Action |
|-----|--------|
| 1-4 | Cast spell / Select option |
| E | End turn |
| Escape | Back / Cancel |

## 🛠️ Tech Stack

- **Flutter** - Cross-platform UI framework
- **Flame** - 2D game engine for sprites/animations
- **Hybrid Architecture** - Flame renders world, Flutter renders UI

## 📁 Project Structure

```
lib/
 ├── game/
 │   ├── spellforge_game.dart    # Main Flame game
 │   ├── game_state.dart         # Game state management
 │   ├── game_loop.dart          # Player action handling
 │   └── exploration/            # Room-based exploration
 ├── domain/
 │   ├── mage.dart               # Mage entity
 │   ├── spell.dart              # Spell definitions
 │   ├── enemy.dart              # Enemy entity
 │   └── element.dart            # Elemental system
 ├── systems/
 │   ├── combat_system.dart      # Turn-based combat
 │   ├── spell_system.dart       # Spell casting & effects
 │   └── node_resolver.dart      # Content generation
 ├── nodes/
 │   ├── node_map_system.dart    # Node progression
 │   └── node_selector.dart      # Node type selection
 ├── ui/
 │   ├── battle/                 # Battle UI components
 │   │   ├── battle_screen.dart  # Main battle widget
 │   │   ├── battle_scene.dart   # Flame scene
 │   │   ├── status_bars.dart    # HP/MP bars
 │   │   └── battle_action_menu.dart
 │   ├── exploration/            # Exploration UI
 │   │   └── overlays/           # Room overlays
 │   └── text_renderer.dart      # Text UI
 └── data/
     ├── spell_definitions.dart  # Spell templates
     ├── enemy_definitions.dart  # Enemy templates
     └── mage_definitions.dart   # Mage templates
```

## 🚀 Getting Started

```bash
# Clone the repository
git clone <repository-url>
cd spellforge

# Install dependencies
flutter pub get

# Run the app (debug)
flutter run

# Build APK (Android)
flutter build apk
```

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Windows
- ✅ macOS
- ✅ Linux
- ✅ Web

## 🎲 How to Play

1. **Start Game** - Launch and select "New Run"
2. **Choose Mage** - Pick from 4 elemental mages
3. **Explore** - Navigate through rooms using doors
4. **Combat**:
   - Select "SPELLS" from the action menu
   - Choose a spell (color indicates effectiveness)
   - Select target if multiple enemies
   - Watch the combat play out
   - Repeat until victory!
5. **Interact** - Use campfires to heal, shrines to upgrade
6. **Progress** - Continue through rooms until the boss

## ✅ Phase 1 Demo Checklist

- [x] Pokémon-style combat flow with dialog narration
- [x] Sequential turn execution with animations
- [x] Elemental effectiveness with color-coded spell names
- [x] 2x2 spell selection grid (full width)
- [x] Room-based exploration system
- [x] Combat encounters with guaranteed frequency
- [x] Non-combat interactables (campfire, shrine)
- [x] Random events with choices
- [x] HP/MP status bars
- [x] Floating damage numbers
- [x] Enemy turn visibility

## 🔮 Future Phases

### Phase 2: Content Expansion

- More spells and enemies
- Elite encounters
- Shop system
- Spell upgrades

### Phase 3: Narrative

- Director system
- Lore fragments
- Journey log
- Boss encounters

### Phase 4: Polish

- Sound effects
- Music
- Visual effects
- Save system

## 📄 License

MIT License
