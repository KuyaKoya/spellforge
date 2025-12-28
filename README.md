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
 ├── director/                   # Phase 4: Director System
 │   ├── director_system.dart    # Main Director logic
 │   ├── director_state.dart     # Pressure states (neutral/aggressive/merciful)
 │   ├── director_rules.dart     # Adjustment rules & thresholds
 │   ├── director_logger.dart    # Decision logging
 │   └── pressure_metrics.dart   # Player performance metrics
 ├── ascension/                  # Phase 4: Ascension System
 │   └── ascension.dart          # 10 difficulty levels with modifiers
 ├── relics/                     # Phase 4: Relic System
 │   ├── relic.dart              # Relic definitions (18 relics)
 │   └── relic_system.dart       # Relic management & generation
 ├── summary/                    # Phase 4: Run Summary
 │   ├── run_summary.dart        # Comprehensive run statistics
 │   └── run_summary_builder.dart # Statistics tracking
 ├── core/                       # Core utilities
 │   └── seeded_random.dart      # Deterministic random for seeded runs
 ├── encounters/
 │   ├── encounter.dart          # Encounter data
 │   ├── encounter_generator.dart # Encounter generation
 │   ├── combat_rewards.dart     # Reward calculations
 │   └── enemy_archetype.dart    # Enemy behavior patterns
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

### Phase 3: Boss Nodes

- Unique boss encounters
- Branching map visualization
- Daily seeded runs

### Phase 4: Director-Driven Replayability ✅

- [x] **Director System** - Observes player performance and adjusts difficulty
- [x] **Ascension System** - 10 levels of optional difficulty modifiers
- [x] **Relic System** - 18 passive relics with triggers and synergies
- [x] **Seeded Runs** - Shareable deterministic runs
- [x] **Run Summary** - Comprehensive statistics and damage breakdown
- [x] **Enemy Archetypes** - Behavior patterns with intent probabilities

### Phase 5: Act 1 Demo ✅ (NEW!)

Act I: The Threshold - A self-contained demo experience.

#### Narrative System

- [x] **Director Lines** - Cold, observational dialogue that reacts to performance
- [x] **Lore Fragments** - Short, archival text pieces discovered during runs
- [x] **Journey Log** - Persistent record of lore, Director observations, and relics
- [x] **Narrative Text Display** - Centered, focused text with fade-in animation
- [x] **Entry Narrative** - Introduces Exodia and the loop at run start
- [x] **Victory/Defeat Text** - Calm, incomplete, slightly unsettling endings

#### Act 1 Content

- [x] **Twin Gatekeepers Boss** - Fire+Earth and Water+Air dual bosses
  - Silent, mechanistic barriers that test readiness
  - Synergy attacks when both are alive
  - Defeating them does not end the loop
- [x] **Act 1 Relics** - 8 elemental relics in 4 sets:
  - Fire: Flame Robe / Charcoal Wand
  - Water: Water Shield / Frost Sword
  - Earth: Hardened Scales / Undying Helmet
  - Air: Zephyr Boots / Wings of the Storm
  - Each with lore fragment and set-completion bonus

#### UI Systems (LOCKED)

- [x] **Node Breadcrumbs** - Abstract symbolic iconography
  - Entry: Hollow circle | Combat: Split diamond | Relic: Fractured square
  - Shrine: Vertical line | Boss: Closed gate | Future: Veiled symbol
  - States: Completed (dimmed), Current (glow pulse), Future (abstracted)
  - No text labels, no color coding, no animations beyond glow
  
- [x] **Journey Log Panel** - Narrative archive (pause menu only)
  - Dark background, serif font, low contrast
  - Persists across runs, ordered by discovery
  - Contains: Lore only. Never same event as Combat Log
  
- [x] **Combat Log Panel** - System transparency (combat only)
  - High contrast, monospace font, element icons
  - Resets every combat, 50 entry hard cap, auto-scroll
  - Contains: Numbers only. Never same event as Journey Log
  
- [x] **Spell Inspection** - Long-press contextual overlay
  - Side-mounted, not modal, not turn-pausing
  - Content: Name, Element, Effect, Modifiers, Status, Tier
  - Dismissal: Release long-press or tap outside (no close button)

#### Core Narrative Pillars

- The world is Exodia
- The player is trapped in a loop
- The Director observes but does not guide
- Act 1 is a filter, not a victory
- Progress is implied, never confirmed

#### Design Rationale (LOCKED)

These decisions intentionally:

- Make repetition visible
- Make mastery learnable
- Make certainty impossible

### Phase 6: Battle UI & Presentation ✅ (NEW!)

Pokémon-inspired battle UI with Flutter/Flame hybrid architecture.

#### Battle Screen Architecture (LOCKED)

```text
BattleScreen (Flutter)
├── Stack
│   ├── FlameGameWidget (BattleScene)  ← Flame renders world
│   ├── EnemyStatusBar (top-right)     ← Flutter renders UI
│   ├── PlayerStatusBar (bottom-left)
│   ├── NodeBreadcrumbs (top-center, 50% opacity)
│   ├── DirectorSubtitleOverlay (bottom-center)
│   ├── CombatLogPanel (bottom, toggle)
│   ├── SpellDetailOverlay (side, contextual)
│   └── BattleActionMenu (bottom-right)
```

#### Status Bars (LOCKED)

- **EnemyStatusBar**: Name, animated HP bar (no numbers), element icon, status icons
- **PlayerStatusBar**: Portrait (changes on low HP), name, HP/Mana bars, element, buffs

#### Battle Action Menu (LOCKED)

- **Root Menu**: 2x2 grid (Spells, Inspect, Items, Retreat) + End Turn
- **Spell Selection**: Grid with icons, element accent, mana cost, modifier glyphs
- **Interaction**: Tap → Cast, Long-press → Spell inspection

#### Combat Feedback System

1. Animation (Flame sprites)
2. Floating damage numbers (element-colored, fade quickly)
3. Status effect icons
4. Combat log entries

#### Director Subtitle Overlay

- Auto-fading, never blocks input
- One line, muted text
- Triggered at combat events

#### Files Created

- `lib/ui/battle/battle_screen.dart` - Main battle widget
- `lib/ui/battle/battle_scene.dart` - Flame game scene
- `lib/ui/battle/status_bars.dart` - HP/Mana bars
- `lib/ui/battle/battle_action_menu.dart` - Action menu
- `lib/ui/battle/director_subtitle_overlay.dart` - Director text
- `lib/ui/battle/floating_damage.dart` - Damage numbers
- `lib/ui/battle/battle.dart` - Barrel export

## 📄 License

MIT License
