import 'dart:math';
import 'effect.dart';
import 'element.dart';
import 'spell.dart';

/// Enemy intent types.
/// Enemy intent types.
enum EnemyIntent {
  attack,
  defend,
  debuff,
  spell; // Phase 7.9.5: Cast a spell

  String get displayName => name[0].toUpperCase() + name.substring(1);

  String get description {
    switch (this) {
      case EnemyIntent.attack:
        return 'Intends to attack';
      case EnemyIntent.defend:
        return 'Intends to defend';
      case EnemyIntent.debuff:
        return 'Intends to debuff';
      case EnemyIntent.spell:
        return 'Intends to cast a spell';
    }
  }

  String get vagueDescription {
    switch (this) {
      case EnemyIntent.attack:
        return 'Gathering energy...';
      case EnemyIntent.defend:
        return 'Takes a defensive stance';
      case EnemyIntent.debuff:
        return 'Dark energy swirls...';
      case EnemyIntent.spell:
        return 'Arcane power gathers...';
    }
  }

  String get vagueIcon {
    switch (this) {
      case EnemyIntent.attack:
        return '⚔️';
      case EnemyIntent.defend:
        return '🛡️';
      case EnemyIntent.debuff:
        return '💀';
      case EnemyIntent.spell:
        return '✨';
    }
  }
}

/// Phase 7.9.4: Enemy with Attack/Defense/Speed stats.
class Enemy {
  final String id;
  final String name;
  final Element element;
  int currentHP;
  final int maxHP;

  /// Phase 7.9.4: Combat stats
  final int attack; // Bonus damage on attacks
  final int defense; // Damage reduction
  final int speed; // Turn order determination

  /// Legacy field for backwards compatibility
  final int attackDamage;
  final int armorGain;
  EnemyIntent intent;
  final List<ActiveStatusEffect> statusEffects;
  bool isDelayed;

  /// Phase 7.9.5: Spell system for enemies
  final List<Spell> spellLoadout;
  int currentMana;
  final int maxMana;

  /// Phase 7.9.5: The spell to cast when intent is spell
  Spell? pendingSpell;

  Enemy({
    required this.id,
    required this.name,
    required this.element,
    required this.currentHP,
    required this.maxHP,
    required this.attackDamage,
    this.attack = 5,
    this.defense = 3,
    this.speed = 4,
    this.armorGain = 5,
    this.intent = EnemyIntent.attack,
    List<ActiveStatusEffect>? statusEffects,
    this.isDelayed = false,
    List<Spell>? spellLoadout,
    int? currentMana,
    int? maxMana,
    this.pendingSpell,
  }) : statusEffects = statusEffects ?? [],
       spellLoadout = spellLoadout ?? [],
       maxMana = maxMana ?? 0,
       currentMana = currentMana ?? (maxMana ?? 0);

  // ==================== EFFECTIVE SPEED (Pokémon-style) ====================
  /// Constants for speed calculation.
  static const int minSpeed = 1;
  static const int maxSpeedCap = 99;

  /// Calculates effective speed including temporary modifiers from status effects.
  ///
  /// Formula: BaseSpeed × (1 + sum of Haste%) × (1 - sum of Slow%)
  /// Clamped to [minSpeed, maxSpeedCap].
  int get effectiveSpeed {
    int base = speed;

    // Calculate cumulative speed modifiers
    double multiplier = 1.0;
    for (final effect in statusEffects) {
      if (effect.type == EffectType.haste) {
        multiplier += effect.value / 100.0;
      } else if (effect.type == EffectType.slow) {
        multiplier -= effect.value / 100.0;
      }
    }

    // Ensure multiplier doesn't go negative
    if (multiplier < 0.1) multiplier = 0.1;

    return (base * multiplier).round().clamp(minSpeed, maxSpeedCap);
  }

  /// Whether the enemy can act this turn (not incapacitated).
  /// Sleep and Freeze prevent actions.
  bool get canActThisTurn {
    if (statusEffects.any((e) => e.type == EffectType.sleep)) return false;
    if (statusEffects.any((e) => e.type == EffectType.freeze)) return false;
    return true;
  }

  bool get isAlive => currentHP > 0;
  String get hpDisplay => '$currentHP/$maxHP HP';
  String get statsDisplay => 'ATK:$attack DEF:$defense SPD:$speed';

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

  int takeDamage(int damage) {
    int remainingDamage = damage;
    final armorEffects = statusEffects
        .where((e) => e.type == EffectType.armor)
        .toList();

    for (final armor in armorEffects) {
      if (remainingDamage <= 0) break;
      final absorbed = remainingDamage.clamp(0, armor.value);
      armor.value -= absorbed;
      remainingDamage -= absorbed;
      if (armor.value <= 0) {
        statusEffects.remove(armor);
      }
    }

    final actualDamage = remainingDamage.clamp(0, currentHP);
    currentHP -= actualDamage;
    return actualDamage;
  }

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

  List<String> processStatusEffects() {
    final logs = <String>[];
    for (final effect in List.from(statusEffects)) {
      switch (effect.type) {
        case EffectType.burn:
          final damage = takeDamage(effect.value);
          logs.add('$name takes $damage burn damage');
          break;
        case EffectType.poison:
          final damage = takeDamage(effect.value);
          logs.add('$name takes $damage poison damage');
          break;
        case EffectType.sleep:
          logs.add('$name is fast asleep');
          break;
        case EffectType.freeze:
          logs.add('$name is frozen solid');
          break;
        default:
          break;
      }
      if (!effect.tick()) {
        statusEffects.remove(effect);
        logs.add('${effect.type.displayName} wore off from $name');
      }
    }
    if (isDelayed) {
      isDelayed = false;
      logs.add('$name is no longer delayed');
    }
    return logs;
  }

  void chooseNextIntent() {
    final roll = DateTime.now().millisecondsSinceEpoch % 100;

    // Phase 7.9.5: Enemies act more like mages now
    // If has spells and mana, 70% chance to cast spell (was 20%)
    if (spellLoadout.isNotEmpty && canCastAnySpell) {
      if (roll < 70) {
        intent = EnemyIntent.spell;
        pendingSpell = getAffordableSpell();
        return;
      }
    }

    // Fallback distribution for remaining 30% or if no casting possible
    // Normalized roll for remaining range
    final actionRoll = roll % 30;

    if (actionRoll < 15) {
      intent = EnemyIntent.attack;
    } else if (actionRoll < 25) {
      intent = EnemyIntent.defend;
    } else {
      intent = EnemyIntent.debuff;
    }
  }

  /// Phase 7.9.5: Check if enemy can cast any spell
  bool get canCastAnySpell =>
      spellLoadout.any((s) => s.manaCost <= currentMana);

  /// Phase 7.9.5: Get an affordable spell to cast
  Spell? getAffordableSpell() {
    final affordable = spellLoadout
        .where((s) => s.manaCost <= currentMana)
        .toList();
    if (affordable.isEmpty) return null;
    // Pick randomly
    affordable.shuffle();
    return affordable.first;
  }

  /// Phase 7.9.5: Consume mana for a spell cast
  void consumeMana(int amount) {
    currentMana = (currentMana - amount).clamp(0, maxMana);
  }

  /// Phase 7.9.5: Restore mana (e.g., at turn start)
  void restoreMana(int amount) {
    currentMana = (currentMana + amount).clamp(0, maxMana);
  }

  /// Phase 7.9.4: Effective damage includes attack stat bonus.
  int getEffectiveDamage() {
    // Base damage from attackDamage + attack stat bonus
    int damage = attackDamage + (attack * 0.5).round();

    for (final effect in statusEffects) {
      if (effect.type == EffectType.weaken) {
        damage = (damage * (100 - effect.value) / 100).round();
      }
    }

    return max(1, damage);
  }

  Enemy copy() {
    return Enemy(
      id: id,
      name: name,
      element: element,
      currentHP: currentHP,
      maxHP: maxHP,
      attackDamage: attackDamage,
      attack: attack,
      defense: defense,
      speed: speed,
      armorGain: armorGain,
      intent: intent,
      spellLoadout: List.from(spellLoadout),
      currentMana: currentMana,
      maxMana: maxMana,
      pendingSpell: pendingSpell,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'element': element.name,
    'currentHP': currentHP,
    'maxHP': maxHP,
    'attackDamage': attackDamage,
    'attack': attack,
    'defense': defense,
    'speed': speed,
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
    'spellLoadout': spellLoadout.map((s) => s.toJson()).toList(),
    'currentMana': currentMana,
    'maxMana': maxMana,
  };

  factory Enemy.fromJson(Map<String, dynamic> json) {
    return Enemy(
      id: json['id'] as String,
      name: json['name'] as String,
      element: Element.values.firstWhere((e) => e.name == json['element']),
      currentHP: json['currentHP'] as int,
      maxHP: json['maxHP'] as int,
      attackDamage: json['attackDamage'] as int,
      attack: json['attack'] as int? ?? 5,
      defense: json['defense'] as int? ?? 3,
      speed: json['speed'] as int? ?? 4,
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
      spellLoadout:
          (json['spellLoadout'] as List?)
              ?.map((s) => Spell.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      currentMana: json['currentMana'] as int? ?? 0,
      maxMana: json['maxMana'] as int? ?? 0,
    );
  }

  @override
  String toString() => '$name (${element.displayName})';
}
