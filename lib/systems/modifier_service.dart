import 'package:flutter/foundation.dart';

import '../domain/element.dart';
import '../progression/node_modifier.dart';

/// Phase 7.9.3: Source tags for modifier application order.
enum ModifierSource {
  /// Base stats from mage template.
  base,

  /// Skill tree bonuses from elemental paths.
  skillTree,

  /// Temporary combat modifiers (buffs, status effects).
  combat,
}

/// Service for aggregating and applying elemental node modifiers to combat.
///
/// Phase 7.8: Integrates character progression bonuses/tradeoffs into gameplay.
/// Phase 7.9.3: Enforces canonical application order:
///   1. Base stats (from mage definition)
///   2. Skill tree bonuses (from elemental nodes)
///   3. Combat modifiers (temporary buffs)
class ModifierService {
  ModifierService._();

  /// Phase 7.9.3: Canonical application order.
  static const List<ModifierSource> applicationOrder = [
    ModifierSource.base,
    ModifierSource.skillTree,
    ModifierSource.combat,
  ];

  /// Phase 7.9.3: Dev-only log of applied modifiers for auditing.
  static final List<ModifierApplicationLog> _applicationLog = [];

  /// Get the application log.
  static List<ModifierApplicationLog> get applicationLog =>
      List.unmodifiable(_applicationLog);

  /// Clears the application log.
  static void clearLog() {
    _applicationLog.clear();
  }

  /// Phase 7.9.3: Applies modifiers in canonical order and logs the result.
  ///
  /// [baseValue] - The starting value before any modifiers.
  /// [modifiers] - Skill tree modifiers to apply.
  /// [combatModifier] - Optional temporary combat modifier.
  /// [statName] - Name of the stat for logging.
  ///
  /// Returns the final value after all modifiers.
  static double applyInOrder({
    required double baseValue,
    required List<NodeModifier> modifiers,
    double combatModifier = 0.0,
    required String statName,
  }) {
    double value = baseValue;

    // Log base
    _logApplication(statName, ModifierSource.base, baseValue, value);

    // Apply skill tree modifiers
    for (final mod in modifiers) {
      value += mod.effectiveValue;
      if (kDebugMode && mod.effectiveValue != 0) {
        _logApplication(
          statName,
          ModifierSource.skillTree,
          mod.effectiveValue.toDouble(),
          value,
          modifierName: mod.description,
        );
      }
    }

    // Apply combat modifiers
    if (combatModifier != 0.0) {
      value += combatModifier;
      _logApplication(statName, ModifierSource.combat, combatModifier, value);
    }

    return value;
  }

  /// Phase 7.9.3: Logs a modifier application for debugging.
  static void _logApplication(
    String statName,
    ModifierSource source,
    double delta,
    double newValue, {
    String? modifierName,
  }) {
    if (!kDebugMode) return;

    _applicationLog.add(
      ModifierApplicationLog(
        statName: statName,
        source: source,
        delta: delta,
        newValue: newValue,
        modifierName: modifierName,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Phase 7.9.3: Gets a debug summary of recent modifier applications.
  static String getDebugSummary() {
    final buffer = StringBuffer();
    buffer.writeln('=== MODIFIER APPLICATION LOG ===');
    buffer.writeln('Total applications: ${_applicationLog.length}');

    for (final log in _applicationLog.take(30)) {
      buffer.writeln(log.toString());
    }

    if (_applicationLog.length > 30) {
      buffer.writeln('... and ${_applicationLog.length - 30} more');
    }

    return buffer.toString();
  }

  /// Calculates aggregate damage multiplier from modifiers.
  /// [element] is the spell's element (for element-specific bonuses).
  /// Returns a multiplier (e.g., 1.15 for +15% damage).
  static double getDamageMultiplier(
    List<NodeModifier> modifiers, {
    Element? element,
    bool targetIsBurning = false,
  }) {
    double multiplier = 1.0;

    for (final mod in modifiers) {
      if (mod.type == ModifierType.damagePercent) {
        // Check if this modifier applies to this element
        if (mod.targetElement == null || mod.targetElement == element) {
          multiplier += mod.effectiveValue / 100.0;
        }
      }
    }

    return multiplier.clamp(0.1, 5.0); // Floor and ceiling for sanity
  }

  /// Gets max HP modifier as a multiplier (e.g., 0.95 for -5% HP).
  static double getMaxHPMultiplier(List<NodeModifier> modifiers) {
    double multiplier = 1.0;

    for (final mod in modifiers) {
      if (mod.type == ModifierType.maxHPPercent) {
        multiplier += mod.effectiveValue / 100.0;
      }
    }

    return multiplier.clamp(0.5, 2.0);
  }

  /// Gets flat armor bonus/penalty at battle start.
  static int getBattleStartArmor(List<NodeModifier> modifiers) {
    int armor = 0;

    for (final mod in modifiers) {
      if (mod.type == ModifierType.battleStartArmor ||
          mod.type == ModifierType.armorFlat) {
        armor += mod.effectiveValue;
      }
    }

    return armor.clamp(-50, 100);
  }

  /// Gets mana cost modifier for a spell of a given element.
  /// Returns the flat change (-1 = costs 1 less, +1 = costs 1 more).
  static int getManaCostModifier(
    List<NodeModifier> modifiers,
    Element element,
  ) {
    int modifier = 0;

    for (final mod in modifiers) {
      if (mod.type == ModifierType.manaCostFlat) {
        if (mod.targetElement == null) {
          // Applies to all elements
          modifier += mod.effectiveValue;
        } else if (mod.targetElement == element) {
          // Element-specific bonus
          modifier += mod.effectiveValue;
        }
      }
    }

    return modifier;
  }

  /// Gets healing multiplier.
  static double getHealingMultiplier(List<NodeModifier> modifiers) {
    double multiplier = 1.0;

    for (final mod in modifiers) {
      if (mod.type == ModifierType.healingPercent) {
        multiplier += mod.effectiveValue / 100.0;
      }
    }

    return multiplier.clamp(0.5, 2.0);
  }

  /// Gets shield value multiplier.
  static double getShieldMultiplier(List<NodeModifier> modifiers) {
    double multiplier = 1.0;

    for (final mod in modifiers) {
      if (mod.type == ModifierType.shieldPercent) {
        multiplier += mod.effectiveValue / 100.0;
      }
    }

    return multiplier.clamp(0.5, 2.0);
  }

  /// Gets burn duration modifier (flat turns).
  static int getBurnDurationModifier(List<NodeModifier> modifiers) {
    int modifier = 0;

    for (final mod in modifiers) {
      if (mod.type == ModifierType.burnDuration) {
        modifier += mod.effectiveValue;
      }
    }

    return modifier;
  }

  /// Gets crit chance modifier (percentage points).
  static int getCritChanceModifier(
    List<NodeModifier> modifiers, {
    Element? element,
  }) {
    int modifier = 0;

    for (final mod in modifiers) {
      if (mod.type == ModifierType.critChance) {
        if (mod.targetElement == null || mod.targetElement == element) {
          modifier += mod.effectiveValue;
        }
      }
    }

    return modifier.clamp(-50, 100);
  }

  /// Gets speed modifier (percentage).
  static double getSpeedMultiplier(List<NodeModifier> modifiers) {
    double multiplier = 1.0;

    for (final mod in modifiers) {
      if (mod.type == ModifierType.speedPercent) {
        multiplier += mod.effectiveValue / 100.0;
      }
    }

    return multiplier.clamp(0.5, 2.0);
  }

  /// Checks if player has the "evade first hit" modifier.
  static bool hasEvadeFirstHit(List<NodeModifier> modifiers) {
    return modifiers.any(
      (m) => m.type == ModifierType.evadeFirstHit && m.isPositive,
    );
  }

  /// Checks if player has the "survive lethal" modifier.
  static bool hasLethalSurvive(List<NodeModifier> modifiers) {
    return modifiers.any(
      (m) => m.type == ModifierType.lethalSurvive && m.isPositive,
    );
  }

  /// Gets extra actions on kill count.
  static int getExtraActionsOnKill(List<NodeModifier> modifiers) {
    int count = 0;

    for (final mod in modifiers) {
      if (mod.type == ModifierType.extraActionOnKill && mod.isPositive) {
        count += mod.value;
      }
    }

    return count;
  }

  /// Gets first turn draw bonus.
  static int getFirstTurnDrawBonus(List<NodeModifier> modifiers) {
    int bonus = 0;

    for (final mod in modifiers) {
      if (mod.type == ModifierType.firstTurnDraw) {
        bonus += mod.effectiveValue;
      }
    }

    return bonus;
  }

  /// Gets burn damage modifier (percentage).
  static double getBurnDamageMultiplier(List<NodeModifier> modifiers) {
    double multiplier = 1.0;

    for (final mod in modifiers) {
      if (mod.type == ModifierType.burnDamagePercent) {
        multiplier += mod.effectiveValue / 100.0;
      }
    }

    return multiplier.clamp(0.1, 5.0);
  }

  /// Checks if player has the "splash on burn" modifier.
  static bool hasSplashOnBurn(List<NodeModifier> modifiers) {
    return modifiers.any(
      (m) => m.type == ModifierType.splashOnBurn && m.isPositive,
    );
  }

  /// Creates a summary of active modifiers for display.
  static String getSummary(List<NodeModifier> modifiers) {
    if (modifiers.isEmpty) return 'No elemental bonuses active.';

    final buffer = StringBuffer();
    final benefits = modifiers.where((m) => m.isPositive).toList();
    final tradeoffs = modifiers.where((m) => !m.isPositive).toList();

    if (benefits.isNotEmpty) {
      buffer.writeln('✨ Bonuses:');
      for (final b in benefits) {
        buffer.writeln('  • ${b.description}');
      }
    }

    if (tradeoffs.isNotEmpty) {
      buffer.writeln('⚠️ Tradeoffs:');
      for (final t in tradeoffs) {
        buffer.writeln('  • ${t.description}');
      }
    }

    return buffer.toString();
  }
}

/// Phase 7.9.3: Log entry for a modifier application.
class ModifierApplicationLog {
  final String statName;
  final ModifierSource source;
  final double delta;
  final double newValue;
  final String? modifierName;
  final DateTime timestamp;

  ModifierApplicationLog({
    required this.statName,
    required this.source,
    required this.delta,
    required this.newValue,
    this.modifierName,
    required this.timestamp,
  });

  @override
  String toString() {
    final sign = delta >= 0 ? '+' : '';
    final name = modifierName != null ? ' ($modifierName)' : '';
    return '[$statName] ${source.name}: $sign$delta = $newValue$name';
  }
}
