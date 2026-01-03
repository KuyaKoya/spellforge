import 'package:flutter/foundation.dart';
import '../domain/effect.dart';
import '../domain/mage.dart';
import '../domain/enemy.dart';
import '../domain/spell.dart';

/// Combat state guard system for A3.2 spec compliance.
/// Validates combat state and prevents invalid state mutations.
class CombatStateGuard {
  /// Validates that HP cannot go below 0.
  static int clampHP(int hp, {int min = 0, int? max}) {
    if (hp < min) {
      _logGuardViolation('HP below minimum', 'HP: $hp, expected >= $min');
      return min;
    }
    if (max != null && hp > max) {
      _logGuardViolation('HP above maximum', 'HP: $hp, expected <= $max');
      return max;
    }
    return hp;
  }

  /// Validates that MP/Mana cannot exceed max.
  static int clampMana(int mana, int maxMana) {
    if (mana < 0) {
      _logGuardViolation('Mana below zero', 'Mana: $mana');
      return 0;
    }
    if (mana > maxMana) {
      _logGuardViolation('Mana above maximum', 'Mana: $mana, max: $maxMana');
      return maxMana;
    }
    return mana;
  }

  /// Validates that a spell can be cast with current resources.
  static CastValidation validateSpellCast({
    required Mage mage,
    required Spell spell,
    required List<Enemy> enemies,
    int? targetIndex,
  }) {
    // Check if mage is alive
    if (!mage.isAlive) {
      return CastValidation.failed('Cannot cast: player is dead');
    }

    // Check mana
    if (mage.mana < spell.manaCost) {
      return CastValidation.failed(
        'Cannot cast ${spell.name}: insufficient mana '
        '(${mage.mana}/${spell.manaCost} required)',
      );
    }

    // Check actions
    if (mage.actionsRemaining <= 0) {
      return CastValidation.failed('Cannot cast: no actions remaining');
    }

    // Validate target if single-target spell
    if (spell.requiresTarget) {
      if (enemies.isEmpty) {
        return CastValidation.failed(
          'Cannot cast ${spell.name}: no valid targets',
        );
      }

      if (targetIndex != null) {
        if (targetIndex < 0 || targetIndex >= enemies.length) {
          return CastValidation.failed(
            'Cannot cast ${spell.name}: invalid target index',
          );
        }
        if (!enemies[targetIndex].isAlive) {
          return CastValidation.failed(
            'Cannot cast ${spell.name}: target is already dead',
          );
        }
      }
    }

    return CastValidation.success();
  }

  /// Validates that an enemy can act.
  static bool canEnemyAct(Enemy enemy) {
    if (!enemy.isAlive) {
      _logGuardViolation(
        'Dead enemy attempting action',
        'Enemy: ${enemy.name}',
      );
      return false;
    }
    return true;
  }

  /// Validates that player action is allowed in current phase.
  static bool canPlayerAct({
    required bool isPlayerTurn,
    required bool isAnimating,
    required bool combatOngoing,
  }) {
    if (!combatOngoing) {
      _logGuardViolation('Player action after combat ended', '');
      return false;
    }
    if (!isPlayerTurn) {
      _logGuardViolation('Player action during enemy turn', '');
      return false;
    }
    if (isAnimating) {
      _logGuardViolation('Player action during animation', '');
      return false;
    }
    return true;
  }

  /// Filters out dead enemies from a list.
  static List<Enemy> filterLivingEnemies(List<Enemy> enemies) {
    return enemies.where((e) => e.isAlive).toList();
  }

  /// Safely applies damage, respecting HP bounds.
  static int applyDamage({
    required int currentHP,
    required int damage,
    int minHP = 0,
  }) {
    final actualDamage = damage.clamp(0, currentHP - minHP);
    return (currentHP - actualDamage).clamp(minHP, currentHP);
  }

  /// Safely applies healing, respecting max HP.
  static int applyHealing({
    required int currentHP,
    required int maxHP,
    required int amount,
  }) {
    final actualHealing = amount.clamp(0, maxHP - currentHP);
    return (currentHP + actualHealing).clamp(0, maxHP);
  }

  /// Logs guard violations for debugging.
  static void _logGuardViolation(String violation, String details) {
    debugPrint('⚠️ COMBAT GUARD VIOLATION: $violation');
    if (details.isNotEmpty) {
      debugPrint('   Details: $details');
    }
  }
}

/// Result of spell cast validation.
class CastValidation {
  final bool isValid;
  final String? errorMessage;

  CastValidation._(this.isValid, this.errorMessage);

  factory CastValidation.success() => CastValidation._(true, null);
  factory CastValidation.failed(String message) =>
      CastValidation._(false, message);
}

/// Extension for Spell to check targeting requirements.
extension SpellTargeting on Spell {
  bool get requiresTarget {
    // A spell requires a target if any effect targets a single enemy
    return effects.any(
      (e) =>
          e.targetRule == TargetRule.single ||
          e.targetRule == TargetRule.random,
    );
  }
}
