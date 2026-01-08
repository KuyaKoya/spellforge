import 'effect.dart';
import 'element.dart';
import 'spell.dart';
import '../systems/exp_system.dart';

/// Represents the player-controlled mage.
/// Mage element does NOT restrict spell learning.
class Mage {
  final String id;
  final String name;
  final Element primaryElement;
  final String passiveDescription;
  int currentHP;
  int maxHP;
  int mana;
  int maxMana;
  final List<Spell> spellLoadout; // Max 4 spells
  final List<ActiveStatusEffect> statusEffects;
  int actionsRemaining;
  int actionsPerTurn;

  // Leveling system
  int level;
  int currentExp;

  /// Phase 7.8: Mana cost modifiers from elemental progression.
  /// Key is element, value is the flat modifier (negative = cheaper, positive = more expensive).
  Map<Element, int> manaCostModifiers = {};

  static const int maxLoadoutSize = 4;

  /// Phase 7.9: Experience required for the current level.
  ///
  /// Uses formula: EXP_TO_NEXT = 40 × Level^1.35
  ///
  /// This curve ensures:
  /// - Levels 1-3: Very fast progression
  /// - Levels 4-6: Moderate progression
  /// - Levels 7+: Slower progression to prevent overleveling before boss
  static int expRequiredForLevel(int level) {
    return ExpSystem.expToNextLevel(level);
  }

  /// Experience needed to reach the next level.
  int get expToNextLevel => ExpSystem.expToNextLevel(level);

  /// Experience progress as a percentage (0.0 to 1.0).
  double get expProgress => ExpSystem.progressToNextLevel(currentExp, level);

  Mage({
    required this.id,
    required this.name,
    required this.primaryElement,
    required this.passiveDescription,
    required this.currentHP,
    required this.maxHP,
    required this.mana,
    required this.maxMana,
    List<Spell>? spellLoadout,
    List<ActiveStatusEffect>? statusEffects,
    this.actionsRemaining = 1,
    this.actionsPerTurn = 1,
    this.level = 1,
    this.currentExp = 0,
  }) : spellLoadout = spellLoadout ?? [],
       statusEffects = statusEffects ?? [],
       assert(
         spellLoadout == null || spellLoadout.length <= maxLoadoutSize,
         'Spell loadout cannot exceed $maxLoadoutSize',
       );

  /// Whether the mage is alive.
  bool get isAlive => currentHP > 0;

  /// Whether the mage is currently affected by Slow.
  bool get isSlowed => statusEffects.any((e) => e.type == EffectType.slow);

  /// Whether the mage is below 50% HP.
  bool get isBelowHalfHP => currentHP < (maxHP / 2);

  /// Whether the loadout is full.
  bool get isLoadoutFull => spellLoadout.length >= maxLoadoutSize;

  /// HP display string.
  String get hpDisplay => '$currentHP/$maxHP HP';

  /// Mana display string.
  String get manaDisplay => '$mana/$maxMana Mana';

  /// Level display string.
  String get levelDisplay => 'Lv.$level ($currentExp/$expToNextLevel EXP)';

  /// Adds experience and handles level ups. Returns list of log messages.
  List<String> gainExp(int amount) {
    final logs = <String>[];
    currentExp += amount;
    logs.add('Gained $amount EXP!');

    while (currentExp >= expToNextLevel) {
      currentExp -= expToNextLevel;
      level++;
      logs.addAll(_applyLevelUp());
    }

    return logs;
  }

  /// Applies level up bonuses.
  List<String> _applyLevelUp() {
    final logs = <String>[];
    logs.add('═══════════════════════════');
    logs.add('🎉 LEVEL UP! Now Level $level!');
    logs.add('═══════════════════════════');

    // HP bonus: +5 per level
    final hpBonus = 5;
    maxHP += hpBonus;
    currentHP += hpBonus; // Also heal the bonus amount
    logs.add('+$hpBonus Max HP (now $maxHP)');

    // Mana bonus: +2 per level
    final manaBonus = 2;
    maxMana += manaBonus;
    mana += manaBonus;
    logs.add('+$manaBonus Max Mana (now $maxMana)');

    // Every 3 levels: +1 action per turn
    if (level % 3 == 0) {
      actionsPerTurn++;
      logs.add('+1 Action per turn (now $actionsPerTurn)');
    }

    logs.add('');
    return logs;
  }

  /// Adds a spell to the loadout if there's room.
  /// Returns true if successful.
  bool learnSpell(Spell spell) {
    if (isLoadoutFull) return false;
    spellLoadout.add(spell);
    return true;
  }

  /// Replaces a spell at the given index with a new spell.
  void replaceSpell(int index, Spell newSpell) {
    if (index >= 0 && index < spellLoadout.length) {
      spellLoadout[index] = newSpell;
    }
  }

  /// Removes a spell at the given index.
  Spell? discardSpell(int index) {
    if (index >= 0 && index < spellLoadout.length) {
      return spellLoadout.removeAt(index);
    }
    return null;
  }

  /// Upgrades a spell in the loadout.
  bool upgradeSpell(int index) {
    if (index >= 0 && index < spellLoadout.length) {
      final spell = spellLoadout[index];
      if (spell.starLevel < 3) {
        spellLoadout[index] = spell.upgrade();
        return true;
      }
    }
    return false;
  }

  /// Gets the effective mana cost of a spell, accounting for elemental modifiers.
  int getEffectiveManaCost(Spell spell) {
    final baseManaCost = spell.manaCost;
    // Phase 7.8: Apply mana cost modifier for this element
    final modifier = manaCostModifiers[spell.element] ?? 0;
    // Also check for "all elements" modifier (using null key stored as fire for simplicity)
    // Actually, we need a separate global modifier
    return (baseManaCost + modifier).clamp(1, 99); // Minimum 1 mana cost
  }

  /// Whether the mage can cast the given spell.
  bool canCast(Spell spell) {
    return mana >= getEffectiveManaCost(spell) && actionsRemaining > 0;
  }

  /// Consumes mana and an action for casting.
  void consumeForCast(Spell spell) {
    mana -= getEffectiveManaCost(spell);
    actionsRemaining--;
  }

  /// Takes damage, returning the actual damage taken.
  int takeDamage(int damage) {
    // Check for armor status effect
    int remainingDamage = damage;
    final armorEffects = statusEffects
        .where((e) => e.type == EffectType.armor)
        .toList();

    for (final armor in armorEffects) {
      if (remainingDamage <= 0) break;

      // Calculate how much this armor stack can absorb
      final absorbed = remainingDamage.clamp(0, armor.value);

      // Reduce armor value (destructible armor)
      armor.value -= absorbed;

      // Reduce remaining damage
      remainingDamage -= absorbed;

      // If armor is fully depleted, remove it
      if (armor.value <= 0) {
        statusEffects.remove(armor);
      }

      // Note: We do NOT decrement duration here.
      // Duration represents turns, not hits.
    }

    final actualDamage = remainingDamage.clamp(0, currentHP);
    currentHP -= actualDamage;
    return actualDamage;
  }

  /// Heals the mage.
  int heal(int amount) {
    final actualHeal = amount.clamp(0, maxHP - currentHP);
    currentHP += actualHeal;
    return actualHeal;
  }

  /// Restores mana.
  int restoreMana(int amount) {
    final actualRestore = amount.clamp(0, maxMana - mana);
    mana += actualRestore;
    return actualRestore;
  }

  /// Resets actions for a new turn.
  void resetActions() {
    actionsRemaining = actionsPerTurn;

    // Check for action modifications from status effects
    for (final effect in statusEffects) {
      if (effect.type == EffectType.slow) {
        actionsRemaining -= effect.value;
      } else if (effect.type == EffectType.actionGain) {
        actionsRemaining += effect.value;
      }
    }
    actionsRemaining = actionsRemaining.clamp(0, 5); // Cap at 5
  }

  /// Applies a status effect.
  void applyStatusEffect(Effect effect) {
    if (!effect.isStatusEffect) return;

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

    return logs;
  }

  /// Creates a fresh copy for a new run.
  Mage freshCopy() {
    return Mage(
      id: id,
      name: name,
      primaryElement: primaryElement,
      passiveDescription: passiveDescription,
      currentHP: maxHP,
      maxHP: maxHP,
      mana: maxMana,
      maxMana: maxMana,
      actionsPerTurn: actionsPerTurn,
      level: 1,
      currentExp: 0,
    );
  }

  /// Converts to JSON for save/load serialization.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'primaryElement': primaryElement.name,
    'passiveDescription': passiveDescription,
    'currentHP': currentHP,
    'maxHP': maxHP,
    'mana': mana,
    'maxMana': maxMana,
    'spellLoadout': spellLoadout.map((s) => s.toJson()).toList(),
    'statusEffects': statusEffects
        .map(
          (e) => {
            'type': e.type.name,
            'value': e.value,
            'remainingDuration': e.remainingDuration,
          },
        )
        .toList(),
    'actionsRemaining': actionsRemaining,
    'actionsPerTurn': actionsPerTurn,
    'level': level,
    'currentExp': currentExp,
    'manaCostModifiers': manaCostModifiers.map((k, v) => MapEntry(k.name, v)),
  };

  /// Creates from JSON for save/load serialization.
  factory Mage.fromJson(Map<String, dynamic> json) {
    final mage = Mage(
      id: json['id'] as String,
      name: json['name'] as String,
      primaryElement: Element.values.firstWhere(
        (e) => e.name == json['primaryElement'],
      ),
      passiveDescription: json['passiveDescription'] as String,
      currentHP: json['currentHP'] as int,
      maxHP: json['maxHP'] as int,
      mana: json['mana'] as int,
      maxMana: json['maxMana'] as int,
      spellLoadout: (json['spellLoadout'] as List)
          .map((s) => Spell.fromJson(s as Map<String, dynamic>))
          .toList(),
      statusEffects: (json['statusEffects'] as List)
          .map(
            (e) => ActiveStatusEffect(
              type: EffectType.values.firstWhere((t) => t.name == e['type']),
              value: e['value'] as int,
              remainingDuration: e['remainingDuration'] as int,
            ),
          )
          .toList(),
      actionsRemaining: json['actionsRemaining'] as int,
      actionsPerTurn: json['actionsPerTurn'] as int,
      level: json['level'] as int,
      currentExp: json['currentExp'] as int,
    );

    // Restore mana cost modifiers
    final modifiersJson = json['manaCostModifiers'] as Map<String, dynamic>?;
    if (modifiersJson != null) {
      mage.manaCostModifiers = modifiersJson.map(
        (k, v) =>
            MapEntry(Element.values.firstWhere((e) => e.name == k), v as int),
      );
    }

    return mage;
  }

  @override
  String toString() => '$name (${primaryElement.displayName} Mage)';
}
