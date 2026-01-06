import 'audio_manager.dart';

/// Manages audio playback for the game.
///
/// @deprecated Use [AudioManager] directly for new code.
/// This class is maintained for backward compatibility and delegates
/// to the AudioManager singleton.
class AudioSystem {
  /// Initialize audio system, preloading common sounds.
  static Future<void> initialize() async {
    await AudioManager.instance.initialize();
  }

  /// Play a sound effect by name.
  /// Automatically handles the 'sound_effects/' prefix and extension if needed.
  static void playSfx(String filename) {
    // Strip prefix and extension if present to get the key
    String key = filename;
    if (key.startsWith('sound_effects/')) {
      key = key.substring('sound_effects/'.length);
    }
    if (key.endsWith('.mp3')) {
      key = key.substring(0, key.length - 4);
    }
    AudioManager.instance.playSfx(key);
  }

  /// Plays background music in a loop.
  static void playMusic(String filename) {
    AudioManager.instance.playMusic(filename);
  }

  /// Plays the sound effect associated with a spell ID.
  static void playSpellSound(String spellId) {
    AudioManager.instance.playSpellSfx(spellId);
  }

  static void playEnemyDeath() {
    AudioManager.instance.playEnemyDeath();
  }

  static void playBossWin() {
    AudioManager.instance.playBattleWin();
  }

  static void playBattleDefeat() {
    AudioManager.instance.playPlayerDefeat();
  }

  static void playBuff() {
    AudioManager.instance.playShieldGain();
  }

  static void playDebuff() {
    AudioManager.instance.playDebuff();
  }

  static void playBurn() {
    AudioManager.instance.playBurn();
  }

  static void playEnemyAttack() {
    AudioManager.instance.playEnemyAttack();
  }

  static void playLevelUp() {
    AudioManager.instance.playLevelUp();
  }

  static void playSkillUnlock() {
    AudioManager.instance.playSkillUnlock();
  }

  /// Phase 7.8: Plays dodge/evade sound effect.
  static void playDodge() {
    // Use a whoosh/swift sound for dodging - reuse an existing wind-like effect
    AudioManager.instance.playSfx(
      'spell_cast',
    ); // Placeholder, could add dedicated sound
  }

  static void stopMusic() {
    AudioManager.instance.stopMusic();
  }
}
