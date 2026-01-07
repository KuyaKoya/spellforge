import 'effect.dart';
import 'element.dart';

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

  /// Phase 7 - A2.3: Vague Enemy Intent
  ///
  /// Returns a vague description of the intent category.
  /// Purpose: Strategic planning without revealing exact moves.
  /// Avoids pure RNG frustration while maintaining mystery.
  String get vagueDescription {
    switch (this) {
      case EnemyIntent.attack:
        return 'Gathering energy...';
      case EnemyIntent.defend:
        return 'Takes a defensive stance';
      case EnemyIntent.debuff:
        return 'Dark energy swirls...';
    }
  }

  /// Icon representing the vague intent.
  String get vagueIcon {
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
  final List<ActiveStatusEffect> statusEffects;
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
  }) : statusEffects = statusEffects ?? [];

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

      // Calculate how much this armor stack can absorb
      final absorbed = remainingDamage.clamp(0, armor.value);

      // Reduce armor value
      armor.value -= absorbed;

      // Reduce remaining damage
      remainingDamage -= absorbed;

      // If armor is fully depleted, remove it
      if (armor.value <= 0) {
        statusEffects.remove(armor);
      }

      // Note: Do not decrement duration here
    }

    final actualDamage = remainingDamage.clamp(0, currentHP);
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

  /// Processes status effects at turn boundary. Returns log messages.
  List<String> processStatusEffects() {
    final logs = <String>[];

    for (final effect in List.from(statusEffects)) {
      switch (effect.type) {
        case EffectType.burn:
          final damage = takeDamage(effect.value);
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

  /// Converts to JSON for save/load serialization.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'element': element.name,
    'currentHP': currentHP,
    'maxHP': maxHP,
    'attackDamage': attackDamage,
    'armorGain': armorGain,
    'intent': intent.name,
    'statusEffects': statusEffects
        .map(
          (e) => {
            'type': e.type.name,
            'value': e.value,
            'remainingDuration': e.remainingDuration,
          },
        )
        .toList(),
    'isDelayed': isDelayed,
  };

  /// Creates from JSON for save/load serialization.
  factory Enemy.fromJson(Map<String, dynamic> json) {
    return Enemy(
      id: json['id'] as String,
      name: json['name'] as String,
      element: Element.values.firstWhere((e) => e.name == json['element']),
      currentHP: json['currentHP'] as int,
      maxHP: json['maxHP'] as int,
      attackDamage: json['attackDamage'] as int,
      armorGain: json['armorGain'] as int? ?? 5,
      intent: EnemyIntent.values.firstWhere((i) => i.name == json['intent']),
      statusEffects:
          (json['statusEffects'] as List?)
              ?.map(
                (e) => ActiveStatusEffect(
                  type: EffectType.values.firstWhere(
                    (t) => t.name == e['type'],
                  ),
                  value: e['value'] as int,
                  remainingDuration: e['remainingDuration'] as int,
                ),
              )
              .toList() ??
          [],
      isDelayed: json['isDelayed'] as bool? ?? false,
    );
  }

  @override
  String toString() => '$name (${element.displayName})';
}
