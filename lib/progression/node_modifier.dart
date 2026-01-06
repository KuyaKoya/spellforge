import '../domain/element.dart';

/// Types of modifiers that elemental nodes can provide.
enum ModifierType {
  // Damage modifiers
  damagePercent, // +X% damage (general or element-specific)
  // Defense modifiers
  maxHPPercent, // +X% max HP
  armorFlat, // +X armor at battle start
  // Mana modifiers
  manaCostFlat, // +X or -X mana cost for spells
  // Status effect modifiers
  burnDuration, // Burn lasts +X turns
  burnDamagePercent, // Burn damage +X%
  slowDuration, // Slow lasts +X turns
  // Healing & Shield modifiers
  healingPercent, // Healing effects +X%
  shieldPercent, // Shield values +X%
  shieldDecay, // Shield decay rate modifier
  // Speed & Action modifiers
  speedPercent, // +X% speed
  battleStartArmor, // Armor at battle start
  firstTurnDraw, // Extra cards first turn
  maxHand, // Max hand size modifier
  // Critical modifiers
  critChance, // +X% crit chance
  critDamage, // +X% crit damage
  // Resistance modifiers
  resistancePercent, // Resistance to element
  // Special/Passive modifiers
  splashOnBurn, // Burn stacks deal splash
  burnIgnoresShield, // Burn bypasses shields
  actFirst, // Act first if favored
  evadeFirstHit, // Evade first hit
  extraActionOnKill, // Extra action on kill
  lethalSurvive, // Survive first lethal at 1 HP
  enemyActSecond, // First enemy always acts second
  // All-turn modifiers
  armorPerTurn, // Gain armor each turn
  shieldPersist, // Shields persist between rooms
}

/// Represents a single modifier from an elemental node.
/// Can be either a benefit or a tradeoff.
class NodeModifier {
  /// The type of modifier.
  final ModifierType type;

  /// The value of the modifier (percentage or flat number).
  final int value;

  /// Optional element this modifier applies to (null = all elements).
  final Element? targetElement;

  /// Whether this is a positive effect (benefit) or negative (tradeoff).
  final bool isPositive;

  /// Human-readable description of this modifier.
  final String description;

  const NodeModifier({
    required this.type,
    required this.value,
    this.targetElement,
    required this.isPositive,
    required this.description,
  });

  /// Creates a benefit modifier (positive effect).
  factory NodeModifier.benefit({
    required ModifierType type,
    required int value,
    Element? targetElement,
    required String description,
  }) {
    return NodeModifier(
      type: type,
      value: value.abs(),
      targetElement: targetElement,
      isPositive: true,
      description: description,
    );
  }

  /// Creates a tradeoff modifier (negative effect).
  factory NodeModifier.tradeoff({
    required ModifierType type,
    required int value,
    Element? targetElement,
    required String description,
  }) {
    return NodeModifier(
      type: type,
      value: value.abs(),
      targetElement: targetElement,
      isPositive: false,
      description: description,
    );
  }

  /// Returns the effective value (positive for benefits, negative for tradeoffs).
  int get effectiveValue => isPositive ? value : -value;

  @override
  String toString() {
    final sign = isPositive ? '+' : '-';
    return '$sign$description';
  }
}
