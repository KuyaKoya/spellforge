import '../domain/enemy.dart';
import '../domain/mage.dart';
import '../domain/spell.dart';

/// Combat state validation guards.
///
/// Phase 7 - A3.2: Combat State Guards
///
/// These guards ensure combat state consistency:
/// - HP cannot go below 0
/// - MP cannot exceed max
/// - Spells cannot be cast without resources
/// - Dead enemies cannot act
///
/// On validation failure:
/// - Logs error with context
/// - Returns safe default / skips action
/// - Never crashes combat
class CombatGuards {
  /// Validates and clamps HP to valid range [0, max].
  static int validateHP(int hp, int maxHP) {
    if (hp < 0) {
      _logError('HP below 0: $hp (clamped to 0)');
      return 0;
    }
    if (hp > maxHP) {
      _logError('HP above max: $hp > $maxHP (clamped to $maxHP)');
      return maxHP;
    }
    return hp;
  }

  /// Validates and clamps MP to valid range [0, max].
  static int validateMP(int mp, int maxMP) {
    if (mp < 0) {
      _logError('MP below 0: $mp (clamped to 0)');
      return 0;
    }
    if (mp > maxMP) {
      _logError('MP above max: $mp > $maxMP (clamped to $maxMP)');
      return maxMP;
    }
    return mp;
  }

  /// Validates damage value (must be non-negative).
  static int validateDamage(int damage) {
    if (damage < 0) {
      _logError('Negative damage attempted: $damage (clamped to 0)');
      return 0;
    }
    return damage;
  }

  /// Checks if a spell can be cast by the mage.
  ///
  /// Returns `null` if castable, or an error message if not.
  static String? canCastSpell(Mage mage, Spell spell) {
    if (!mage.isAlive) {
      return 'Mage is dead';
    }
    if (mage.actionsRemaining <= 0) {
      return 'No actions remaining';
    }
    if (mage.mana < spell.manaCost) {
      return 'Insufficient mana (${mage.mana}/${spell.manaCost})';
    }
    return null; // Castable
  }

  /// Checks if a spell at index can be cast.
  static String? canCastSpellByIndex(Mage mage, int spellIndex) {
    if (spellIndex < 0 || spellIndex >= mage.spellLoadout.length) {
      return 'Invalid spell index: $spellIndex';
    }
    return canCastSpell(mage, mage.spellLoadout[spellIndex]);
  }

  /// Checks if an enemy can act.
  static bool canEnemyAct(Enemy enemy) {
    if (!enemy.isAlive) {
      _logWarning('Dead enemy attempted to act: ${enemy.name}');
      return false;
    }
    if (enemy.isDelayed) {
      _logInfo('Delayed enemy skipping turn: ${enemy.name}');
      return false;
    }
    return true;
  }

  /// Checks if an enemy is a valid attack target.
  static bool isValidTarget(List<Enemy> enemies, int targetIndex) {
    if (targetIndex < 0 || targetIndex >= enemies.length) {
      _logError('Invalid target index: $targetIndex');
      return false;
    }
    if (!enemies[targetIndex].isAlive) {
      _logWarning('Target is already dead: ${enemies[targetIndex].name}');
      return false;
    }
    return true;
  }

  /// Validates combat can continue.
  ///
  /// Returns a [CombatEndReason] if combat should end, or null if continuing.
  static CombatEndReason? checkCombatEnd(Mage mage, List<Enemy> enemies) {
    if (!mage.isAlive) {
      return CombatEndReason.playerDefeated;
    }
    if (enemies.every((e) => !e.isAlive)) {
      return CombatEndReason.allEnemiesDefeated;
    }
    return null; // Combat continues
  }

  // ==================== LOGGING ====================

  static final List<CombatGuardLog> _logs = [];

  static void _logError(String message) {
    final entry = CombatGuardLog(
      level: LogLevel.error,
      message: message,
      timestamp: DateTime.now(),
    );
    _logs.add(entry);
    // ignore: avoid_print
    print('[CombatGuard ERROR] $message');
  }

  static void _logWarning(String message) {
    final entry = CombatGuardLog(
      level: LogLevel.warning,
      message: message,
      timestamp: DateTime.now(),
    );
    _logs.add(entry);
    // ignore: avoid_print
    print('[CombatGuard WARN] $message');
  }

  static void _logInfo(String message) {
    final entry = CombatGuardLog(
      level: LogLevel.info,
      message: message,
      timestamp: DateTime.now(),
    );
    _logs.add(entry);
  }

  /// Gets all guard logs.
  static List<CombatGuardLog> get logs => List.unmodifiable(_logs);

  /// Clears all guard logs (call at start of combat).
  static void clearLogs() => _logs.clear();
}

/// Reason for combat ending.
enum CombatEndReason { playerDefeated, allEnemiesDefeated }

/// Log level for guard messages.
enum LogLevel { info, warning, error }

/// A logged guard event.
class CombatGuardLog {
  final LogLevel level;
  final String message;
  final DateTime timestamp;

  const CombatGuardLog({
    required this.level,
    required this.message,
    required this.timestamp,
  });

  @override
  String toString() => '[$level] $message';
}
