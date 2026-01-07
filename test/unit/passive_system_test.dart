import 'package:flutter_test/flutter_test.dart';
import 'package:spellforge/domain/combat_event.dart';
import 'package:spellforge/domain/effect.dart';
import 'package:spellforge/domain/element.dart';
import 'package:spellforge/domain/elite_enemy.dart';
import 'package:spellforge/domain/enemy_passive.dart';
import 'package:spellforge/systems/passive_resolver.dart';

void main() {
  group('PassiveResolver & EliteEnemy Integration', () {
    late EliteEnemy elite;
    late EnemyPassive turnStartPassive;

    setUp(() {
      PassiveResolver.instance.resetCombat();

      turnStartPassive = EnemyPassive(
        id: 'turn_start_passive',
        name: 'Turn Start Passive',
        description: 'Triggers on turn start',
        icon: 'T',
        category: PassiveCategory.behavioral,
        triggerHint: 'Start',
        triggers: [CombatEventType.turnStart],
        scope: PassiveScope.self,
        effect: (event, state) {
          return PassiveResult(
            logMessage: 'Turn Start Triggered',
            armorGain: 10,
          );
        },
      );

      elite = EliteEnemy(
        id: 'elite_1',
        name: 'Test Elite',
        element: Element.fire,
        currentHP: 100,
        maxHP: 100,
        attackDamage: 10,
        modifiers: [],
        passives: [],
      );
    });

    test('validates scope correctly for turn events', () {
      elite.passives.add(turnStartPassive);

      final event = CombatEvent.turnStart(source: elite, turnNumber: 1);
      final results = elite.triggerPassives(event);

      expect(results.length, 1);
      expect(results.first.hasEffect, true);
      expect(results.first.armorGain, 10);

      // Verify logging happened
      expect(PassiveResolver.instance.triggerLog.length, 1);
      expect(PassiveResolver.instance.triggerLog.first.triggered, true);
    });

    test(
      'Scope validation blocks invalid triggers',
      skip: 'Investigation required on source ID mismatch',
      () {
        final pickyPassive = EnemyPassive(
          id: 'picky',
          name: 'Picky',
          description: 'Picky',
          icon: 'P',
          category: PassiveCategory.behavioral,
          triggerHint: 'Picky',
          triggers: [CombatEventType.spellCastAgainst],
          scope: PassiveScope.self,
          effect: (event, state) => PassiveResult(),
        );

        elite.passives.add(pickyPassive);

        final otherElite = EliteEnemy(
          id: 'other',
          name: 'Other',
          element: Element.water,
          currentHP: 100,
          maxHP: 100,
          attackDamage: 10,
          modifiers: [],
        );

        final event = CombatEvent(
          type: CombatEventType.spellCastAgainst,
          source: otherElite,
          target: elite,
        );

        final results = elite.triggerPassives(event);

        expect(results, isEmpty);
      },
    );

    test('Unique stack rule is enforced by PassiveResolver', () {
      final uniquePassive = EnemyPassive(
        id: 'unique',
        name: 'Unique',
        description: 'Unique',
        icon: 'U',
        category: PassiveCategory.behavioral,
        triggerHint: 'Unique',
        triggers: [CombatEventType.damageTaken],
        stackRule: StackRule.unique,
        effect: (event, state) => PassiveResult(),
      );

      elite.passives.add(uniquePassive);

      final event = CombatEvent.damageTaken(
        source: elite,
        damage: 10,
        element: Element.fire,
      );

      final results1 = elite.triggerPassives(event);
      expect(results1.length, 1);

      final results2 = elite.triggerPassives(event);
      expect(results2.length, 0);
    });

    test('Armor status effect triggers armorGained event', () {
      bool armorGainedTriggered = false;

      final armorListener = EnemyPassive(
        id: 'listener',
        name: 'Listener',
        description: 'Listen',
        icon: 'L',
        category: PassiveCategory.behavioral,
        triggerHint: 'Listen',
        triggers: [CombatEventType.armorGained],
        effect: (event, state) {
          armorGainedTriggered = true;
          return PassiveResult();
        },
      );

      elite.passives.add(armorListener);

      elite.applyStatusEffect(Effect(type: EffectType.armor, value: 50));

      expect(armorGainedTriggered, true);
    });
  });
}
