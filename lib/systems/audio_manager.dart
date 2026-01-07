import 'dart:async';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Music states for different game contexts.
enum MusicState {
  none,
  home,
  exploration,
  normalCombat,
  eliteCombat,
  bossCombat,
}

/// Centralized audio manager using flutter_soloud for low-latency playback.
///
/// Responsibilities:
/// - Singleton pattern for global access
/// - Volume control for SFX and Music separately
/// - Preloads all audio at startup
/// - Music fade transitions
/// - Music ducking for narrative moments
class AudioManager {
  // Singleton instance
  static final AudioManager _instance = AudioManager._internal();
  static AudioManager get instance => _instance;
  factory AudioManager() => _instance;
  AudioManager._internal();

  // SoLoud engine reference
  SoLoud get _soloud => SoLoud.instance;

  // Volume settings (0.0 to 1.0)
  double _sfxVolume = 1.0;
  double _musicVolume = 0.7;
  double _preDuckMusicVolume = 0.7;

  // Track current music state
  MusicState _currentMusicState = MusicState.none;
  String? _currentMusicKey;

  // Preloaded audio sources
  final Map<String, AudioSource> _sfxSources = {};
  final Map<String, AudioSource> _musicSources = {};

  // Current music handle for control
  SoundHandle? _currentMusicHandle;

  // Initialization flag
  bool _initialized = false;

  // Debounce for SFX to prevent double-plays
  final Map<String, DateTime> _lastPlayedSfx = {};
  static const _sfxDebounceMs = 50;

  // Music fade duration
  static const Duration _musicFadeDuration = Duration(milliseconds: 800);

  // ==================== SOUND EFFECT KEYS ====================
  // These must match actual file names in assets/audio/sound_effects/
  static const sfxSpellCast = 'fireball'; // Default spell sound
  static const sfxDamageDealt = 'enemy_attack'; // Reuse for damage
  static const sfxEnemyAttack = 'enemy_attack';
  static const sfxShieldGain = 'armor';
  static const sfxBurn = 'burn';
  static const sfxDebuff = 'debuff';
  static const sfxEnemyDeath = 'enemy_death';
  static const sfxBattleWin = 'battle_win';
  static const sfxPlayerDefeat = 'battle_defeat';
  static const sfxSpellForged = 'level_up'; // Reuse for spell forged
  static const sfxRoomSelect = 'room_select';
  static const sfxEnteringRoom = 'entering_a_room';
  static const sfxEnemySelect = 'enemy_select';
  static const sfxBaseSelect = 'base_select';
  static const sfxShopEntrance = 'shop_entrance';
  static const sfxShopPurchase = 'shop_purchase';
  static const sfxShrineOpen = 'enchantment_shrine_open';
  static const sfxShrineUpgrade = 'enchantment_shrine_upgrade';

  // ==================== MUSIC KEYS ====================
  static const musicHome = 'home';
  static const musicExploration = 'exploration';
  static const musicNormalCombat = 'normal_combat';
  static const musicEliteCombat = 'elite_combat';
  static const musicBossCombat = 'boss_combat';
  static const musicMysteryEvent = 'mystery_event';

  // ==================== INITIALIZATION ====================

  /// Initialize the audio manager and preload ALL audio assets.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      print('AudioManager: Initializing SoLoud engine...');

      // Initialize the SoLoud engine
      await _soloud.init();

      print('AudioManager: Preloading audio assets...');

      // Load persistent settings
      await _loadSettings();

      // Preload all SFX
      await _preloadSfx();

      // Preload all music
      await _preloadMusic();

      _initialized = true;
      print('AudioManager: Initialization complete!');
    } catch (e) {
      print('AudioManager: Initialization failed: $e');
    }
  }

  Future<void> _preloadSfx() async {
    // Actual sound files in assets/audio/sound_effects/
    final sfxFiles = [
      // Battle sounds
      'battle_win',
      'battle_defeat',
      'enemy_attack',
      'enemy_death',
      'elite_death',
      'boss_death',
      // Spell sounds
      'fireball',
      'blaze_strike',
      'inferno',
      'phoenix_flame',
      'water_bolt',
      'tidal_wave',
      'rock_throw',
      'earthquake',
      'wind_slash',
      'gust',
      'hurricane',
      'typhoon',
      // Status effects
      'armor',
      'burn',
      'debuff',
      // UI/Navigation sounds
      'room_select',
      'entering_a_room',
      'enemy_select',
      'base_select',
      'shop_entrance',
      'shop_purchase',
      'enchantment_shrine_open',
      'enchantment_shrine_upgrade',
      'level_up',
      'skill_tree_unlock',
    ];

    for (final name in sfxFiles) {
      try {
        final source = await _soloud.loadAsset(
          'assets/audio/sound_effects/$name.mp3',
        );
        _sfxSources[name] = source;
      } catch (e) {
        print('AudioManager: Failed to preload SFX "$name": $e');
      }
    }

    print('AudioManager: Preloaded ${_sfxSources.length} SFX files');
  }

  Future<void> _preloadMusic() async {
    final musicFiles = {
      'home': 'home.mp3',
      'exploration': 'exploration.mp3',
      'normal_combat': 'normal_combat.mp3',
      'elite_combat': 'elite_combat.mp3',
      'boss_combat': 'boss_combat.mp3',
      'mystery_event': 'mystery_event.mp3',
      'main_bg': 'home.mp3', // Alias for backwards compatibility
    };

    for (final entry in musicFiles.entries) {
      try {
        final source = await _soloud.loadAsset(
          'assets/audio/music/${entry.value}',
        );
        _musicSources[entry.key] = source;
      } catch (e) {
        print('AudioManager: Failed to preload music "${entry.key}": $e');
      }
    }

    print('AudioManager: Preloaded ${_musicSources.length} music files');
  }

  /// Convenience method to preload all audio (alias for initialize).
  Future<void> preloadAll() => initialize();

  // ==================== VOLUME CONTROL ====================

  double get sfxVolume => _sfxVolume;
  double get musicVolume => _musicVolume;

  /// Set sound effects volume (0.0 to 1.0).
  void setSfxVolume(double value) {
    _sfxVolume = value.clamp(0.0, 1.0);
    _saveSettings();
  }

  /// Set music volume (0.0 to 1.0).
  void setMusicVolume(double value) {
    _musicVolume = value.clamp(0.0, 1.0);

    // Update current music volume if playing
    if (_currentMusicHandle != null) {
      _soloud.setVolume(_currentMusicHandle!, _musicVolume);
    }
    _saveSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _sfxVolume = prefs.getDouble('sfx_volume') ?? 1.0;
    _musicVolume = prefs.getDouble('music_volume') ?? 0.7;
    _preDuckMusicVolume = _musicVolume;
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sfx_volume', _sfxVolume);
    await prefs.setDouble('music_volume', _musicVolume);
  }

  // ==================== SFX PLAYBACK ====================

  /// Play a sound effect by key.
  Future<void> playSfx(String key) async {
    if (_sfxVolume <= 0 || !_initialized) return;

    // Debounce check
    final now = DateTime.now();
    final lastPlayed = _lastPlayedSfx[key];
    if (lastPlayed != null &&
        now.difference(lastPlayed).inMilliseconds < _sfxDebounceMs) {
      return;
    }
    _lastPlayedSfx[key] = now;

    // Get preloaded source
    final source = _sfxSources[key];
    if (source == null) {
      print('AudioManager: SFX not found: $key');
      return;
    }

    try {
      await _soloud.play(source, volume: _sfxVolume);
    } catch (e) {
      print('AudioManager: Failed to play SFX "$key": $e');
    }
  }

  /// Plays a sound effect and returns a Future that completes when it finishes.
  Future<void> playSfxAndWait(String key) async {
    if (_sfxVolume <= 0 || !_initialized) return;

    final source = _sfxSources[key];
    if (source == null) {
      // Fallback delay to prevent logic skips
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }

    try {
      final handle = await _soloud.play(source, volume: _sfxVolume);

      // Wait for sound to complete
      // Use a completer that resolves when sound finishes
      final completer = Completer<void>();

      // Poll for completion (flutter_soloud doesn't have onComplete callback)
      Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (!_soloud.getIsValidVoiceHandle(handle)) {
          timer.cancel();
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      });

      // Timeout after 5 seconds max
      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {},
      );
    } catch (e) {
      print('AudioManager: playSfxAndWait failed for "$key": $e');
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  /// Stop all currently playing sound effects.
  void stopAllSfx() {
    // flutter_soloud doesn't have a "stop all SFX only" method
    // We'd need to track handles - for now this clears the debounce
    _lastPlayedSfx.clear();
  }

  /// Clear the SFX debounce queue.
  void clearSfxQueue() {
    _lastPlayedSfx.clear();
  }

  // ==================== MUSIC PLAYBACK ====================

  /// Play background music with fade-in.
  Future<void> playMusic(String key, {bool loop = true}) async {
    if (_musicVolume <= 0 || !_initialized) return;

    // Don't restart if already playing this track
    if (_currentMusicKey == key && _currentMusicHandle != null) {
      return;
    }

    final source = _musicSources[key];
    if (source == null) {
      print('AudioManager: Music not found: $key');
      return;
    }

    try {
      // Fade out current music if playing
      if (_currentMusicHandle != null) {
        await _fadeOutMusic();
      }

      // Start new music at volume 0 for fade-in
      _currentMusicHandle = await _soloud.play(
        source,
        volume: 0,
        looping: loop,
      );
      _currentMusicKey = key;

      // Fade in
      await _fadeInMusic();
    } catch (e) {
      print('AudioManager: Failed to play music "$key": $e');
    }
  }

  /// Fade out current music over duration.
  Future<void> _fadeOutMusic() async {
    if (_currentMusicHandle == null) return;

    final handle = _currentMusicHandle!;
    final steps = 20;
    final stepDuration = _musicFadeDuration.inMilliseconds ~/ steps;
    final volumeStep = _musicVolume / steps;

    for (int i = steps; i >= 0; i--) {
      if (!_soloud.getIsValidVoiceHandle(handle)) break;
      _soloud.setVolume(handle, volumeStep * i);
      await Future.delayed(Duration(milliseconds: stepDuration));
    }

    // Stop the old music
    await _soloud.stop(handle);
  }

  /// Fade in current music over duration.
  Future<void> _fadeInMusic() async {
    if (_currentMusicHandle == null) return;

    final handle = _currentMusicHandle!;
    final steps = 20;
    final stepDuration = _musicFadeDuration.inMilliseconds ~/ steps;
    final volumeStep = _musicVolume / steps;

    for (int i = 0; i <= steps; i++) {
      if (!_soloud.getIsValidVoiceHandle(handle)) break;
      _soloud.setVolume(handle, volumeStep * i);
      await Future.delayed(Duration(milliseconds: stepDuration));
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
      case MusicState.home:
        playMusic(musicHome);
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

  /// Stop all background music with fade-out.
  Future<void> stopMusic() async {
    if (_currentMusicHandle != null) {
      await _fadeOutMusic();
      _currentMusicHandle = null;
      _currentMusicKey = null;
    }
    _currentMusicState = MusicState.none;
  }

  /// Pause background music.
  void pauseMusic() {
    if (_currentMusicHandle != null) {
      _soloud.setPause(_currentMusicHandle!, true);
    }
  }

  /// Resume background music.
  void resumeMusic() {
    if (_currentMusicHandle != null) {
      _soloud.setPause(_currentMusicHandle!, false);
    }
  }

  // ==================== MUSIC DUCKING ====================

  /// Duck (reduce) background music volume for narrative moments.
  void duckBackgroundMusic() {
    if (_currentMusicHandle == null) return;

    _preDuckMusicVolume = _musicVolume;
    final duckedVolume = _musicVolume * 0.3;
    _soloud.setVolume(_currentMusicHandle!, duckedVolume);
  }

  /// Restore background music to original volume after ducking.
  void restoreBackgroundMusic() {
    if (_currentMusicHandle == null) return;

    _soloud.setVolume(_currentMusicHandle!, _preDuckMusicVolume);
  }

  // ==================== CONVENIENCE METHODS ====================

  void playRoomEnter() => playSfx(sfxEnteringRoom);
  void playEnteringRoom() => playSfx(sfxEnteringRoom);
  void playDamage() => playSfx(sfxDamageDealt);
  void playShieldGain() => playSfx(sfxShieldGain);
  void playBurn() => playSfx(sfxBurn);
  void playDebuff() => playSfx(sfxDebuff);
  void playEnemyDeath() => playSfx(sfxEnemyDeath);
  void playBattleWin() => playSfx(sfxBattleWin);
  void playPlayerDefeat() => playSfx(sfxPlayerDefeat);
  void playRoomSelect() => playSfx(sfxRoomSelect);
  void playEnemySelect() => playSfx(sfxEnemySelect);
  void playEnemyAttack() => playSfx(sfxEnemyAttack);
  void playShopEntrance() => playSfx(sfxShopEntrance);
  void playShrineOpen() => playSfx(sfxShrineOpen);
  void playShrineUpgrade() => playSfx(sfxShrineUpgrade);
  void playLevelUp() => playSfx('level_up');
  void playSkillUnlock() => playSfx('skill_unlock');

  /// Play spell-specific sound effect.
  void playSpellSfx(String spellId) {
    final key = _getSpellSoundKey(spellId);
    if (key != null) {
      playSfx(key);
    } else {
      playSfx(sfxSpellCast);
    }
  }

  /// Plays spell sound and waits for completion.
  Future<void> playSpellSfxAndWait(String spellId) async {
    final key = _getSpellSoundKey(spellId);
    await playSfxAndWait(key ?? sfxSpellCast);
  }

  /// Play battle start sound based on encounter type.
  /// Note: Battle start SFX assets were removed. This method is kept for API
  /// compatibility but now only transitions to combat music.
  void playBattleStart({bool isElite = false, bool isBoss = false}) {
    // Battle start SFX removed - music transition handles the feel
  }

  /// Play mystery event music.
  void playMysteryEventMusic() {
    playMusic(musicMysteryEvent);
  }

  /// Stop mystery event music (return to exploration music).
  void stopMysteryEventMusic() {
    transitionToMusicState(MusicState.exploration);
  }

  /// Play shop purchase sound.
  void playShopPurchase() => playSfx(sfxShopPurchase);

  /// Play base select sound.
  void playBaseSelect() => playSfx(sfxBaseSelect);

  String? _getSpellSoundKey(String spellId) {
    // Map spell IDs to actual sound file keys
    final spellSounds = {
      // Fire spells
      'fireball': 'fireball',
      'ember_burst': 'blaze_strike',
      'flame_wall': 'inferno',
      'inferno': 'inferno',
      'blaze_strike': 'blaze_strike',
      'phoenix_flame': 'phoenix_flame',
      // Water spells
      'water_bolt': 'water_bolt',
      'tidal_wave': 'tidal_wave',
      'frost_nova': 'water_bolt',
      'healing_rain': 'tidal_wave',
      // Earth spells
      'stone_spike': 'rock_throw',
      'rock_throw': 'rock_throw',
      'earthquake': 'earthquake',
      'iron_skin': 'armor',
      'crystal_armor': 'armor',
      // Air spells
      'wind_slash': 'wind_slash',
      'gust': 'gust',
      'hurricane': 'hurricane',
      'typhoon': 'typhoon',
      'lightning_bolt': 'wind_slash',
      'gale_force': 'hurricane',
      'static_field': 'gust',
    };
    return spellSounds[spellId.toLowerCase()];
  }

  // ==================== CLEANUP ====================

  /// Dispose of audio manager resources.
  Future<void> dispose() async {
    // Stop all playback
    if (_currentMusicHandle != null) {
      _soloud.stop(_currentMusicHandle!);
    }

    // Dispose all loaded sources
    for (final source in _sfxSources.values) {
      await _soloud.disposeSource(source);
    }
    _sfxSources.clear();

    for (final source in _musicSources.values) {
      await _soloud.disposeSource(source);
    }
    _musicSources.clear();

    // Deinitialize engine
    _soloud.deinit();
    _initialized = false;

    print('AudioManager: Disposed');
  }

  // ==================== DIAGNOSTICS ====================

  /// Run audio system diagnostics.
  void runDiagnostics() {
    print('\n========== AUDIO SYSTEM DIAGNOSTICS ==========');
    print('Engine: flutter_soloud (SoLoud C++)');
    print('Initialized: $_initialized');
    print('SFX Sources Loaded: ${_sfxSources.length}');
    print('Music Sources Loaded: ${_musicSources.length}');
    print('Current Music State: $_currentMusicState');
    print('Current Music Key: ${_currentMusicKey ?? "None"}');
    print('SFX Volume: ${(_sfxVolume * 100).toInt()}%');
    print('Music Volume: ${(_musicVolume * 100).toInt()}%');
    print('==============================================\n');
  }
}
