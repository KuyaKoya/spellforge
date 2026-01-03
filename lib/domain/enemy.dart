import 'effect.dart';
import 'element.dart';
import 'status_effect.dart';
import 'status_effect_manager.dart';

/// Enemy intent types - simple enum as per specification.
enum EnemyIntent {
  attack,
  defend,
  debuff;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }

  String get description {
    switch (this) {
      case EnemyIntent.attack:
        return 'Intends to attack';
      case EnemyIntent.defend:
        return 'Intends to defend';
      case EnemyIntent.debuff:
        return 'Intends to debuff';
    }
  }

  /// A2.3: Vague intent description for strategic planning without exact numbers.
  /// Examples: "Preparing a heavy attack", "Gathering energy", "Defensive stance"
  String get vagueDescription {
    switch (this) {
      case EnemyIntent.attack:
        return 'Preparing to strike';
      case EnemyIntent.defend:
        return 'Defensive stance';
      case EnemyIntent.debuff:
        return 'Gathering dark energy';
    }
  }

  /// Intent icon for UI display.
  String get icon {
    switch (this) {
      case EnemyIntent.attack:
        return '⚔️';
      case EnemyIntent.defend:
        return '🛡️';
      case EnemyIntent.debuff:
        return '💀';
    }
  }
}

/// Represents an enemy in combat.
/// Enemies act once per turn and do not upgrade.
class Enemy {
  final String id;
  final String name;
  final Element element;
  int currentHP;
  final int maxHP;
  final int attackDamage;
  final int armorGain;
  EnemyIntent intent;
  final List<ActiveStatusEffect> statusEffects; // Legacy
  late final StatusEffectManager statusManager; // Phase 7.2
  bool isDelayed;

  Enemy({
    required this.id,
    required this.name,
    required this.element,
    required this.currentHP,
    required this.maxHP,
    required this.attackDamage,
    this.armorGain = 5,
    this.intent = EnemyIntent.attack,
    List<ActiveStatusEffect>? statusEffects,
    this.isDelayed = false,
  }) : statusEffects = statusEffects ?? [] {
    statusManager = StatusEffectManager(ownerName: name);
  }

  /// Whether the enemy is alive.
  bool get isAlive => currentHP > 0;

  /// HP display string.
  String get hpDisplay => '$currentHP/$maxHP HP';

  /// Full status display.
  String get statusDisplay {
    final parts = <String>[
      '$name [${element.displayName}]',
      hpDisplay,
      'Intent: ${intent.displayName}',
    ];

    if (statusEffects.isNotEmpty) {
      parts.add(
        'Effects: ${statusEffects.map((e) => e.displayText).join(', ')}',
      );
    }

    if (isDelayed) {
      parts.add('(Delayed)');
    }

    return parts.join(' | ');
  }

  /// Takes damage, returning actual damage taken.
  int takeDamage(int damage) {
    // Check for armor
    int remainingDamage = damage;
    final armorEffects = statusEffects
        .where((e) => e.type == EffectType.armor)
        .toList();

    for (final armor in armorEffects) {
      if (remainingDamage <= 0) break;
      final absorbed = remainingDamage.clamp(0, armor.value);
      armor.remainingDuration--;
      remainingDamage -= absorbed;
      if (armor.remainingDuration <= 0) {
        statusEffects.remove(armor);
      }
    }

    final actualDamage = remainingDamage.clamp(0, currentHP);
    currentHP -= actualDamage;
    return actualDamage;
  }

  /// Takes burn damage (ignores shields per C1 spec).
  int takeBurnDamage(int damage) {
    final actualDamage = damage.clamp(0, currentHP);
    currentHP -= actualDamage;
    return actualDamage;
  }

  /// Applies a status effect.
  void applyStatusEffect(Effect effect) {
    if (!effect.isStatusEffect) return;

    if (effect.type == EffectType.delay) {
      isDelayed = true;
      return;
    }

    statusEffects.add(
      ActiveStatusEffect(
        type: effect.type,
        value: effect.value,
        remainingDuration: effect.duration,
      ),
    );
  }

  /// Applies a new-style status effect.
  String? applyNewStatusEffect(StatusEffect effect) {
    return statusManager.applyEffect(effect);
  }

  /// Processes status effects at turn boundary. Returns log messages.
  /// Legacy method - also processes new system effects.
  List<String> processStatusEffects() {
    final logs = <String>[];

    // Phase 7.2: Process new status effects
    final turnStartResults = statusManager.processTurnStart();
    for (final result in turnStartResults) {
      if (result.damage > 0) {
        // C1 Spec: Burn ignores shields
        final actualDamage = takeBurnDamage(result.damage);
        logs.add('$name takes $actualDamage burn damage');
      }
      if (result.healing > 0) {
        currentHP = (currentHP + result.healing).clamp(0, maxHP);
        logs.add('$name regenerates ${result.healing} HP');
      }
    }

    // Process turn end for new effects
    final expiredMessages = statusManager.processTurnEnd();
    logs.addAll(expiredMessages);

    // Legacy: Process old status effects for compatibility
    for (final effect in List.from(statusEffects)) {
      switch (effect.type) {
        case EffectType.burn:
          final damage = takeBurnDamage(effect.value);
          logs.add('$name takes $damage burn damage');
          break;
        default:
          break;
      }

      if (!effect.tick()) {
        statusEffects.remove(effect);
        logs.add('${effect.type.displayName} wore off from $name');
      }
    }

    // Reset delay
    if (isDelayed) {
      isDelayed = false;
      logs.add('$name is no longer delayed');
    }

    return logs;
  }

  /// Chooses next intent (simple rotation for prototype).
  void chooseNextIntent() {
    // Simple pattern: mostly attack, sometimes defend or debuff
    final roll = DateTime.now().millisecondsSinceEpoch % 10;
    if (roll < 6) {
      intent = EnemyIntent.attack;
    } else if (roll < 8) {
      intent = EnemyIntent.defend;
    } else {
      intent = EnemyIntent.debuff;
    }
  }

  /// Gets the damage output (affected by weaken).
  int getEffectiveDamage() {
    int damage = attackDamage;

    for (final effect in statusEffects) {
      if (effect.type == EffectType.weaken) {
        damage = (damage * (100 - effect.value) / 100).round();
      }
    }

    return damage.clamp(0, 999);
  }

  /// Creates a copy of this enemy.
  Enemy copy() {
    return Enemy(
      id: id,
      name: name,
      element: element,
      currentHP: currentHP,
      maxHP: maxHP,
      attackDamage: attackDamage,
      armorGain: armorGain,
      intent: intent,
    );
  }

  @override
  String toString() => '$name (${element.displayName})';
}
