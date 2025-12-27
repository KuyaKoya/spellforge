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

### Phase 2: Node Progression & Elite Encounters (NEW!)

#### Strategic Path Choices

- **1-2 node choices per depth** - Make meaningful path decisions
- **Node sequencing rules** - Same type won't appear twice in a row
- **Combat frequency guarantee** - Combat every 2 depths minimum

#### Node Types

| Type | Icon | Description |
|------|------|-------------|
| Combat | ⚔️ | Standard battle with scaling enemies |
| Spell Shrine | 📖 | Learn a new spell |
| Enhancement Shrine | ⭐ | Upgrade your spells |
| Shop | 🏪 | Trade fragments for items |
| Rest | 🛏️ | Recovery with tradeoffs |
| Elite | 💀 | High-risk, high-reward combat |
| Random Event | ❓ | Unexpected encounters |
| Boss | 👹 | Final battle |

#### Elite Encounters

Elite enemies test your build, not just stats!

**Elite Modifiers:**

| Modifier | Effect |
|----------|--------|
| 💪 Empowered | +50% damage |
| 🛡️ Resistant | 50% reduction from one element |
| ⚡ Relentless | Acts twice every 3 turns |
| 🔄 Adaptive | Gains resistance to repeated elements |

**Example Elite Encounters:**

- **Burnward Colossus** - Earth elite, resistant to Fire
- **Tempest Twins** - Dual Air elites with bonus actions
- **Glacial Executioner** - Water elite with heavy delayed attacks

#### Shop System

- **Buy Spell Fragments** - Stock up on upgrade currency
- **Buy Spell Crystal** - Rare crystals (after depth 4)
- **Buy Spells** - Rarity based on depth
- **Buy Heals** - Restore HP
- **Buy Temporary Buffs** - +25% damage for 3 nodes

#### Difficulty Scaling

| Depth | Expected Player State |
|-------|----------------------|
| 1-2 | Building initial loadout |
| 3 | 1 upgraded spell |
| 5 | Core spell defined |
| 7 | Synergy online |
| 9+ | Build under pressure |

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
 │   ├── elite_enemy.dart        # Elite enemies with modifiers
 │   └── element.dart            # Elemental system
 ├── systems/
 │   ├── combat_system.dart      # Turn-based combat with logging
 │   ├── spell_system.dart       # Spell casting & resolution
 │   ├── node_map_system.dart    # Depth-based node progression
 │   ├── node_resolver.dart      # Node content generation
 │   ├── shop_system.dart        # Shop items & purchasing
 │   ├── difficulty_scaler.dart  # Depth-based difficulty
 │   └── progression_system.dart # Persistent resources
 ├── ui/
 │   └── text_renderer.dart      # Text UI widget
 ├── data/
 │   ├── spell_definitions.dart  # Spell templates
 │   ├── enemy_definitions.dart  # Enemy templates
 │   ├── elite_definitions.dart  # Elite encounter templates
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
| B | Temp Buff (at rest) |
| M | Modifier removal / Main Menu |
| Y | Confirm (elite) |
| L | Leave shop |

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
3. **Navigate nodes** - Choose your path when offered multiple options
4. **Combat**:
   - Cast spells with [1-4] keys
   - Select target when facing multiple enemies
   - End turn with [E] (or auto-ends when no actions left)
   - Defeat all enemies to win and gain EXP!
5. **Elite encounters**:
   - Confirm [Y] or retreat [N]
   - Failure ends your run!
   - Victory grants guaranteed rare rewards
6. **Shop** - Purchase items with fragments
7. **Level up** - Gain HP, Mana, and Actions as you level
8. **Learn spells** - Choose from 3 offered spells at Spell Shrines
9. **Random events** - Make choices at mysterious encounters
10. **Upgrade spells** - Spend fragments at Enhancement Shrines
11. **Rest** - Choose between: heal, remove modifier, or temp buff
12. **Boss battle** - Defeat the Elemental Guardian to win!

## 📊 Features Implemented

### Phase 1 ✅

- [x] Start a run and choose a mage
- [x] Progress through fixed nodes
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

### Phase 2 ✅ (NEW!)

- [x] Node path choices (1-2 options per depth)
- [x] Elite encounters with modifiers
- [x] Elite rewards (crystal, spell, upgrade)
- [x] Shop node with inventory
- [x] Difficulty scaling by depth
- [x] Temporary buffs system
- [x] Rest node with multiple options
- [x] Node sequencing constraints

## 🔮 Future Phases

### Phase 3: Boss Nodes

- Unique boss encounters
- Branching map visualization
- Daily seeded runs

### Phase 4: Arcanist & Sub-elements

- Arcanist unlock system
- Sub-element encounters
- Advanced spell modifiers

## 📄 License

MIT License
