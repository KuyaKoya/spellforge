import 'package:flutter/foundation.dart';

import '../domain/spell.dart';
import '../domain/effect.dart';

/// Phase 7.9.3: Validates spell effects for correctness and serializability.
///
/// This validator ensures:
/// - Spell descriptions match actual effects
/// - Effects are serializable without data loss
class SpellEffectValidator {
  /// Singleton instance.
  static final SpellEffectValidator instance = SpellEffectValidator._();
  SpellEffectValidator._();

  /// Dev-only: Validation error log.
  final List<SpellValidationError> _errors = [];

  /// Get all validation errors.
  List<SpellValidationError> get errors => List.unmodifiable(_errors);

  /// Clears logged errors.
  void clearErrors() {
    _errors.clear();
  }

  /// Validates a spell's serialization round-trip.
  ///
  /// Returns true if the spell survives serialization without data loss.
  bool validateSerialization(Spell spell) {
    try {
      final json = spell.toJson();
      final restored = Spell.fromJson(json);

      // Check all fields match
      if (spell.id != restored.id) {
        _logError(spell, 'ID mismatch after deserialization');
        return false;
      }
      if (spell.name != restored.name) {
        _logError(spell, 'Name mismatch after deserialization');
        return false;
      }
      if (spell.element != restored.element) {
        _logError(spell, 'Element mismatch after deserialization');
        return false;
      }
      if (spell.starLevel != restored.starLevel) {
        _logError(spell, 'Star level mismatch after deserialization');
        return false;
      }
      if (spell.manaCost != restored.manaCost) {
        _logError(spell, 'Mana cost mismatch after deserialization');
        return false;
      }
      if (spell.effects.length != restored.effects.length) {
        _logError(spell, 'Effects count mismatch after deserialization');
        return false;
      }

      // Validate each effect
      for (int i = 0; i < spell.effects.length; i++) {
        if (!_effectsMatch(spell.effects[i], restored.effects[i])) {
          _logError(spell, 'Effect[$i] mismatch after deserialization');
          return false;
        }
      }

      return true;
    } catch (e) {
      _logError(spell, 'Serialization exception: $e');
      return false;
    }
  }

  /// Validates that a spell's baseDescription accurately reflects its effects.
  ///
  /// Returns a list of discrepancies found.
  List<String> validateDescriptionAccuracy(Spell spell) {
    final discrepancies = <String>[];
    final desc = spell.baseDescription.toLowerCase();

    for (final effect in spell.effects) {
      // Check damage effects mention damage
      if (effect.type == EffectType.damage) {
        if (!desc.contains('damage') &&
            !desc.contains('hit') &&
            !desc.contains('strike') &&
            !desc.contains('deal')) {
          discrepancies.add(
            'Spell deals ${effect.value} damage but description may not mention damage',
          );
        }
      }

      // Check status effects are mentioned
      if (effect.isStatusEffect) {
        final statusName = effect.type.displayName.toLowerCase();
        if (!desc.contains(statusName) && !desc.contains(effect.type.name)) {
          discrepancies.add(
            'Spell applies ${effect.type.displayName} but description may not mention it',
          );
        }
      }
    }

    return discrepancies;
  }

  /// Validates that spell effects have valid values.
  bool validateEffectValues(Spell spell) {
    for (final effect in spell.effects) {
      // Damage effects should have positive value
      if (effect.type == EffectType.damage && effect.value <= 0) {
        _logError(spell, 'Invalid damage value: ${effect.value}');
        return false;
      }

      // Status effects should have valid duration
      if (effect.isStatusEffect && effect.duration <= 0) {
        _logError(
          spell,
          'Status effect has invalid duration: ${effect.duration}',
        );
        return false;
      }
    }

    return true;
  }

  /// Compares two effects for equality.
  bool _effectsMatch(Effect a, Effect b) {
    return a.type == b.type &&
        a.value == b.value &&
        a.targetRule == b.targetRule &&
        a.duration == b.duration;
  }

  /// Logs a validation error.
  void _logError(Spell spell, String message) {
    final error = SpellValidationError(
      spellId: spell.id,
      spellName: spell.name,
      message: message,
      timestamp: DateTime.now(),
    );
    _errors.add(error);

    if (kDebugMode) {
      print('[SpellValidator] ERROR: ${spell.name} - $message');
    }
  }

  /// Gets a debug summary.
  String getDebugSummary() {
    final buffer = StringBuffer();
    buffer.writeln('=== SPELL VALIDATOR LOG ===');
    buffer.writeln('Total errors: ${_errors.length}');

    for (final error in _errors.take(20)) {
      buffer.writeln('${error.spellName}: ${error.message}');
    }

    return buffer.toString();
  }
}

/// Represents a spell validation error.
class SpellValidationError {
  final String spellId;
  final String spellName;
  final String message;
  final DateTime timestamp;

  SpellValidationError({
    required this.spellId,
    required this.spellName,
    required this.message,
    required this.timestamp,
  });

  @override
  String toString() => '[$spellName] $message';
}
