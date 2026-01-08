import 'effect.dart';
import 'element.dart';

/// Rarity levels for spells.
enum SpellRarity {
  common,
  uncommon,
  rare,
  signature;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }

  /// Rarity icon for display.
  String get icon {
    switch (this) {
      case SpellRarity.common:
        return '⚪';
      case SpellRarity.uncommon:
        return '🟢';
      case SpellRarity.rare:
        return '🔵';
      case SpellRarity.signature:
        return '🟡';
    }
  }

  /// Rarity color for text display (ANSI-style names).
  String get colorName {
    switch (this) {
      case SpellRarity.common:
        return 'white';
      case SpellRarity.uncommon:
        return 'green';
      case SpellRarity.rare:
        return 'blue';
      case SpellRarity.signature:
        return 'gold';
    }
  }
}

/// Upgrade path types for spells.
enum UpgradePath {
  addStatus, // Add a status effect
  improveTargeting, // Single → Multi-target
  addRepeated, // Add repeated effect
  addDelayed, // Add delayed effect
  tradeoff, // Stronger effect with a cost
}

/// Represents a spell that can be cast by a mage.
/// Spells have star levels (1-3 in prototype) and can be upgraded.
class Spell {
  final String id;
  final String name;
  final Element element;
  final SpellRarity rarity;
  final int starLevel; // 1-3 in prototype
  final String baseDescription;
  final List<Effect> effects;
  final int manaCost;
  final List<UpgradePath> allowedUpgrades;

  const Spell({
    required this.id,
    required this.name,
    required this.element,
    required this.rarity,
    required this.starLevel,
    required this.baseDescription,
    required this.effects,
    required this.manaCost,
    this.allowedUpgrades = const [],
  }) : assert(starLevel >= 1 && starLevel <= 3, 'Star level must be 1-3');

  /// Display stars as unicode characters.
  String get starsDisplay => '★' * starLevel + '☆' * (3 - starLevel);

  /// Full display name with stars.
  String get displayName => '$name $starsDisplay';

  /// Element icon.
  String get elementIcon {
    switch (element) {
      case Element.fire:
        return '🔥';
      case Element.water:
        return '💧';
      case Element.earth:
        return '🪨';
      case Element.air:
        return '💨';
    }
  }

  /// Gets the total base damage of this spell.
  int get baseDamage {
    return effects
        .where((e) => e.type == EffectType.damage)
        .fold(0, (sum, e) => sum + e.value);
  }

  /// Gets targeting info.
  String get targetingInfo {
    final hasAoe = effects.any((e) => e.targetRule == TargetRule.all);
    final hasSelf = effects.any((e) => e.targetRule == TargetRule.self);

    if (hasAoe && hasSelf) return '🎯 All + Self';
    if (hasAoe) return '🎯 All Enemies';
    if (hasSelf) return '🎯 Self';
    return '🎯 Single Target';
  }

  /// Creates an upgraded version of this spell.
  Spell upgrade() {
    if (starLevel >= 3) {
      return this; // Already at max
    }

    // Scale effects based on star level
    final scaledEffects = effects.map((e) {
      if (e.type == EffectType.damage) {
        return e.copyWith(value: (e.value * 1.25).round());
      } else if (e.isStatusEffect) {
        return e.copyWith(duration: e.duration + 1);
      }
      return e;
    }).toList();

    return Spell(
      id: id,
      name: name,
      element: element,
      rarity: rarity,
      starLevel: starLevel + 1,
      baseDescription: baseDescription,
      effects: scaledEffects,
      manaCost: manaCost,
      allowedUpgrades: allowedUpgrades,
    );
  }

  /// Creates a copy of this spell.
  Spell copyWith({
    String? id,
    String? name,
    Element? element,
    SpellRarity? rarity,
    int? starLevel,
    String? baseDescription,
    List<Effect>? effects,
    int? manaCost,
    List<UpgradePath>? allowedUpgrades,
  }) {
    return Spell(
      id: id ?? this.id,
      name: name ?? this.name,
      element: element ?? this.element,
      rarity: rarity ?? this.rarity,
      starLevel: starLevel ?? this.starLevel,
      baseDescription: baseDescription ?? this.baseDescription,
      effects: effects ?? this.effects,
      manaCost: manaCost ?? this.manaCost,
      allowedUpgrades: allowedUpgrades ?? this.allowedUpgrades,
    );
  }

  /// Full effect description.
  String get effectsDescription {
    return effects.map((e) => e.description).join(', ');
  }

  /// Detailed multi-line stats display.
  List<String> get detailedStats {
    final stats = <String>[];

    stats.add('$elementIcon $displayName ${rarity.icon}');
    stats.add('   ${rarity.displayName} • ${element.displayName}');
    stats.add('   💧 Cost: $manaCost mana');
    stats.add('   $targetingInfo');

    // Show each effect
    for (final effect in effects) {
      stats.add('   ${getEffectLine(effect)}');
    }

    return stats;
  }

  /// Gets a formatted line for an effect.
  String getEffectLine(Effect effect) {
    switch (effect.type) {
      case EffectType.damage:
        return '⚔️  ${effect.value} damage';
      case EffectType.burn:
        return '🔥 Burn: ${effect.value}/turn for ${effect.duration} turns';
      case EffectType.poison:
        return '☠️ Poison: ${effect.value}/turn for ${effect.duration} turns';
      case EffectType.slow:
        return '🐌 Slow: -${effect.value}% speed for ${effect.duration} turns';
      case EffectType.haste:
        return '⚡ Haste: +${effect.value}% speed for ${effect.duration} turns';
      case EffectType.weaken:
        return '💀 Weaken: -${effect.value}% damage for ${effect.duration} turns';
      case EffectType.armor:
        return '🛡️  +${effect.value} armor for ${effect.duration} turns';
      case EffectType.shield:
        return '🔰 Shield: -${effect.value}% damage taken for ${effect.duration} turns';
      case EffectType.sleep:
        return '💤 Sleep: skip turn for ${effect.duration} turns';
      case EffectType.freeze:
        return '❄️ Freeze: cannot act for ${effect.duration} turns';
      case EffectType.actionGain:
        return '⚡ +${effect.value} action(s)';
      case EffectType.delay:
        return '⏸️  Delay target for ${effect.value} turn(s)';
    }
  }

  /// Compact one-line summary.
  String get compactSummary {
    final damage = baseDamage;
    final parts = <String>[];

    if (damage > 0) {
      parts.add('$damage dmg');
    }

    for (final effect in effects.where((e) => e.type != EffectType.damage)) {
      switch (effect.type) {
        case EffectType.burn:
          parts.add('Burn ${effect.value}×${effect.duration}');
          break;
        case EffectType.slow:
          parts.add('Slow');
          break;
        case EffectType.weaken:
          parts.add('Weaken');
          break;
        case EffectType.armor:
          parts.add('+${effect.value} Armor');
          break;
        case EffectType.actionGain:
          parts.add('+${effect.value} Act');
          break;
        case EffectType.delay:
          parts.add('Delay');
          break;
        default:
          break;
      }
    }

    return parts.join(' • ');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'element': element.name,
    'rarity': rarity.name,
    'starLevel': starLevel,
    'baseDescription': baseDescription,
    'effects': effects.map((e) => e.toJson()).toList(),
    'manaCost': manaCost,
    'allowedUpgrades': allowedUpgrades.map((u) => u.name).toList(),
  };

  factory Spell.fromJson(Map<String, dynamic> json) => Spell(
    id: json['id'] as String,
    name: json['name'] as String,
    element: Element.values.firstWhere((e) => e.name == json['element']),
    rarity: SpellRarity.values.firstWhere((r) => r.name == json['rarity']),
    starLevel: json['starLevel'] as int,
    baseDescription: json['baseDescription'] as String,
    effects: (json['effects'] as List).map((e) => Effect.fromJson(e)).toList(),
    manaCost: json['manaCost'] as int,
    allowedUpgrades:
        (json['allowedUpgrades'] as List?)
            ?.map((u) => UpgradePath.values.firstWhere((p) => p.name == u))
            .toList() ??
        [],
  );

  @override
  String toString() => displayName;
}
