import 'effect.dart';
import 'element.dart';
import 'spell.dart';
import '../data/elemental_growth.dart';
import '../systems/exp_system.dart';

/// Phase 7.9.4: Player-controlled mage with separated stat categories.
///
/// Stats are organized into:
/// - Base Stats: From element template at level 1
/// - Level Stats: Accumulated from elemental growth per level
/// - Skill Tree Bonuses: From character progression
/// - Temporary Modifiers: Combat buffs/debuffs (via status effects)
class Mage {
  final String id;
  final String name;
  final Element primaryElement;
  final String passiveDescription;

  // ==================== BASE STATS (from template) ====================
  final int baseHP;
  final int baseMana;
  final int baseAttack;
  final int baseDefense;
  final int baseSpeed;

  // ==================== LEVEL STATS (accumulated from growth) ====================
  int levelHP = 0;
  int levelMana = 0;
  int levelAttack = 0;
  int levelDefense = 0;
  int levelSpeed = 0;

  // ==================== SKILL TREE BONUSES ====================
  int skillTreeHPBonus = 0;
  int skillTreeManaBonus = 0;
  int skillTreeAttackBonus = 0;
  int skillTreeDefenseBonus = 0;
  int skillTreeSpeedBonus = 0;

  // ==================== COMPUTED STATS ====================
  int get maxHP => baseHP + levelHP + skillTreeHPBonus;
  int get maxMana => baseMana + levelMana + skillTreeManaBonus;
  int get attack => baseAttack + levelAttack + skillTreeAttackBonus;
  int get defense => baseDefense + levelDefense + skillTreeDefenseBonus;
  int get speed => baseSpeed + levelSpeed + skillTreeSpeedBonus;

  // ==================== EFFECTIVE SPEED (Pokémon-style) ====================
  /// Constants for speed calculation.
  static const int minSpeed = 1;
  static const int maxSpeedCap = 99;

  /// Calculates effective speed including temporary modifiers from status effects.
  ///
  /// Formula: BaseSpeed × (1 + sum of Haste%) × (1 - sum of Slow%)
  /// Clamped to [minSpeed, maxSpeedCap].
  int get effectiveSpeed {
    int base = speed; // Already includes base + level + skillTree

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

  // ==================== CURRENT VALUES ====================
  int currentHP;
  int mana;
  final List<Spell> spellLoadout;
  final List<ActiveStatusEffect> statusEffects;
  int actionsRemaining;
  int actionsPerTurn;

  // ==================== LEVELING ====================
  int level;
  int currentExp;
  int totalExpEarned; // For save/load validation

  /// Phase 7.8: Mana cost modifiers from elemental progression.
  Map<Element, int> manaCostModifiers = {};

  static const int maxLoadoutSize = 4;

  /// Phase 7.9.4: Uses explicit thresholds from ElementalGrowth.
  static int expRequiredForLevel(int level) {
    return ExpSystem.expToNextLevel(level);
  }

  int get expToNextLevel => ExpSystem.expToNextLevel(level);
  double get expProgress => ExpSystem.progressToNextLevel(currentExp, level);

  Mage({
    required this.id,
    required this.name,
    required this.primaryElement,
    required this.passiveDescription,
    required this.baseHP,
    required this.baseMana,
    required this.baseAttack,
    required this.baseDefense,
    required this.baseSpeed,
    required this.currentHP,
    required this.mana,
    List<Spell>? spellLoadout,
    List<ActiveStatusEffect>? statusEffects,
    this.actionsRemaining = 1,
    this.actionsPerTurn = 1,
    this.level = 1,
    this.currentExp = 0,
    this.totalExpEarned = 0,
  }) : spellLoadout = spellLoadout ?? [],
       statusEffects = statusEffects ?? [],
       assert(
         spellLoadout == null || spellLoadout.length <= maxLoadoutSize,
         'Spell loadout cannot exceed $maxLoadoutSize',
       );

  /// Whether the mage is alive.
  bool get isAlive => currentHP > 0;

  /// Whether currently affected by Slow.
  bool get isSlowed => statusEffects.any((e) => e.type == EffectType.slow);

  /// Whether below 50% HP.
  bool get isBelowHalfHP => currentHP < (maxHP / 2);

  /// Whether loadout is full.
  bool get isLoadoutFull => spellLoadout.length >= maxLoadoutSize;

  /// Whether the mage can act this turn (not incapacitated).
  /// Sleep and Freeze prevent actions.
  bool get canActThisTurn {
    if (statusEffects.any((e) => e.type == EffectType.sleep)) return false;
    if (statusEffects.any((e) => e.type == EffectType.freeze)) return false;
    return true;
  }

  String get hpDisplay => '$currentHP/$maxHP HP';
  String get manaDisplay => '$mana/$maxMana Mana';
  String get levelDisplay => 'Lv.$level ($currentExp/$expToNextLevel EXP)';
  String get statsDisplay => 'ATK:$attack DEF:$defense SPD:$speed';

  // ==================== EXP & LEVEL UP (Phase 7.9.4) ====================

  /// Adds experience and handles level-ups atomically.
  /// Returns list of log messages for each level gained.
  List<String> gainExp(int amount) {
    final logs = <String>[];
    currentExp += amount;
    totalExpEarned += amount;
    logs.add('Gained $amount EXP!');

    while (currentExp >= expToNextLevel && level < ExpSystem.maxLevel) {
      final expNeeded = expToNextLevel;
      currentExp -= expNeeded;
      level++;
      logs.addAll(_applyLevelUp());
    }

    return logs;
  }

  /// Phase 7.9.4: Applies level-up with elemental growth.
  /// Canonical order: increment level → apply base growth → apply skill tree
  List<String> _applyLevelUp() {
    final logs = <String>[];
    logs.add('═══════════════════════════');
    logs.add('🎉 LEVEL UP! Now Level $level!');
    logs.add('═══════════════════════════');

    // Apply elemental growth for this level
    final growth = ElementalGrowth.getGrowth(primaryElement);

    levelHP += growth.hp;
    levelMana += growth.mana;
    levelAttack += growth.attack;
    levelDefense += growth.defense;
    levelSpeed += growth.speed;

    // Also heal the bonus HP/Mana
    currentHP += growth.hp;
    mana += growth.mana;

    logs.add('+${growth.hp} Max HP (now $maxHP)');
    logs.add('+${growth.mana} Max Mana (now $maxMana)');
    if (growth.attack > 0) logs.add('+${growth.attack} Attack (now $attack)');
    if (growth.defense > 0) {
      logs.add('+${growth.defense} Defense (now $defense)');
    }
    if (growth.speed > 0) logs.add('+${growth.speed} Speed (now $speed)');

    logs.add('');
    return logs;
  }

  /// Phase 7.9.4: Rebuilds level stats from level + element.
  /// Used after loading to reconstruct computed stats.
  void rebuildLevelStats() {
    final growth = ElementalGrowth.calculateAccumulatedGrowth(
      primaryElement,
      1,
      level,
    );
    levelHP = growth.hp;
    levelMana = growth.mana;
    levelAttack = growth.attack;
    levelDefense = growth.defense;
    levelSpeed = growth.speed;
  }

  // ==================== SPELLS ====================

  bool learnSpell(Spell spell) {
    if (isLoadoutFull) return false;
    spellLoadout.add(spell);
    return true;
  }

  void replaceSpell(int index, Spell newSpell) {
    if (index >= 0 && index < spellLoadout.length) {
      spellLoadout[index] = newSpell;
    }
  }

  Spell? discardSpell(int index) {
    if (index >= 0 && index < spellLoadout.length) {
      return spellLoadout.removeAt(index);
    }
    return null;
  }

  bool upgradeSpell(int index, [String? upgradePath]) {
    if (index >= 0 && index < spellLoadout.length) {
      final spell = spellLoadout[index];
      if (spell.starLevel < 3) {
        spellLoadout[index] = spell.upgrade(upgradePath);
        return true;
      }
    }
    return false;
  }

  int getEffectiveManaCost(Spell spell) {
    final baseManaCost = spell.manaCost;
    final modifier = manaCostModifiers[spell.element] ?? 0;
    return (baseManaCost + modifier).clamp(1, 99);
  }

  bool canCast(Spell spell) {
    return mana >= getEffectiveManaCost(spell) && actionsRemaining > 0;
  }

  void consumeForCast(Spell spell) {
    mana -= getEffectiveManaCost(spell);
    actionsRemaining--;
  }

  // ==================== COMBAT ====================

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

  int heal(int amount) {
    final actualHeal = amount.clamp(0, maxHP - currentHP);
    currentHP += actualHeal;
    return actualHeal;
  }

  int restoreMana(int amount) {
    final actualRestore = amount.clamp(0, maxMana - mana);
    mana += actualRestore;
    return actualRestore;
  }

  void resetActions() {
    actionsRemaining = actionsPerTurn;
    for (final effect in statusEffects) {
      if (effect.type == EffectType.slow) {
        actionsRemaining -= effect.value;
      } else if (effect.type == EffectType.actionGain) {
        actionsRemaining += effect.value;
      }
    }
    actionsRemaining = actionsRemaining.clamp(0, 5);
  }

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
    return logs;
  }

  // ==================== COPY / SERIALIZE ====================

  Mage freshCopy() {
    return Mage(
      id: id,
      name: name,
      primaryElement: primaryElement,
      passiveDescription: passiveDescription,
      baseHP: baseHP,
      baseMana: baseMana,
      baseAttack: baseAttack,
      baseDefense: baseDefense,
      baseSpeed: baseSpeed,
      currentHP: baseHP,
      mana: baseMana,
      actionsPerTurn: actionsPerTurn,
      level: 1,
      currentExp: 0,
      totalExpEarned: 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'primaryElement': primaryElement.name,
    'passiveDescription': passiveDescription,
    'baseHP': baseHP,
    'baseMana': baseMana,
    'baseAttack': baseAttack,
    'baseDefense': baseDefense,
    'baseSpeed': baseSpeed,
    'levelHP': levelHP,
    'levelMana': levelMana,
    'levelAttack': levelAttack,
    'levelDefense': levelDefense,
    'levelSpeed': levelSpeed,
    'skillTreeHPBonus': skillTreeHPBonus,
    'skillTreeManaBonus': skillTreeManaBonus,
    'skillTreeAttackBonus': skillTreeAttackBonus,
    'skillTreeDefenseBonus': skillTreeDefenseBonus,
    'skillTreeSpeedBonus': skillTreeSpeedBonus,
    'currentHP': currentHP,
    'mana': mana,
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
    'totalExpEarned': totalExpEarned,
    'manaCostModifiers': manaCostModifiers.map((k, v) => MapEntry(k.name, v)),
  };

  factory Mage.fromJson(Map<String, dynamic> json) {
    final mage = Mage(
      id: json['id'] as String,
      name: json['name'] as String,
      primaryElement: Element.values.firstWhere(
        (e) => e.name == json['primaryElement'],
      ),
      passiveDescription: json['passiveDescription'] as String,
      baseHP: json['baseHP'] as int? ?? json['maxHP'] as int,
      baseMana: json['baseMana'] as int? ?? json['maxMana'] as int,
      baseAttack: json['baseAttack'] as int? ?? 5,
      baseDefense: json['baseDefense'] as int? ?? 3,
      baseSpeed: json['baseSpeed'] as int? ?? 4,
      currentHP: json['currentHP'] as int,
      mana: json['mana'] as int,
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
      totalExpEarned: json['totalExpEarned'] as int? ?? 0,
    );

    // Restore level stats
    mage.levelHP = json['levelHP'] as int? ?? 0;
    mage.levelMana = json['levelMana'] as int? ?? 0;
    mage.levelAttack = json['levelAttack'] as int? ?? 0;
    mage.levelDefense = json['levelDefense'] as int? ?? 0;
    mage.levelSpeed = json['levelSpeed'] as int? ?? 0;

    // Restore skill tree bonuses
    mage.skillTreeHPBonus = json['skillTreeHPBonus'] as int? ?? 0;
    mage.skillTreeManaBonus = json['skillTreeManaBonus'] as int? ?? 0;
    mage.skillTreeAttackBonus = json['skillTreeAttackBonus'] as int? ?? 0;
    mage.skillTreeDefenseBonus = json['skillTreeDefenseBonus'] as int? ?? 0;
    mage.skillTreeSpeedBonus = json['skillTreeSpeedBonus'] as int? ?? 0;

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
