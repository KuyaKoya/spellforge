import 'package:flame_audio/flame_audio.dart';

/// Music states for different game contexts.
enum MusicState { none, exploration, normalCombat, eliteCombat, bossCombat }

/// Centralized audio manager for sound effects and background music.
///
/// Responsibilities:
/// - Singleton pattern for global access
/// - Volume control for SFX and Music separately
/// - Prevents overlapping/duplicate playback
/// - Graceful handling of missing assets
/// - Music state transitions
class AudioManager {
  // Singleton instance
  static final AudioManager _instance = AudioManager._internal();
  static AudioManager get instance => _instance;
  factory AudioManager() => _instance;
  AudioManager._internal();

  // Volume settings (0.0 to 1.0)
  double _sfxVolume = 1.0;
  double _musicVolume = 0.7;

  // Track current music state to prevent redundant changes
  MusicState _currentMusicState = MusicState.none;
  String? _currentMusicTrack;

  // Debounce for SFX to prevent double-plays
  final Map<String, DateTime> _lastPlayedSfx = {};
  static const _sfxDebounceMs =
      50; // Debounce to prevent lag from rapid triggers

  // Initialization flag
  bool _initialized = false;

  // Common sound effect keys
  static const String sfxRoomEnter = 'room_enter';
  static const String sfxCombatStart = 'combat_start';
  static const String sfxSpellCast = 'spell_cast'; // Generic fallback
  static const String sfxDamage = 'damage';
  static const String sfxShieldGain = 'armor';
  static const String sfxBurn = 'burn';
  static const String sfxDebuff = 'debuff';
  static const String sfxEnemyAttack = 'enemy_attack';
  static const String sfxEnemyDeath = 'enemy_death';
  static const String sfxPlayerDefeat = 'battle_defeat';
  static const String sfxBattleWin = 'battle_win';

  // Phase 7.6.2: UI and non-combat SFX keys
  static const String sfxBaseSelect = 'base_select';
  static const String sfxShopEntrance = 'shop_entrance';
  static const String sfxShopPurchase = 'shop_purchase';
  static const String sfxShrineOpen = 'shrine_open';
  static const String sfxShrineUpgrade = 'shrine_upgrade';
  static const String sfxBattleStartNormal = 'battle_start_normal';
  static const String sfxBattleStartElite = 'battle_start_elite';
  static const String sfxEnteringRoom = 'entering_a_room';
  static const String sfxRoomSelect = 'room_select';
  static const String sfxEnemySelect = 'enemy_select';

  // Music track keys
  static const String musicExploration = 'exploration';
  static const String musicNormalCombat = 'normal_combat';
  static const String musicEliteCombat = 'elite_combat';
  static const String musicBossCombat = 'boss_combat';
  static const String musicMysteryEvent = 'mystery_event';

  /// Initialize the audio manager and preload common sounds.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Preload all sound effects
      await FlameAudio.audioCache.loadAll([
        'sound_effects/armor.mp3',
        'sound_effects/base_select.mp3',
        'sound_effects/battle_defeat.mp3',
        'sound_effects/battle_start_elite.mp3',
        'sound_effects/battle_start_normal.mp3',
        'sound_effects/battle_win.mp3',
        'sound_effects/blaze_strike.mp3',
        'sound_effects/boss_bg_music.mp3',
        'sound_effects/burn.mp3',
        'sound_effects/debuff.mp3',
        'sound_effects/earthquake.mp3',
        'sound_effects/enchantment_shrine_open.mp3',
        'sound_effects/enchantment_shrine_upgrade.mp3',
        'sound_effects/enemy_attack.mp3',
        'sound_effects/enemy_death.mp3',
        'sound_effects/enemy_select.mp3',
        'sound_effects/entering_a_room.mp3',
        'sound_effects/fireball.mp3',
        'sound_effects/gust.mp3',
        'sound_effects/hurricane.mp3',
        'sound_effects/inferno.mp3',
        'sound_effects/mystery_event_bg_music.mp3',
        'sound_effects/phoenix_flame.mp3',
        'sound_effects/rock_throw.mp3',
        'sound_effects/room_select.mp3',
        'sound_effects/shop_entrance.mp3',
        'sound_effects/shop_purchase.mp3',
        'sound_effects/tidal_wave.mp3',
        'sound_effects/typhoon.mp3',
        'sound_effects/water_bolt.mp3',
        'sound_effects/wind_slash.mp3',
      ]);
      _initialized = true;
    } catch (e) {
      // Log but don't crash - graceful degradation
      print('AudioManager: Failed to preload sounds: $e');
      _initialized = true; // Mark as initialized anyway to prevent retry loops
    }
  }

  /// Get current SFX volume.
  double get sfxVolume => _sfxVolume;

  /// Get current music volume.
  double get musicVolume => _musicVolume;

  /// Set sound effects volume (0.0 to 1.0).
  void setSfxVolume(double value) {
    _sfxVolume = value.clamp(0.0, 1.0);
  }

  /// Set music volume (0.0 to 1.0).
  void setMusicVolume(double value) {
    _musicVolume = value.clamp(0.0, 1.0);
    // Apply to currently playing music
    if (_currentMusicTrack != null) {
      try {
        FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
      } catch (e) {
        // Ignore volume setting errors
      }
    }
  }

  /// Stop all currently playing sound effects.
  /// Call this at the start of a new turn or action to prevent overlap.
  void stopAllSfx() {
    try {
      // Clear the audio cache to stop any playing sounds
      FlameAudio.audioCache.clearAll();
      _lastPlayedSfx.clear();
    } catch (e) {
      print('AudioManager: Failed to stop SFX: $e');
    }
  }

  /// Clear the SFX debounce queue without stopping sounds.
  /// Allows the same sound to be played again immediately.
  void clearSfxQueue() {
    _lastPlayedSfx.clear();
  }

  /// Play a sound effect by key.
  ///
  /// Keys are mapped to actual file paths internally.
  /// Duplicate/overlapping plays of the same sound are debounced.
  void playSfx(String key) {
    if (_sfxVolume <= 0) return;

    // Debounce check (disabled when _sfxDebounceMs = 0)
    if (_sfxDebounceMs > 0) {
      final now = DateTime.now();
      final lastPlayed = _lastPlayedSfx[key];
      if (lastPlayed != null &&
          now.difference(lastPlayed).inMilliseconds < _sfxDebounceMs) {
        return; // Skip duplicate play
      }
      _lastPlayedSfx[key] = now;
    }

    final filename = _getSfxFilename(key);
    if (filename == null) return;

    try {
      FlameAudio.play(filename, volume: _sfxVolume);
    } catch (e) {
      // Graceful failure - don't crash gameplay
      print('AudioManager: Failed to play SFX "$key": $e');
    }
  }

  /// Play a spell-specific sound effect.
  void playSpellSfx(String spellId) {
    final soundKey = _getSpellSoundKey(spellId);
    if (soundKey != null) {
      playSfx(soundKey);
    } else {
      // Fallback to generic spell cast
      playSfx(sfxSpellCast);
    }
  }

  /// Play background music for a given state.
  void playMusic(String key, {bool loop = true}) {
    if (_musicVolume <= 0) {
      stopMusic();
      return;
    }

    final filename = _getMusicFilename(key);
    if (filename == null) return;

    // Don't restart if already playing this track
    if (_currentMusicTrack == filename) return;

    try {
      FlameAudio.bgm.stop();
      FlameAudio.bgm.play(filename, volume: _musicVolume);
      _currentMusicTrack = filename;
    } catch (e) {
      print('AudioManager: Failed to play music "$key": $e');
    }
  }

  /// Transition music based on game state.
  void transitionToMusicState(MusicState newState) {
    if (_currentMusicState == newState) return;

    _currentMusicState = newState;

    switch (newState) {
      case MusicState.none:
        stopMusic();
        break;
      case MusicState.exploration:
        playMusic(musicExploration);
        break;
      case MusicState.normalCombat:
        playMusic(musicNormalCombat);
        break;
      case MusicState.eliteCombat:
        playMusic(musicEliteCombat);
        break;
      case MusicState.bossCombat:
        playMusic(musicBossCombat);
        break;
    }
  }

  /// Stop all background music.
  void stopMusic() {
    try {
      FlameAudio.bgm.stop();
      _currentMusicTrack = null;
    } catch (e) {
      print('AudioManager: Failed to stop music: $e');
    }
  }

  /// Pause background music (for menus, etc).
  void pauseMusic() {
    try {
      FlameAudio.bgm.pause();
    } catch (e) {
      // Ignore
    }
  }

  /// Resume background music.
  void resumeMusic() {
    try {
      FlameAudio.bgm.resume();
    } catch (e) {
      // Ignore
    }
  }

  // ==================== CONVENIENCE METHODS ====================

  /// Play room enter sound.
  void playRoomEnter() => playSfx(sfxRoomEnter);

  /// Play combat start sound.
  void playCombatStart() => playSfx(sfxCombatStart);

  /// Play damage dealt sound.
  void playDamage() => playSfx(sfxDamage);

  /// Play shield/armor gain sound.
  void playShieldGain() => playSfx(sfxShieldGain);

  /// Play burn tick sound.
  void playBurn() => playSfx(sfxBurn);

  /// Play debuff applied sound.
  void playDebuff() => playSfx(sfxDebuff);

  /// Play enemy attack sound.
  void playEnemyAttack() => playSfx(sfxEnemyAttack);

  /// Play enemy death sound.
  void playEnemyDeath() => playSfx(sfxEnemyDeath);

  /// Play player defeat sound.
  void playPlayerDefeat() => playSfx(sfxPlayerDefeat);

  /// Play battle win sound.
  void playBattleWin() => playSfx(sfxBattleWin);

  // ==================== PHASE 7.6.2: NON-COMBAT SOUNDS ====================

  /// Play base UI selection sound (start exploration, element selection).
  void playBaseSelect() => playSfx(sfxBaseSelect);

  /// Play room enter sound (entering a new room in exploration).
  void playEnteringRoom() => playSfx(sfxEnteringRoom);

  /// Play room select sound (room overlay/preview panels).
  void playRoomSelect() => playSfx(sfxRoomSelect);

  /// Play enemy select sound (selecting enemy in exploration).
  void playEnemySelect() => playSfx(sfxEnemySelect);

  /// Play shop entrance sound.
  void playShopEntrance() => playSfx(sfxShopEntrance);

  /// Play shop purchase sound.
  void playShopPurchase() => playSfx(sfxShopPurchase);

  /// Play enchantment shrine open sound.
  void playShrineOpen() => playSfx(sfxShrineOpen);

  /// Play enchantment shrine upgrade sound.
  void playShrineUpgrade() => playSfx(sfxShrineUpgrade);

  /// Play battle start sound based on encounter type.
  void playBattleStart({bool isElite = false, bool isBoss = false}) {
    if (isBoss) {
      // Boss: stop ambient music, start boss music
      stopMusic();
      playMusic(musicBossCombat);
    } else if (isElite) {
      playSfx(sfxBattleStartElite);
    } else {
      playSfx(sfxBattleStartNormal);
    }
  }

  /// Start mystery event background music.
  void playMysteryEventMusic() {
    playMusic(musicMysteryEvent);
  }

  /// Stop mystery event background music.
  void stopMysteryEventMusic() {
    stopMusic();
  }

  // ==================== INTERNAL MAPPINGS ====================

  /// Map SFX keys to actual filenames.
  String? _getSfxFilename(String key) {
    switch (key) {
      case sfxRoomEnter:
        return null; // TODO: Add room_enter.mp3 asset
      case sfxCombatStart:
        return null; // TODO: Add combat_start.mp3 asset
      case sfxDamage:
        return 'sound_effects/enemy_attack.mp3'; // Reuse for now
      case sfxShieldGain: // 'armor'
        return 'sound_effects/armor.mp3';
      case sfxBurn: // 'burn'
        return 'sound_effects/burn.mp3';
      case sfxDebuff: // 'debuff'
        return 'sound_effects/debuff.mp3';
      case sfxEnemyAttack: // 'enemy_attack'
        return 'sound_effects/enemy_attack.mp3';
      case sfxEnemyDeath: // 'enemy_death'
        return 'sound_effects/enemy_death.mp3';
      case sfxPlayerDefeat: // 'battle_defeat'
        return 'sound_effects/battle_defeat.mp3';
      case sfxBattleWin: // 'battle_win'
        return 'sound_effects/battle_win.mp3';
      // Spell sounds
      case 'fireball':
        return 'sound_effects/fireball.mp3';
      case 'inferno':
        return 'sound_effects/inferno.mp3';
      case 'blaze_strike':
        return 'sound_effects/blaze_strike.mp3';
      case 'water_bolt':
        return 'sound_effects/water_bolt.mp3';
      case 'tidal_wave':
        return 'sound_effects/tidal_wave.mp3';
      case 'rock_throw':
        return 'sound_effects/rock_throw.mp3';
      case 'earthquake':
        return 'sound_effects/earthquake.mp3';
      case 'wind_slash':
        return 'sound_effects/wind_slash.mp3';
      case 'gust':
        return 'sound_effects/gust.mp3';
      case 'hurricane':
        return 'sound_effects/hurricane.mp3';
      case 'phoenix_flame':
        return 'sound_effects/phoenix_flame.mp3';
      case 'typhoon':
        return 'sound_effects/typhoon.mp3';
      // Phase 7.6.2: UI and non-combat sounds
      case sfxBaseSelect: // 'base_select'
        return 'sound_effects/base_select.mp3';
      case sfxShopEntrance: // 'shop_entrance'
        return 'sound_effects/shop_entrance.mp3';
      case sfxShopPurchase: // 'shop_purchase'
        return 'sound_effects/shop_purchase.mp3';
      case sfxShrineOpen: // 'shrine_open'
        return 'sound_effects/enchantment_shrine_open.mp3';
      case sfxShrineUpgrade: // 'shrine_upgrade'
        return 'sound_effects/enchantment_shrine_upgrade.mp3';
      case sfxBattleStartNormal: // 'battle_start_normal'
        return 'sound_effects/battle_start_normal.mp3';
      case sfxBattleStartElite: // 'battle_start_elite'
        return 'sound_effects/battle_start_elite.mp3';
      case sfxEnteringRoom: // 'entering_a_room'
        return 'sound_effects/entering_a_room.mp3';
      case sfxRoomSelect: // 'room_select'
        return 'sound_effects/room_select.mp3';
      case sfxEnemySelect: // 'enemy_select'
        return 'sound_effects/enemy_select.mp3';
      default:
        return null;
    }
  }

  /// Map spell IDs to sound keys.
  String? _getSpellSoundKey(String spellId) {
    switch (spellId) {
      case 'fireball':
        return 'fireball';
      case 'inferno':
        return 'inferno';
      case 'blazeStrike':
        return 'blaze_strike';
      case 'waterBolt':
        return 'water_bolt';
      case 'tidalWave':
        return 'tidal_wave';
      case 'frostArmor':
        return 'armor';
      case 'rockThrow':
        return 'rock_throw';
      case 'earthquake':
        return 'earthquake';
      case 'stoneWall':
        return 'armor';
      case 'windSlash':
        return 'wind_slash';
      case 'gust':
        return 'gust';
      case 'hurricane':
        return 'hurricane';
      case 'phoenixFlame':
        return 'phoenix_flame';
      case 'typhoon':
        return 'typhoon';
      default:
        return null;
    }
  }

  /// Map music keys to actual filenames.
  String? _getMusicFilename(String key) {
    switch (key) {
      case 'main_bg': // Direct key used by AudioSystem.playMusic
      case musicExploration:
        return 'sound_effects/main_bg.mp3';
      case musicNormalCombat:
        return 'sound_effects/main_bg.mp3'; // Reuse main_bg for now
      case musicEliteCombat:
        return 'sound_effects/main_bg.mp3'; // Reuse main_bg for now
      case musicBossCombat:
        return 'sound_effects/boss_bg_music.mp3';
      case musicMysteryEvent:
        return 'sound_effects/mystery_event_bg_music.mp3';
      default:
        return null;
    }
  }
}
