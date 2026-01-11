import '../data/passive_definitions.dart';
import '../data/spell_definitions.dart';
import '../domain/boss_enemy.dart';
import '../domain/element.dart';
import '../domain/elite_enemy.dart';

/// The Twin Gatekeepers - Act 1 Boss.
/// Gatekeeper A: Fire + Earth
/// Gatekeeper B: Water + Air
///
/// They are silent, mechanistic, a barrier not a villain.
/// They exist to prevent unready persistence.
class TwinGatekeepers {
  TwinGatekeepers._();

  /// Creates the Twin Gatekeepers encounter.
  static List<BossEnemy> createEncounter({int difficultyLevel = 1}) {
    return [
      gatekeeperPyre(difficultyLevel: difficultyLevel),
      gatekeeperTide(difficultyLevel: difficultyLevel),
    ];
  }

  /// Gatekeeper of Pyre (Fire + Earth) - tanky, deals burn.
  /// Passives:
  /// - Immune to Burn (modifier)
  /// - Resistant to Fire (modifier)
  /// - Forge of Endurance (systemic passive)
  static BossEnemy gatekeeperPyre({int difficultyLevel = 1}) {
    final baseHp = 60;
    final hpBonus = (baseHp * 0.15 * (difficultyLevel - 1)).round();

    return BossEnemy(
      id: 'gatekeeper_pyre',
      name: 'Gatekeeper of Pyre',
      title: 'Gatekeeper of Pyre',
      element: Element.fire,
      currentHP: baseHp + hpBonus,
      maxHP: baseHp + hpBonus,
      attackDamage: 8 + (difficultyLevel - 1),
      armorGain: 10,
      modifiers: [EliteModifier.burnImmune, EliteModifier.resistant],
      resistantElement: Element.fire,
      passives: PassiveDefinitions.gatekeeperPyrePassives(),
      maxMana: 20,
      spellLoadout: [SpellDefinitions.blazeStrike, SpellDefinitions.inferno],
    );
  }

  /// Gatekeeper of Tide (Water + Air) - fast, deals control.
  /// Passives:
  /// - Immune to Slow (modifier)
  /// - Resistant to Water (modifier)
  /// - Tidal Reversal (systemic passive)
  static BossEnemy gatekeeperTide({int difficultyLevel = 1}) {
    final baseHp = 50;
    final hpBonus = (baseHp * 0.15 * (difficultyLevel - 1)).round();

    return BossEnemy(
      id: 'gatekeeper_tide',
      name: 'Gatekeeper of Tide',
      title: 'Gatekeeper of Tide',
      element: Element.water,
      currentHP: baseHp + hpBonus,
      maxHP: baseHp + hpBonus,
      attackDamage: 6 + (difficultyLevel - 1),
      armorGain: 5,
      modifiers: [EliteModifier.slowImmune, EliteModifier.resistant],
      resistantElement: Element.water,
      passives: PassiveDefinitions.gatekeeperTidePassives(),
      maxMana: 20,
      spellLoadout: [SpellDefinitions.tidalWave, SpellDefinitions.frostArmor],
    );
  }

  // ==================== NARRATIVE ====================

  /// Pre-battle narrative lines.
  static const List<String> preBattleLines = [
    'Two figures stand at the threshold.',
    'They do not speak. They do not need to.',
    'Fire and Water. Earth and Air.',
    'Complete in opposition.',
    'They were placed here. They do not tire.',
  ];

  /// Lines displayed during the fight (rare, triggered by conditions).
  static const Map<String, String> combatLines = {
    'pyre_low_hp': 'Pyre flickers. But does not fade.',
    'tide_low_hp': 'Tide ebbs. But will return.',
    'player_low_hp': 'The threshold tests. Always.',
    'synergy_attack': 'They move as one.',
  };

  /// Post-victory narrative (loop continues).
  static const List<String> postVictoryLines = [
    'The Gatekeepers fall.',
    'Silence.',
    'The threshold yields. For now.',
    'Progress? Or repetition?',
    'The loop continues.',
  ];

  /// Post-defeat narrative.
  static const List<String> postDefeatLines = [
    'The Gatekeepers stand.',
    'You do not.',
    'The threshold remains.',
    'You will return. You always do.',
  ];

  // ==================== MECHANICS ====================

  /// Gets the attack pattern for a gatekeeper.
  /// Gatekeepers attack in a predictable pattern.
  static GatekeeperAction getAction(
    String gatekeeperId,
    int turnNumber,
    int playerHpPercent,
  ) {
    // Pyre focuses on damage + burn
    if (gatekeeperId == 'gatekeeper_pyre') {
      if (turnNumber % 3 == 0) {
        return GatekeeperAction.heavyAttack;
      } else if (turnNumber % 3 == 1) {
        return GatekeeperAction.burnAttack;
      } else {
        return GatekeeperAction.defend;
      }
    }

    // Tide focuses on control + chip damage
    if (gatekeeperId == 'gatekeeper_tide') {
      if (turnNumber % 3 == 0) {
        return GatekeeperAction.slowAttack;
      } else if (turnNumber % 3 == 1) {
        return GatekeeperAction.quickAttack;
      } else {
        return GatekeeperAction.heal;
      }
    }

    return GatekeeperAction.basicAttack;
  }

  /// Checks if the Gatekeepers should perform a synergy attack.
  /// Happens when both are alive and on certain turns.
  static bool shouldSynergyAttack(
    bool pyreAlive,
    bool tideAlive,
    int turnNumber,
  ) {
    return pyreAlive && tideAlive && turnNumber % 5 == 0 && turnNumber > 0;
  }

  /// Gets synergy attack damage.
  static int getSynergyDamage(int difficultyLevel) {
    return 12 + (difficultyLevel * 2);
  }
}

/// Actions the Gatekeepers can take.
enum GatekeeperAction {
  basicAttack,
  heavyAttack,
  burnAttack,
  slowAttack,
  quickAttack,
  defend,
  heal,
  synergyAttack;

  String get displayName {
    switch (this) {
      case GatekeeperAction.basicAttack:
        return 'Attack';
      case GatekeeperAction.heavyAttack:
        return 'Heavy Strike';
      case GatekeeperAction.burnAttack:
        return 'Searing Flame';
      case GatekeeperAction.slowAttack:
        return 'Freezing Current';
      case GatekeeperAction.quickAttack:
        return 'Swift Tide';
      case GatekeeperAction.defend:
        return 'Earthward';
      case GatekeeperAction.heal:
        return 'Rejuvenate';
      case GatekeeperAction.synergyAttack:
        return 'Elemental Convergence';
    }
  }

  String get icon {
    switch (this) {
      case GatekeeperAction.basicAttack:
        return '⚔️';
      case GatekeeperAction.heavyAttack:
        return '💥';
      case GatekeeperAction.burnAttack:
        return '🔥';
      case GatekeeperAction.slowAttack:
        return '❄️';
      case GatekeeperAction.quickAttack:
        return '💨';
      case GatekeeperAction.defend:
        return '🛡️';
      case GatekeeperAction.heal:
        return '💧';
      case GatekeeperAction.synergyAttack:
        return '⚡';
    }
  }
}
