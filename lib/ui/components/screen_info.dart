import 'package:flutter/material.dart';
import '../../game/game_state.dart';

/// Maps GameScreen enum to display properties.
class ScreenInfo {
  final String name;
  final Color color;

  const ScreenInfo(this.name, this.color);

  /// Gets screen info for a given GameScreen.
  static ScreenInfo forScreen(GameScreen screen) {
    switch (screen) {
      case GameScreen.mainMenu:
        return ScreenInfo('MENU', Colors.grey.shade700);
      case GameScreen.mageSelect:
        return ScreenInfo('SELECT MAGE', Colors.purple);
      case GameScreen.nodeMap:
        return ScreenInfo('NODE MAP', Colors.green);
      case GameScreen.nodeChoice:
        return ScreenInfo('CHOOSE PATH', Colors.blue);
      case GameScreen.exploration:
        return ScreenInfo('EXPLORATION', Colors.indigo);
      case GameScreen.combat:
        return ScreenInfo('COMBAT', Colors.red);
      case GameScreen.targetSelect:
        return ScreenInfo('SELECT TARGET', Colors.orange);
      case GameScreen.spellLearn:
        return ScreenInfo('LEARN SPELL', Colors.blue);
      case GameScreen.enhancementShrine:
        return ScreenInfo('ENHANCE', Colors.amber);
      case GameScreen.shop:
        return ScreenInfo('SHOP', Colors.green);
      case GameScreen.rest:
        return ScreenInfo('REST', Colors.teal);
      case GameScreen.elite:
        return ScreenInfo('ELITE', Colors.purple);
      case GameScreen.eliteReward:
        return ScreenInfo('ELITE REWARD', Colors.amber);
      case GameScreen.randomEvent:
        return ScreenInfo('RANDOM EVENT', Colors.purple);
      case GameScreen.spellSelect:
        return ScreenInfo('SELECT SPELL', Colors.purple);
      case GameScreen.runEnd:
        return ScreenInfo('RUN END', Colors.orange);
    }
  }

  /// Gets the color for a GameScreen.
  static Color colorFor(GameScreen screen) => forScreen(screen).color;

  /// Gets the display name for a GameScreen.
  static String nameFor(GameScreen screen) => forScreen(screen).name;
}
