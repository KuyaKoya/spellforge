# SpellForge Audio & Battle Timing Refactor

## Summary

This refactor implements centralized audio management and restructures battle execution order to ensure attack animations and sounds **always occur before** gameplay state changes.

## Changes Made

### Part 1: Audio System Integration

#### 1. AudioManager (`lib/systems/audio_manager.dart`) - NEW

A centralized singleton for all audio playback:

- **Volume Control**: Separate controls for SFX and Music (`setSfxVolume`, `setMusicVolume`)
- **Debouncing**: Prevents overlapping/duplicate sound playback (50ms debounce)
- **Graceful Degradation**: Missing assets are logged but don't crash the game
- **Music States**: Supports exploration, normalCombat, eliteCombat, bossCombat states
- **Methods**:
  - `playSfx(String key)` - Play sound effect by key
  - `playSpellSfx(String spellId)` - Play spell-specific sound
  - `playMusic(String key, {bool loop})` - Play background music
  - `stopMusic()` - Stop all music
  - `transitionToMusicState(MusicState)` - Change music based on game state
  - Convenience methods: `playEnemyAttack()`, `playShieldGain()`, `playDebuff()`, etc.

#### 2. AudioSystem (`lib/systems/audio_system.dart`) - UPDATED

Now delegates to AudioManager for backward compatibility:

- All existing static methods still work
- Marked as `@deprecated` - new code should use AudioManager directly

#### 3. Sound Effect Mapping

All sound effects are mapped to gameplay events:

- **Room enter**: TODO (asset needed)
- **Combat start**: TODO (asset needed)
- **Spell cast**: Per-spell sounds (fireball, inferno, water_bolt, etc.)
- **Damage dealt**: Uses enemy_attack.mp3
- **Shield gained**: armor.mp3
- **Status applied**: burn.mp3, debuff.mp3
- **Enemy defeated**: enemy_death.mp3
- **Player defeated**: battle_defeat.mp3
- **Battle won**: battle_win.mp3

### Part 2: Battle Flow Refactor

#### 4. Battle Execution Order - CRITICAL CHANGE

All combat actions now follow this strict sequence:

```
1. Intent resolution (who attacks whom, which spell)
2. Play attack animation
3. Play corresponding sound effect
4. Delay (configurable)
5. Apply damage
6. Apply buffs / debuffs
7. Trigger status effects
8. Update UI state
9. Check for death / end of combat
```

#### 5. BattleTiming Class (`lib/ui/battle/battle_screen.dart`)

Configurable timing constants (in milliseconds):

- `spellCastToSound`: 300ms - Delay after cast message before sound
- `soundToDamage`: 400ms - Delay after sound before damage applied
- `effectivenessDisplay`: 800ms - Duration for "Super effective!" message
- `damageResultDisplay`: 900ms - Duration for damage result message
- `enemyFaintedDisplay`: 1100ms - Duration for enemy fainted message
- `enemyIntentDisplay`: 700ms - Delay showing enemy intent
- `enemySoundToDamage`: 350ms - Delay after enemy sound before damage
- `enemyDamageDisplay`: 700ms - Duration for enemy damage display
- `enemyOtherActionDisplay`: 700ms - Duration for defend/debuff messages

#### 6. CombatSystem Changes (`lib/systems/combat_system.dart`)

**Removed audio from `castSpell()`** - BattleScreen now handles audio timing

**Added new methods for UI-controlled enemy execution**:

- `prepareEnemyPhase()` - Switches to enemy phase, returns (enemy, intent) pairs WITHOUT executing actions
- `executeEnemyActionManual(enemy, intent)` - Executes a single enemy action, returns `EnemyActionResult`
- `finalizeEnemyPhase()` - Handles status effects and turn transition after all enemy actions

**New class `EnemyActionResult`**:

```dart
class EnemyActionResult {
  final int damageDealt;
  final String? statusApplied;
  final bool targetDefeated;
  final bool skipped;
}
```

#### 7. BattleScreen Changes (`lib/ui/battle/battle_screen.dart`)

**Player Spell Flow**:

```
_executePlayerSpell
  ├─ Show cast message + play animation (NO DAMAGE)
  ├─ Wait spellCastToSound (300ms)
  ├─ Play spell sound via AudioManager
  ├─ Wait soundToDamage (400ms)
  └─ _applyPlayerSpellDamage
      ├─ Apply damage via combat.castSpell()
      ├─ Play result sounds (enemy death, debuff, etc.)
      └─ Show effectiveness/damage messages
```

**Enemy Action Flow**:

```
_startEnemyPhase
  ├─ combat.prepareEnemyPhase() (captures intents, NO damage)
  └─ _executeEnemyActionWithTiming(0)
      ├─ Show intent message
      ├─ Wait enemyIntentDisplay (700ms)
      ├─ Play sound (attack/defend/debuff)
      ├─ Wait enemySoundToDamage (350ms)
      └─ _applyEnemyAction
          ├─ Apply damage via combat.executeEnemyActionManual()
          ├─ Show result message
          └─ Continue to next enemy or _finalizeEnemyPhase
```

### Part 3: Combat Action Queue (Future Expansion)

Created `lib/systems/combat_action_queue.dart` for future use:

- Serialized action execution
- Async execution with callbacks for before/after apply
- Supports combo attacks, reactions (future)

Currently not integrated but available for future expansion.

## Validation Checklist

✅ No damage appears before sound plays
✅ No buff/debuff appears before sound plays
✅ Combat feels sequential and readable
✅ Audio does not overlap or double-play (debouncing)
✅ Muting audio does not break combat (volume = 0 supported)

## Not Implemented (Out of Scope)

- UI redesign
- Particle effects polish
- Volume sliders UI
- Settings menu
- Multiplayer hooks
- Room enter sound (asset needed)
- Combat start sound (asset needed)
- Combat-specific music tracks (assets needed)

## Files Modified

1. `lib/systems/audio_manager.dart` - NEW
2. `lib/systems/audio_system.dart` - UPDATED (now delegates to AudioManager)
3. `lib/systems/combat_system.dart` - UPDATED (added manual execution methods, removed audio)
4. `lib/systems/combat_action_queue.dart` - NEW (future use)
5. `lib/ui/battle/battle_screen.dart` - UPDATED (complete timing refactor)

## Testing Notes

The app builds successfully with `flutter build apk --debug`.
Analyzer shows only info-level warnings (avoid_print, deprecated members).
No breaking changes to game balance or UI layout.
