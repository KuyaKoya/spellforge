import 'effect.dart';
import 'element.dart';
import 'spell.dart';

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

  static const int maxLoadoutSize = 4;

  /// Experience required for each level.
  /// Level 1: 10, Level 2: 15, Level 3: 22, Level 4: 30, Level 5: 40, etc.
  static int expRequiredForLevel(int level) {
    if (level <= 0) return 0;
    if (level == 1) return 10;
    if (level == 2) return 15;
    if (level == 3) return 22;
    if (level == 4) return 30;
    if (level == 5) return 40;
    if (level == 6) return 52;
    if (level == 7) return 66;
    if (level == 8) return 82;
    if (level == 9) return 100;
    // Beyond level 9, continue increasing
    return 100 + (level - 9) * 25;
  }

  /// Experience needed to reach the next level.
  int get expToNextLevel => expRequiredForLevel(level);

  /// Experience progress as a percentage.
  double get expProgress =>
      expToNextLevel > 0 ? currentExp / expToNextLevel : 1.0;

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

  /// Whether the mage can cast the given spell.
  bool canCast(Spell spell) {
    return mana >= spell.manaCost && actionsRemaining > 0;
  }

  /// Consumes mana and an action for casting.
  void consumeForCast(Spell spell) {
    mana -= spell.manaCost;
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

  @override
  String toString() => '$name (${primaryElement.displayName} Mage)';
}
