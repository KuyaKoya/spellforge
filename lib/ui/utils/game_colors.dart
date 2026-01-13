import 'package:flutter/material.dart';
import '../../domain/element.dart' as game_element;
import '../../domain/spell.dart';

/// Global utility class for game-related colors.
/// Centralizes color definitions for elements and rarities across the UI.
class GameColors {
  GameColors._(); // Private constructor to prevent instantiation

  /// Returns the color associated with a spell rarity.
  static Color getRarityColor(SpellRarity rarity) {
    switch (rarity) {
      case SpellRarity.common:
        return Colors.grey.shade400;
      case SpellRarity.uncommon:
        return Colors.green;
      case SpellRarity.rare:
        return Colors.blue;
      case SpellRarity.signature:
        return Colors.amber;
      case SpellRarity.legendary:
        return const Color(0xFFbc8cff);
      case SpellRarity.fusion:
        return const Color(0xFF00d4aa);
    }
  }

  /// Returns the color associated with an integer rarity value.
  /// Used for items that use numeric rarity instead of SpellRarity enum.
  static Color getRarityColorFromInt(int rarity) {
    switch (rarity) {
      case 0:
        return Colors.grey.shade400;
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.amber;
      case 4:
        return const Color(0xFFbc8cff);
      case 5:
        return const Color(0xFF00d4aa);
      default:
        return Colors.grey.shade400;
    }
  }

  /// Returns the color associated with an element.
  static Color getElementColor(game_element.Element element) {
    switch (element) {
      case game_element.Element.fire:
        return Colors.orange;
      case game_element.Element.water:
        return Colors.blue;
      case game_element.Element.earth:
        return Colors.brown;
      case game_element.Element.air:
        return Colors.cyan;
    }
  }

  /// Returns the color associated with an element name string.
  /// Useful when working with element names directly.
  static Color getElementColorFromString(String elementName) {
    // Handle both "fire" and "Element.fire" formats
    final name = elementName.contains('.')
        ? elementName.split('.').last
        : elementName;

    switch (name.toLowerCase()) {
      case 'fire':
        return Colors.orange;
      case 'water':
        return Colors.blue;
      case 'earth':
        return Colors.brown;
      case 'air':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  /// Returns the color for a dynamic element type.
  /// Handles both Element enum and string representations.
  static Color getElementColorDynamic(dynamic element) {
    if (element is game_element.Element) {
      return getElementColor(element);
    }
    return getElementColorFromString(element.toString());
  }
}
