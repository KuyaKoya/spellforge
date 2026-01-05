---
description: Phase 7.6.2 Battle & Audio Execution Implementation
---

# SpellForge – Phase 7.6.2 Battle & Audio Execution Plan

## Implementation Status

### Implemented Audio Mapping

| Context | Audio File | Trigger Location | Status |
|---------|------------|------------------|--------|
| Start exploration | `base_select.mp3` | ElementSelectionOverlay - BEGIN button | ✅ |
| Element tap select | `base_select.mp3` | ElementSelectionOverlay - Icon tap | ✅ |
| Entering a room | `entering_a_room.mp3` | ExplorationScreenV2 - Room change | ✅ |
| Room overlay | `room_select.mp3` | ExplorationScreenV2 - Door tap | ✅ |
| Enemy select | `enemy_select.mp3` | ExplorationScreenV2 - Enemy tap | ✅ |
| Shop entrance | `shop_entrance.mp3` | ShopOverlay - initState | ✅ |
| Shop purchase | `shop_purchase.mp3` | ShopOverlay - _handlePurchase | ✅ |
| Shrine open | `enchantment_shrine_open.mp3` | SpellShrineOverlay & EnhancementShrineOverlay | ✅ |
| Shrine upgrade | `enchantment_shrine_upgrade.mp3` | SpellShrineOverlay & EnhancementShrineOverlay | ✅ |
| Mystery event | `mystery_event_bg_music.mp3` | RandomEventOverlay - enter/exit | ✅ |
| Battle start (normal) | `battle_start_normal.mp3` | AudioManager.playBattleStart | ✅ Ready |
| Battle start (elite) | `battle_start_elite.mp3` | AudioManager.playBattleStart | ✅ Ready |
| Boss music | `boss_bg_music.mp3` | AudioManager.playBattleStart(isBoss) | ✅ Ready |

### Implementation Details

#### 1. Audio Manager (`lib/systems/audio_manager.dart`)

- **Debounce Enabled:** Set `_sfxDebounceMs` to 50ms to prevent audio lag from rapid triggers.
- New SFX Keys: `sfxEnemySelect`, `sfxEnteringRoom`, `sfxRoomSelect` etc.

#### 2. Exploration Screen (`lib/ui/exploration/exploration_screen_v2.dart`)

- **Fade Animation:** Added logic to fade in the screen content (500ms ease-in) only when entering a new room.
- **Entering Sound:** Plays `entering_a_room.mp3` synced with the fade animation.
- **Enemy Select:** Plays `enemy_select.mp3` when clicking an enemy.
- **Room Select:** Plays `room_select.mp3` when clicking a door.

#### 3. Enhancement Shrine (`lib/ui/exploration/overlays/enhancement_shrine_overlay.dart`)

- Converted to `StatefulWidget`.
- Plays `enchantment_shrine_open.mp3` on open.
- Plays `enchantment_shrine_upgrade.mp3` on spell upgrade.

#### 4. Element Selection (`lib/ui/exploration/overlays/element_selection_overlay.dart`)

- Plays `base_select.mp3` when tapping an element icon.
- Plays `base_select.mp3` when clicking "BEGIN".

## Audio Asset Verification ✅

All audio files verified in `assets/audio/sound_effects/`:

- `enemy_select.mp3` ✓
- `entering_a_room.mp3` ✓
- `room_select.mp3` ✓
- `enchantment_shrine_open.mp3` ✓
- `enchantment_shrine_upgrade.mp3` ✓
- ...and all others previously verified.

## Testing Verification

```bash
dart analyze lib/...
# Result: Only info-level warnings (avoid_print). No errors.
```
