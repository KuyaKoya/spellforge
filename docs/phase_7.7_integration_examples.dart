/// PHASE 7.7 INTEGRATION EXAMPLE
///
/// This file demonstrates how to integrate the narrative system
/// into the existing SpellForge flow. Copy the relevant sections
/// into your actual implementation files.

// ============================================================
// EXAMPLE 1: Intro Lore on First Launch
// ============================================================
// Location: In MainMenuOverlay or SpellforgeGame initialization
// Trigger: Check hasSeenIntro flag when main menu loads

import 'package:flutter/material.dart';
import '../narrative/narrative.dart'; // Imports all narrative system components
import '../ui/narrative_overlay.dart';
import '../systems/progression_system.dart';
import '../game/game_state.dart';

// In your main menu's initState() or build() method:
void showIntroLoreIfNeeded(BuildContext context, GameState gameState) {
  // Check if user has seen intro
  if (!gameState.progression.hasSeenIntro) {
    // Small delay to let the menu UI settle
    Future.delayed(const Duration(milliseconds: 500), () {
      final introNode = IntroLore.getIntroSequence(
        onComplete: () async {
          // Mark intro as seen
          await gameState.progression.markIntroAsSeen();
          print('Intro lore complete - marked as seen');
        },
      );

      // Show fullscreen narrative overlay
      showDialog(
        context: context,
        barrierDismissible: false, // Force user to tap through
        builder: (context) => NarrativeOverlay(
          narrativeNode: introNode,
          onComplete: () {
            Navigator.of(context).pop();
          },
          showFadeIn: true,
        ),
      );
    });
  }
}

// ============================================================
// EXAMPLE 2: Elite Dialogue Before Combat
// ============================================================
// Location: In ExplorationScreen when player taps elite enemy
// Trigger: Before calling startCombatDirectly()

void handleEliteEncounter(
  BuildContext context,
  GameState gameState,
  List<Enemy> eliteEnemies,
  String eliteName, // e.g., "Burnward Colossus"
) {
  // Check if we should show dialogue for this elite
  if (gameState.shouldShowEliteDialogue(eliteName)) {
    // Get dialogue for this specific elite
    final dialogue = EliteDialogue.getDialogueForElite(
      eliteName: eliteName,
      onComplete: () {
        // Mark dialogue as shown
        gameState.markEliteDialogueShown(eliteName);
        print('Elite dialogue shown for: $eliteName');
      },
    );

    if (dialogue != null) {
      // Show dialogue overlay
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => NarrativeOverlay(
          narrativeNode: dialogue,
          onComplete: () {
            Navigator.of(context).pop();
            // Proceed to combat after dialogue
            gameState.startCombatDirectly(eliteEnemies, isElite: true);
          },
          showFadeIn: true,
        ),
      );
    } else {
      // No dialogue defined for this elite, proceed directly
      gameState.startCombatDirectly(eliteEnemies, isElite: true);
    }
  } else {
    // Dialogue already shown this run, proceed directly
    gameState.startCombatDirectly(eliteEnemies, isElite: true);
  }
}

// ============================================================
// EXAMPLE 3: Boss Narrative Sequence
// ============================================================
// Location: In ExplorationScreen when player engages boss
// Trigger: Before boss combat starts

void handleBossEncounter(
  BuildContext context,
  GameState gameState,
  List<Enemy> bossEnemies,
  String bossName, // e.g., "Gatekeeper of Pyre"
) {
  // Step 1: Show shared pre-fight narrative
  final preFightNode = BossNarrative.getPreFightNarrative(
    onComplete: () {
      print('Boss pre-fight narrative complete');
    },
  );

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => NarrativeOverlay(
      narrativeNode: preFightNode,
      onComplete: () {
        Navigator.of(context).pop();
        // After pre-fight, show boss-specific dialogue
        _showBossSpecificDialogue(context, gameState, bossEnemies, bossName);
      },
      showFadeIn: true,
    ),
  );
}

void _showBossSpecificDialogue(
  BuildContext context,
  GameState gameState,
  List<Enemy> bossEnemies,
  String bossName,
) {
  final bossDialogue = BossNarrative.getBossSpecificNarrative(
    bossName: bossName,
    onComplete: () {
      print('Boss-specific dialogue complete: $bossName');
    },
  );

  if (bossDialogue != null) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NarrativeOverlay(
        narrativeNode: bossDialogue,
        onComplete: () {
          Navigator.of(context).pop();
          // Start actual boss combat
          gameState.startCombatDirectly(bossEnemies, isElite: false);
        },
        showFadeIn: true,
      ),
    );
  } else {
    // No specific dialogue, proceed to combat
    gameState.startCombatDirectly(bossEnemies, isElite: false);
  }
}

// ============================================================
// EXAMPLE 4: Post-Victory Boss Dialogue
// ============================================================
// Location: In combat victory handler, after boss is defeated
// Trigger: When combat ends with victory && isBossCombat

void handleBossVictory(BuildContext context, GameState gameState) {
  final postVictoryNode = BossNarrative.getPostVictoryNarrative(
    onComplete: () {
      print('Boss victory narrative complete');
    },
  );

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => NarrativeOverlay(
      narrativeNode: postVictoryNode,
      onComplete: () {
        Navigator.of(context).pop();
        // Continue to rewards or run end
      },
      showFadeIn: true,
    ),
  );
}

// ============================================================
// IMPLEMENTATION NOTES
// ============================================================

/*
## Where to Add These Integrations:

### 1. Intro Lore
- File: lib/ui/exploration/overlays/main_menu_overlay.dart
- Method: Inside initState() or at end of build()
- Add: Call showIntroLoreIfNeeded() when menu first loads

### 2. Elite Dialogue
- File: lib/ui/exploration/exploration_screen.dart
- Location: Where player taps elite enemy sprite
- Replace: Direct call to startCombatDirectly()
- With: Call to handleEliteEncounter()

### 3. Boss Narrative (Pre-Fight)
- File: lib/ui/exploration/exploration_screen.dart
- Location: Where player engages boss enemy
- Replace: Direct call to startCombatDirectly() for boss
- With: Call to handleBossEncounter()

### 4. Boss Narrative (Post-Victory)
- File: lib/systems/combat_system.dart or battle UI
- Location: Victory handler when isBossCombat == true
- Add: Call to handleBossVictory() before transitioning away

## Testing Checklist:

1. First Launch:
   - [ ] Intro shows on very first app launch
   - [ ] Intro does NOT show on subsequent launches
   - [ ] Can tap through all 6 screens
   - [ ] Background music ducks during intro
   - [ ] Music restores after intro

2. Elite Combat:
   - [ ] Dialogue appears before first elite of each type
   - [ ] Dialogue does NOT appear on second elite of same type
   - [ ] Dialogue resets on new run
   - [ ] Combat starts correctly after dialogue

3. Boss Combat:
   - [ ] Pre-fight narrative appears
   - [ ] Boss-specific dialogue appears
   - [ ] Post-victory dialogue appears
   - [ ] All sequences play in correct order

4. Audio:
   - [ ] Background music volume reduces during narrative
   - [ ] Music volume restores after narrative closes
   - [ ] No audio glitches or stutters
*/
