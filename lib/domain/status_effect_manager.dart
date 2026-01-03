import 'status_effect.dart';

/// Manages status effects on a combatant.
///
/// Phase 7.2 B1 Spec: Turn Phase Breakdown
/// 1. Turn Start Effects
/// 2. Action Phase
/// 3. Turn End Effects
/// 4. Cleanup / Expiration
class StatusEffectManager {
  final List<StatusEffect> _effects = [];
  final String ownerName;

  StatusEffectManager({required this.ownerName});

  /// All active status effects.
  List<StatusEffect> get effects => List.unmodifiable(_effects);

  /// Active effects only.
  List<StatusEffect> get activeEffects =>
      _effects.where((e) => e.isActive).toList();

  /// Buffs only.
  List<StatusEffect> get buffs =>
      _effects.where((e) => e.category == StatusEffectCategory.buff).toList();

  /// Debuffs only.
  List<StatusEffect> get debuffs =>
      _effects.where((e) => e.category == StatusEffectCategory.debuff).toList();

  /// Whether any effects are active.
  bool get hasActiveEffects => _effects.any((e) => e.isActive);

  /// Whether the entity has a specific effect type.
  bool hasEffect(StatusEffectType type) =>
      _effects.any((e) => e.type == type && e.isActive);

  /// Gets the first effect of a specific type.
  StatusEffect? getEffect(StatusEffectType type) =>
      _effects.where((e) => e.type == type && e.isActive).firstOrNull;

  /// Gets all effects of a specific type.
  List<StatusEffect> getEffects(StatusEffectType type) =>
      _effects.where((e) => e.type == type && e.isActive).toList();

  /// Total shield value.
  int get totalShield {
    return _effects
        .where((e) => e.type == StatusEffectType.shield && e.isActive)
        .fold(0, (sum, e) => sum + e.value);
  }

  // ==================== LIFECYCLE: APPLY ====================

  /// Applies a new status effect.
  /// Handles stacking rules per E spec.
  String? applyEffect(StatusEffect effect) {
    // Check for existing effect of same type
    final existing = getEffect(effect.type);

    if (existing != null) {
      // Stacking rules from Part E
      switch (effect.type) {
        case StatusEffectType.burn:
          // Intensity + Duration stacking
          existing.addStacks(effect.stacks);
          existing.refreshDuration(effect.duration);
          return '$ownerName: Burn intensifies! (${existing.stacks} stacks)';

        case StatusEffectType.slow:
          // No stacking, refresh duration
          existing.refreshDuration(effect.duration);
          return null;

        case StatusEffectType.shield:
          // Numeric additive
          existing.value += effect.value;
          return '$ownerName gained ${effect.value} more shield! (Total: ${existing.value})';

        case StatusEffectType.weaken:
          // Duration only
          existing.refreshDuration(effect.duration);
          return null;

        default:
          // Default: refresh duration
          existing.refreshDuration(effect.duration);
          return null;
      }
    }

    // New effect
    _effects.add(effect);
    return effect.onApply(ownerName);
  }

  // ==================== LIFECYCLE: TURN START ====================

  /// Processes turn start effects.
  /// Returns list of results for UI display.
  List<TurnStartResult> processTurnStart() {
    final results = <TurnStartResult>[];

    for (final effect in activeEffects) {
      final result = effect.onTurnStart(ownerName);
      if (result != null) {
        results.add(
          TurnStartResult(
            effect: effect,
            damage: result.damage,
            healing: result.healing,
            message: result.message,
          ),
        );
      }
    }

    return results;
  }

  // ==================== LIFECYCLE: ACTION PHASE ====================

  /// Modifies outgoing damage based on status effects.
  int modifyOutgoingDamage(int baseDamage) {
    int modified = baseDamage;

    for (final effect in activeEffects) {
      modified = effect.modifyOutgoingDamage(modified);
    }

    return modified;
  }

  /// Modifies incoming damage based on status effects (vulnerable).
  /// Note: Shield absorption is handled separately.
  int modifyIncomingDamage(int baseDamage) {
    int modified = baseDamage;

    for (final effect in activeEffects) {
      modified = effect.modifyIncomingDamage(modified);
    }

    return modified;
  }

  /// Absorbs damage through shields.
  /// Returns (absorbed, remaining damage).
  DamageAbsorption absorbDamage(int incomingDamage) {
    int remaining = incomingDamage;
    int totalAbsorbed = 0;

    // C3 Spec: Shields absorb damage first
    final shields = getEffects(StatusEffectType.shield);
    for (final shield in shields) {
      if (remaining <= 0) break;

      final result = shield.absorbDamage(remaining);
      totalAbsorbed += result.absorbed;
      remaining = result.remaining;
    }

    // Also handle armor effects
    final armors = getEffects(StatusEffectType.armor);
    for (final armor in armors) {
      if (remaining <= 0) break;

      final result = armor.absorbDamage(remaining);
      totalAbsorbed += result.absorbed;
      remaining = result.remaining;
    }

    return DamageAbsorption(absorbed: totalAbsorbed, remaining: remaining);
  }

  /// Checks if entity is slowed.
  bool get isSlowed => hasEffect(StatusEffectType.slow);

  /// Gets priority modifier for turn order.
  /// C2 Spec: Slowed entities act after non-slowed entities.
  int get priorityModifier {
    if (isSlowed) return -1;
    if (hasEffect(StatusEffectType.haste)) return 1;
    return 0;
  }

  // ==================== LIFECYCLE: TURN END ====================

  /// Processes turn end effects.
  /// Returns list of expired effect messages.
  List<String> processTurnEnd() {
    final expiredMessages = <String>[];

    for (final effect in List.from(_effects)) {
      if (!effect.onTurnEnd()) {
        final message = effect.onExpire(ownerName);
        if (message != null) {
          expiredMessages.add(message);
        }
      }
    }

    // Cleanup expired effects
    _cleanup();

    return expiredMessages;
  }

  // ==================== LIFECYCLE: CLEANUP ====================

  /// Removes expired effects.
  void _cleanup() {
    _effects.removeWhere((e) => e.hasExpired);
  }

  /// Clears all effects (combat end).
  void clearAll() {
    _effects.clear();
  }

  /// Removes a specific effect.
  void removeEffect(StatusEffect effect) {
    _effects.remove(effect);
  }

  /// Removes all effects of a specific type.
  void removeEffectType(StatusEffectType type) {
    _effects.removeWhere((e) => e.type == type);
  }
}

/// Result of turn start processing.
class TurnStartResult {
  final StatusEffect effect;
  final int damage;
  final int healing;
  final String message;

  TurnStartResult({
    required this.effect,
    this.damage = 0,
    this.healing = 0,
    required this.message,
  });
}
