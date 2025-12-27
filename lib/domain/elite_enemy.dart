import 'element.dart';
import 'enemy.dart';

/// Modifiers that elite enemies can have.
enum EliteModifier {
  empowered, // Increased damage
  resistant, // Reduced damage from one element
  relentless, // Acts twice every X turns
  adaptive; // Gains resistance to repeated elements

  String get displayName {
    switch (this) {
      case EliteModifier.empowered:
        return 'Empowered';
      case EliteModifier.resistant:
        return 'Resistant';
      case EliteModifier.relentless:
        return 'Relentless';
      case EliteModifier.adaptive:
        return 'Adaptive';
    }
  }

  String get description {
    switch (this) {
      case EliteModifier.empowered:
        return 'Deals 50% more damage';
      case EliteModifier.resistant:
        return 'Takes 50% reduced damage from one element';
      case EliteModifier.relentless:
        return 'Acts twice every 3 turns';
      case EliteModifier.adaptive:
        return 'Gains resistance to repeated element attacks';
    }
  }

  String get icon {
    switch (this) {
      case EliteModifier.empowered:
        return '💪';
      case EliteModifier.resistant:
        return '🛡️';
      case EliteModifier.relentless:
        return '⚡';
      case EliteModifier.adaptive:
        return '🔄';
    }
  }
}

/// Represents an elite enemy with special modifiers and enhanced stats.
class EliteEnemy extends Enemy {
  final List<EliteModifier> modifiers;
  final Element? resistantElement;
  int _turnsSinceRelentless = 0;
  final Map<Element, int> _elementHitCount = {};

  EliteEnemy({
    required super.id,
    required super.name,
    required super.element,
    required super.currentHP,
    required super.maxHP,
    required super.attackDamage,
    super.armorGain = 5,
    super.intent = EnemyIntent.attack,
    required this.modifiers,
    this.resistantElement,
  });

  /// Whether this elite has a specific modifier.
  bool hasModifier(EliteModifier modifier) => modifiers.contains(modifier);

  /// Gets the damage output with elite modifiers.
  @override
  int getEffectiveDamage() {
    int damage = super.getEffectiveDamage();

    // Empowered: +50% damage
    if (hasModifier(EliteModifier.empowered)) {
      damage = (damage * 1.5).round();
    }

    return damage;
  }

  /// Calculates damage taken with elite modifiers.
  int calculateDamageTaken(int baseDamage, Element attackElement) {
    int damage = baseDamage;

    // Resistant: 50% reduction from specific element
    if (hasModifier(EliteModifier.resistant) &&
        resistantElement == attackElement) {
      damage = (damage * 0.5).round();
    }

    // Adaptive: Gain resistance based on hit count
    if (hasModifier(EliteModifier.adaptive)) {
      final hitCount = _elementHitCount[attackElement] ?? 0;
      if (hitCount > 0) {
        // 10% reduction per previous hit, max 50%
        final reduction = (hitCount * 0.1).clamp(0.0, 0.5);
        damage = (damage * (1.0 - reduction)).round();
      }
      _elementHitCount[attackElement] = hitCount + 1;
    }

    return damage.clamp(0, 999);
  }

  /// Takes damage with elite modifier considerations.
  int takeDamageWithElement(int damage, Element attackElement) {
    final adjustedDamage = calculateDamageTaken(damage, attackElement);
    return takeDamage(adjustedDamage);
  }

  /// Whether the elite can act twice this turn (Relentless).
  bool canActTwice() {
    if (!hasModifier(EliteModifier.relentless)) return false;

    _turnsSinceRelentless++;
    if (_turnsSinceRelentless >= 3) {
      _turnsSinceRelentless = 0;
      return true;
    }
    return false;
  }

  /// Gets all modifier display strings.
  List<String> get modifierDescriptions {
    final descriptions = <String>[];

    for (final modifier in modifiers) {
      String desc = '${modifier.icon} ${modifier.displayName}';
      if (modifier == EliteModifier.resistant && resistantElement != null) {
        desc += ' (${resistantElement!.displayName})';
      }
      descriptions.add(desc);
    }

    return descriptions;
  }

  @override
  String get statusDisplay {
    final base = super.statusDisplay;
    if (modifiers.isEmpty) return base;

    final modifierText = modifierDescriptions.join(', ');
    return '$base | Modifiers: $modifierText';
  }

  /// Creates a copy of this elite enemy.
  @override
  EliteEnemy copy() {
    return EliteEnemy(
      id: id,
      name: name,
      element: element,
      currentHP: currentHP,
      maxHP: maxHP,
      attackDamage: attackDamage,
      armorGain: armorGain,
      intent: intent,
      modifiers: List.from(modifiers),
      resistantElement: resistantElement,
    );
  }
}
