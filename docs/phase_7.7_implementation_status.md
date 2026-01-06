# Phase 7.7 - Narrative System Implementation

## Status: Core systems created, integration needed

---

## ✅ Completed Components

### 1. Data Models & Content (100%)

- **narrative_node.dart**: Core data model for narrative content
  - Supports multi-page tap-to-advance sequences
  - Speaker attribution (Director, World, or silent)
  - Completion callbacks

-**intro_lore.dart**: Complete 6-screen intro sequence

- Establishes Exodia lore
- Introduces the loop concept
- Sets atmospheric tone

- **elite_dialogue.dart**: Director commentary for 6 elite types
  - Burnward Colossus, Tempest Twins, Glacial Executioner
  - Infernal Warlord, Stone Sentinel, Typhoon Herald
  - Foreshadows mechanics without explicit rules

- **boss_narrative.dart**: Act 1 boss dialogue
  - Pre-fight shared narrative
  - Boss-specific commentary (Pyre & Tide)
  - Post-victory dialogue

### 2. UI Component (100%)

- **narrative_overlay.dart**: Fullscreen narrative widget
  - Tap-to-advance with fade animations
  - Background audio ducking integration
  - Page indicators for multi-page sequences
  - Tap indicator ("Tap to continue" / "Tap to close")

### 3. Audio Integration (100%)

- **AudioManager enhancements**:
  - `duckBackgroundMusic()`: Reduces music to 30% during narrative
  - `restoreBackgroundMusic()`: Returns to original volume
  - Tracks ducked state to prevent stacking

### 4. Persistence Layer (100%)

- **ProgressionSystem**:
  - `hasSeenIntro` flag with persistence
  - `markIntroAsSeen()` method
  - Loads/saves via SharedPreferences

- **GameState**:
  - `_shownEliteDialogues` set tracks which elites showed dialogue this run
  - `shouldShowEliteDialogue(eliteName)` checks if dialogue should appear
  - `markEliteDialogueShown(eliteName)` marks as shown
  - Resets on new run start

### 5. Module Exports (100%)

- Updated `narrative/narrative.dart` barrel export
- All Phase 7.7 content accessible via single import

---

## 🚧 Integration Tasks Remaining

### A. Main Menu / App Launch Integration

**Trigger**: First app launch (when `!progression.hasSeenIntro`)

**Implementation needed**:

1. Check `hasSeenIntro` flag when app loads
2. Show `NarrativeOverlay` with `IntroLore.getIntroSequence()`
3. On completion, call `progression.markIntroAsSeen()`
4. Transition to main menu

**Where to add**:

- Likely in `SpellforgeGame` initialization or main menu screen
- After audio preload completes

---

### B. Elite Combat Integration

**Trigger**: Before elite battle starts (in exploration or transition)

**Implementation needed**:

1. When displaying elite enemy in exploration screen:
   - Get elite name from enemy data
   - Check `gameState.shouldShowEliteDialogue(eliteName)`
   - If true, show `EliteDialogue.getDialogueForElite(eliteName)`
   - On completion, call `gameState.markEliteDialogueShown(eliteName)`
   - Then proceed to combat

**Where to add**:

- In `ExplorationScreen` when player taps elite enemy
- Before calling `startCombatDirectly()`
- OR in `_setupEliteCombat()` method in game_state.dart

---

### C. Boss Combat Integration

**Trigger**: Before boss battle starts

**Implementation needed**:

1. Show `BossNarrative.getPreFightNarrative()` first
2. Then show `BossNarrative.getBossSpecificNarrative(bossName)`
3. Then start combat
4. After victory, show `BossNarrative.getPostVictoryNarrative()`

**Where to add**:

- In `ExplorationScreen` when player engages boss
- OR in `_setupBossCombat()` method
- Post-victory: in combat victory handler

---

## 📋 Integration Checklist

- [ ] **Intro Lore**:
  - [ ] Detect first launch
  - [ ] Display intro sequence
  - [ ] Mark as seen
  - [ ] Test: Intro only shows once

- [ ] **Elite Dialogue**:
  - [ ] Hook into elite encounter flow
  - [ ] Display dialogue before combat
  - [ ] Track shown dialogues
  - [ ] Test: Each elite dialogue shows once per run

- [ ] **Boss Narrative**:
  - [ ] Pre-fight sequence
  - [ ] Boss-specific commentary
  - [ ] Post-victory dialogue
  - [ ] Test: All sequences trigger correctly

- [ ] **Audio**:
  - [ ] Verify background music ducks during narrative
  - [ ] Verify restoration after narrative closes
  - [ ] Optional: Add subtle SFX for narrative appearance

- [ ] **Testing**:
  - [ ] Complete run with intro → elites → boss
  - [ ] Verify persistence across app restarts
  - [ ] Verify elite dialogue resets between runs
  - [ ] Test tap-to-advance responsiveness

---

## 🔮 Future Enhancements (Phase 7.7+)

### Director Interest System

**Status**: Data structures ready, tracking not yet implemented

**What's needed**:

- Track interest events in DirectorSystem
- Modify dialogue selection based on interest level
- Add interest-based dialogue variants

**When to implement**: Phase 7.8 or later

**Data model**: Already defined in SDD, ready to build

---

## 🛠️ Quick Start Integration Guide

### 1. Intro Lore (Main Menu or Game Init)

```dart
// In main menu or game initialization
if (!gameState.progression.hasSeenIntro) {
  final introNode = IntroLore.getIntroSequence(
    onComplete: () async {
      await gameState.progression.markIntroAsSeen();
      // Continue to main menu
    },
  );
  
  // Show narrative overlay
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => NarrativeOverlay(
      narrativeNode: introNode,
      onComplete: () => Navigator.of(context).pop(),
    ),
  );
}
```

### 2. Elite Dialogue (Before Elite Combat)

```dart
// In exploration screen when elite is tapped
if (gameState.shouldShowEliteDialogue(eliteName)) {
  final dialogue = EliteDialogue.getDialogueForElite(
    eliteName: eliteName,
    onComplete: () {
      gameState.markEliteDialogueShown(eliteName);
      // Proceed to combat
      gameState.startCombatDirectly(enemies, isElite: true);
    },
  );
  
  if (dialogue != null) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NarrativeOverlay(
        narrativeNode: dialogue,
        onComplete: () => Navigator.of(context).pop(),
      ),
    );
  }
}
```

### 3. Boss Narrative (Before Boss Combat)

```dart
// Pre-fight sequence
final preFight = BossNarrative.getPreFightNarrative(
  onComplete: () {
    // Show boss-specific dialogue
  },
);

// Then boss-specific
final bossDialogue = BossNarrative.getBossSpecificNarrative(
  bossName: bossName,
  onComplete: () {
    // Start actual combat
  },
);
```

---

## 📁 Files Modified

### New Files Created

- `lib/narrative/narrative_node.dart`
- `lib/narrative/intro_lore.dart`
- `lib/narrative/elite_dialogue.dart`
- `lib/narrative/boss_narrative.dart`
- `lib/ui/narrative_overlay.dart`

### Modified Files

- `lib/systems/audio_manager.dart` (duck/restore methods)
- `lib/systems/progression_system.dart` (hasSeenIntro tracking)
- `lib/game/game_state.dart` (elite dialogue tracking)
- `lib/narrative/narrative.dart` (barrel exports)

---

## 🎯 Acceptance Criteria Progress

### Functional Requirements

- ✅ Intro lore data ready to trigger on first load
- ⏳ Intro lore integration pending
- ✅ Elite dialogue data ready
- ⏳ Elite dialogue triggering pending
- ✅ Boss dialogue data ready
- ⏳ Boss dialogue triggering pending
- ✅ Narrative overlay blocks input
- ✅ State persists correctly (data layer ready)
- ⏳ End-to-end persistence testing pending

### Narrative Requirements

- ✅ Tone consistent with Exodia theme
- ✅ No exposition during combat (dialogue before combat)
- ✅ Director never explains rules outright
- ✅ Atmospheric and observational voice

---

## 🚀 Next Steps

1. **Identify integration points** in existing UI screens
   - Main menu initialization
   - Exploration screen enemy interaction
   - Boss encounter flow

2. **Add NarrativeOverlay display logic** at triggered points

3. **Test complete narrative flow** from intro → elite → boss

4. **Polish**:
   - Add optional background images
   - Fine-tune fade timings
   - Optional SFX for narrative moments

5. **Future**: Build Director Interest System for dynamic tone shifts

---

## 💬 Notes

- All core narrative systems are **production-ready**
- Integration is **straightforward** - just add overlay display calls at trigger points
- Audio ducking is **automatic** via NarrativeOverlay widget
- Persistence is **fully handled** by underlying systems
- Design is **extensible** for future narrative nodes (events, endings, etc.)

**Estimated integration time**: 1-2 hours for full implementation + testing
