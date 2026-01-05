import 'package:flame_audio/flame_audio.dart';

/// Manages audio playback for the game.
class AudioSystem {
  /// Initialize audio system, preloading common sounds.
  static Future<void> initialize() async {
    // Preload common sounds
    await FlameAudio.audioCache.loadAll([
      'sound_effects/armor.mp3',
      'sound_effects/battle_defeat.mp3',
      'sound_effects/battle_win.mp3',
      'sound_effects/blaze_strike.mp3',
      'sound_effects/burn.mp3',
      'sound_effects/debuff.mp3',
      'sound_effects/earthquake.mp3',
      'sound_effects/enemy_attack.mp3',
      'sound_effects/enemy_death.mp3',
      'sound_effects/fireball.mp3',
      'sound_effects/gust.mp3',
      'sound_effects/hurricane.mp3',
      'sound_effects/inferno.mp3',
      'sound_effects/main_bg.mp3',
      'sound_effects/phoenix_flame.mp3',
      'sound_effects/rock_throw.mp3',
      'sound_effects/tidal_wave.mp3',
      'sound_effects/typhoon.mp3',
      'sound_effects/water_bolt.mp3',
      'sound_effects/wind_slash.mp3',
      // Note: 'main_bg.mp3' is large, stream it instead of preloading if possible,
      // but loadAll is fine for now for simplicity.
    ]);
  }

  /// Play a sound effect by name.
  /// Automatically handles the 'sound_effects/' prefix and extension if needed,
  /// but assumes full path relative to assets/ audio prefix (sound_effects/...)
  static void playSfx(String filename) {
    try {
      if (!filename.startsWith('sound_effects/')) {
        filename = 'sound_effects/$filename';
      }
      if (!filename.endsWith('.mp3')) {
        filename = '$filename.mp3';
      }
      FlameAudio.play(filename);
    } catch (e) {
      // Ignore audio errors (e.g. file not found) to prevent crash
      print('Error playing audio: $e');
    }
  }

  /// Plays background music in a loop.
  static void playMusic(String filename) {
    try {
      if (!filename.startsWith('sound_effects/')) {
        filename = 'sound_effects/$filename';
      }
      if (!filename.endsWith('.mp3')) {
        filename = '$filename.mp3';
      }
      // loop: true by default for music usually? check api.
      // FlameAudio.bgm.play(filename) is often used for music looping
      FlameAudio.bgm.play(filename);
    } catch (e) {
      print('Error playing music: $e');
    }
  }

  /// Plays the sound effect associated with a spell ID.
  static void playSpellSound(String spellId) {
    String? soundFile;
    switch (spellId) {
      case 'fireball':
        soundFile = 'fireball';
        break;
      case 'inferno':
        soundFile = 'inferno';
        break;
      case 'blazeStrike':
        soundFile = 'blaze_strike';
        break;
      case 'waterBolt':
        soundFile = 'water_bolt';
        break;
      case 'tidalWave':
        soundFile = 'tidal_wave';
        break;
      case 'frostArmor':
        soundFile = 'armor'; // reusing armor sound
        break;
      case 'rockThrow':
        soundFile = 'rock_throw';
        break;
      case 'earthquake':
        soundFile = 'earthquake';
        break;
      case 'stoneWall':
        soundFile = 'armor'; // reusing armor sound
        break;
      case 'windSlash':
        soundFile = 'wind_slash';
        break;
      case 'gust':
        soundFile = 'gust';
        break;
      case 'hurricane':
        soundFile = 'hurricane';
        break;
      case 'phoenixFlame':
        soundFile = 'phoenix_flame';
        break;
      case 'typhoon':
        soundFile = 'typhoon';
        break;
      default:
        // Default sounds by element if mapped, or just generic
        break;
    }

    if (soundFile != null) {
      playSfx(soundFile);
    }
  }

  static void playEnemyDeath() {
    playSfx('enemy_death');
  }

  static void playBossWin() {
    playSfx('battle_win');
  }

  static void playBattleDefeat() {
    playSfx('battle_defeat');
  }

  static void playBuff() {
    playSfx('armor'); // Use armor sound for generic buff/defense
  }

  static void playDebuff() {
    playSfx('debuff');
  }

  static void playBurn() {
    playSfx('burn');
  }

  static void playEnemyAttack() {
    playSfx('enemy_attack');
  }

  static void stopMusic() {
    FlameAudio.bgm.stop();
  }
}
