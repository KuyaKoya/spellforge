# Spellforge - Text-Based Roguelike

A text-based turn-based roguelike built with Flutter + Flame where you control a mage, cast spells, progress through nodes, upgrade spells, and battle elemental creatures.

## 🎮 Features

### Core Gameplay

- **Turn-based combat** with elemental effectiveness system
- **4 Elemental mages** to choose from (Pyromancer, Hydromancer, Geomancer, Aeromancer)
- **Spell loadout system** (max 4 spells)
- **Spell upgrades** (★ → ★★ → ★★★)
- **Leveling system** with experience and stat bonuses
- **Target selection** for single-target spells with multiple enemies
- **Auto-end turn** when no actions are available
- **Persistent progression** (spell fragments & crystals saved across runs)

### Leveling System

Defeat enemies to gain experience and level up!

| Level | EXP Required | Cumulative |
|-------|--------------|------------|
| 1 → 2 | 10 | 10 |
| 2 → 3 | 15 | 25 |
| 3 → 4 | 22 | 47 |
| 4 → 5 | 30 | 77 |
| 5 → 6 | 40 | 117 |
| 6+ | +12 per level | ... |

**Level-up Bonuses:**

- +5 Max HP (and heals that amount)
- +2 Max Mana
- Every 3 levels: +1 Action per turn

### Elemental System

Fire > Earth > Air > Water > Fire (cyclic effectiveness)

| Matchup | Damage Multiplier |
|---------|-------------------|
| ✅ Strong | 1.5× |
| ❌ Weak | 0.75× |
| ➖ Neutral | 1.0× |

### Node Progression (10 Nodes)

| Node | Type | Description |
|------|------|-------------|
| 0 | ⚔️ Combat | Intro battle |
| 1 | 📖 Spell Learn | First spell reward |
| 2 | ⚔️ Combat | Second battle |
| 3 | ⚔️ Combat | Third battle |
| 4 | ❓ Random Event | Random encounter |
| 5 | ⚔️ Combat | Fourth battle |
| 6 | ⚔️ Combat | Fifth battle |
| 7 | 🛏️ Rest | Rest before boss |
| 8 | ⭐ Enhancement | Final upgrade |
| 9 | 👹 Boss Combat | Boss battle |

### Random Events

- **💎 Treasure** - Find spell fragments
- **⚔️ Trial of Flames** - Risk HP for fragments
- **🧙 Wandering Merchant** - Buy random spells
- **✨ Ancient Blessing** - Free healing

### Spell Rarities

| Rarity | Icon | Description |
|--------|------|-------------|
| Common | ⚪ | Basic spells |
| Uncommon | 🟢 | Spells with status effects |
| Rare | 🔵 | Powerful spells with multiple effects |
| Signature | 🟡 | Legendary spells |

### Status Effects

| Effect | Icon | Description |
|--------|------|-------------|
| Burn | 🔥 | Damage over time |
| Slow | 🐌 | Reduce enemy actions |
| Weaken | 💀 | Reduce enemy damage |
| Armor | 🛡️ | Absorb incoming damage |
| Delay | ⏸️ | Skip enemy turn |

### Combat Display

The combat log shows detailed information:

- **Numbered enemies** with HP and intent
- **Element indicators** for targeting
- **Damage effectiveness** (Strong/Weak/Neutral)
- **Status effect tracking**
- **Turn-by-turn logging**

## 🛠️ Tech Stack

- **Flutter** - Cross-platform UI framework
- **Flame** - Game loop hosting
- **shared_preferences** - Persistent storage

## 📁 Project Structure

```
lib/
 ├── game/
 │   ├── spellforge_game.dart   # Main Flame game class
 │   ├── game_state.dart         # Game state management
 │   └── game_loop.dart          # Player action handling
 ├── domain/
 │   ├── mage.dart               # Mage entity with leveling
 │   ├── spell.dart              # Spell entity with detailed stats
 │   ├── effect.dart             # Effect & status system
 │   ├── enemy.dart              # Enemy entity
 │   └── element.dart            # Elemental system
 ├── systems/
 │   ├── combat_system.dart      # Turn-based combat with logging
 │   ├── spell_system.dart       # Spell casting & resolution
 │   ├── node_system.dart        # Fixed node progression
 │   └── progression_system.dart # Persistent resources
 ├── ui/
 │   └── text_renderer.dart      # Text UI widget
 ├── data/
 │   ├── spell_definitions.dart  # Spell templates
 │   ├── enemy_definitions.dart  # Enemy templates
 │   └── mage_definitions.dart   # Mage templates
 └── main.dart                   # App entry point
```

## 🎯 Controls

### Keyboard Controls

| Key | Action |
|-----|--------|
| N | New Run |
| E | Enter Node / End Turn |
| 1-4 | Select option / Cast spell / Choose target |
| C | Cancel target selection |
| S | Skip |
| R | Rest |
| M | Main Menu |

### On-Screen Buttons

All actions are also available as clickable buttons at the bottom of the screen.

## 🚀 Getting Started

```bash
# Clone the repository
git clone <repository-url>
cd spellforge

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 📱 Supported Platforms

- ✅ macOS
- ✅ Windows
- ✅ Linux
- ✅ iOS
- ✅ Android
- ✅ Web

## 🎲 How to Play

1. **Start a new run** - Press [N] on the main menu
2. **Choose your mage** - Select from 4 elemental mages
3. **Navigate nodes** - Press [E] to enter the current node
4. **Combat**:
   - Cast spells with [1-4] keys
   - Select target when facing multiple enemies
   - End turn with [E] (or auto-ends when no actions left)
   - Defeat all enemies to win and gain EXP!
5. **Level up** - Gain HP, Mana, and Actions as you level
6. **Learn spells** - Choose from 3 offered spells at Spell Shrines
7. **Random events** - Make choices at mysterious encounters
8. **Upgrade spells** - Spend fragments at Enhancement Shrines
9. **Rest** - Recover HP at Rest Sites
10. **Boss battle** - Defeat the Elemental Guardian to win!

## 📊 Features Implemented

- [x] Start a run and choose a mage
- [x] Progress through 10 fixed nodes
- [x] Turn-based combat with elemental effectiveness
- [x] Target selection for multi-enemy encounters
- [x] Learn and replace spells
- [x] Upgrade spells to ★★★
- [x] Experience and leveling system
- [x] Random events with choices
- [x] Boss battle finale
- [x] Detailed combat logging
- [x] Auto-end turn when no actions available
- [x] Persistent progression (fragments saved across runs)

## 📄 License

MIT License
