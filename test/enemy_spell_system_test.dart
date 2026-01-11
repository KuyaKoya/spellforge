import 'package:flutter_test/flutter_test.dart';
import 'package:spellforge/domain/enemy.dart';
import 'package:spellforge/domain/spell.dart';
import 'package:spellforge/domain/element.dart';
import 'package:spellforge/domain/effect.dart';
import 'package:spellforge/data/spell_definitions.dart';
import 'package:spellforge/data/enemy_definitions.dart';

void main() {
  group('Enemy Spell System Tests', () {
    test('Enemy has spell loadout and mana', () {
      // Create enemy with spells
      final enemy = Enemy(
        id: 'test_caster',
        name: 'Test Caster',
        element: Element.fire,
        currentHP: 50,
        maxHP: 50,
        attackDamage: 10,
        spellLoadout: [SpellDefinitions.fireball],
        maxMana: 5,
      );

      expect(enemy.spellLoadout.length, 1);
      expect(enemy.spellLoadout.first.id, 'fireball');
      expect(enemy.maxMana, 5);
      expect(enemy.currentMana, 5); // Should start at max
    });

    test('Enemy can check spell affordability', () {
      final enemy = Enemy(
        id: 'test_caster',
        name: 'Test Caster',
        element: Element.fire,
        currentHP: 50,
        maxHP: 50,
        attackDamage: 10,
        spellLoadout: [SpellDefinitions.fireball, SpellDefinitions.inferno],
        maxMana: 3,
      );

      // Fireball costs 2, should be affordable
      expect(enemy.canCastAnySpell, true);

      final affordableSpell = enemy.getAffordableSpell();
      expect(affordableSpell, isNotNull);
      expect(affordableSpell!.manaCost, lessThanOrEqualTo(enemy.currentMana));
    });

    test('Enemy mana consumption works', () {
      final enemy = Enemy(
        id: 'test_caster',
        name: 'Test Caster',
        element: Element.fire,
        currentHP: 50,
        maxHP: 50,
        attackDamage: 10,
        spellLoadout: [SpellDefinitions.fireball],
        maxMana: 5,
      );

      final spell = enemy.getAffordableSpell()!;
      final initialMana = enemy.currentMana;
      enemy.consumeMana(spell.manaCost);

      expect(enemy.currentMana, initialMana - spell.manaCost);
    });

    test('Enemy without spells cannot cast', () {
      final enemy = Enemy(
        id: 'test_melee',
        name: 'Test Melee',
        element: Element.earth,
        currentHP: 50,
        maxHP: 50,
        attackDamage: 15,
        spellLoadout: const [],
        maxMana: 0,
      );

      expect(enemy.canCastAnySpell, false);
      expect(enemy.getAffordableSpell(), isNull);
    });

    test('EnemyIntent.spell exists in enum', () {
      expect(EnemyIntent.values, contains(EnemyIntent.spell));
    });

    test('Common enemies have spell loadouts', () {
      // Test that all common enemies from definitions have spells
      for (final generator in EnemyDefinitions.allEnemies) {
        final enemy = generator();
        expect(
          enemy.spellLoadout,
          isNotEmpty,
          reason: '${enemy.name} should have spells',
        );
        expect(
          enemy.maxMana,
          greaterThan(0),
          reason: '${enemy.name} should have mana',
        );
      }
    });
  });

  group('Legendary Spell Tests', () {
    test('SpellRarity.legendary exists', () {
      expect(SpellRarity.values, contains(SpellRarity.legendary));
    });

    test('Legendary rarity has correct display properties', () {
      expect(SpellRarity.legendary.displayName, 'Legendary');
      expect(SpellRarity.legendary.icon, '🟣');
      expect(SpellRarity.legendary.colorName, 'purple');
    });

    test('Forge Collapse spell is defined correctly', () {
      final spell = SpellDefinitions.forgeCollapse;

      expect(spell.id, 'forgeCollapse');
      expect(spell.name, 'Forge Collapse');
      expect(spell.element, Element.fire);
      expect(spell.rarity, SpellRarity.legendary);
      expect(spell.effects.length, 3);

      // Check effects
      final damageEffect = spell.effects.firstWhere(
        (e) => e.type == EffectType.damage,
      );
      expect(damageEffect.value, 20);

      final burnEffect = spell.effects.firstWhere(
        (e) => e.type == EffectType.burn,
      );
      expect(burnEffect.value, 8);
      expect(burnEffect.duration, 4);

      final weakenEffect = spell.effects.firstWhere(
        (e) => e.type == EffectType.weaken,
      );
      expect(weakenEffect.value, 30);
      expect(weakenEffect.duration, 3);
    });

    test('Tidal Severance spell is defined correctly', () {
      final spell = SpellDefinitions.tidalSeverance;

      expect(spell.id, 'tidalSeverance');
      expect(spell.name, 'Tidal Severance');
      expect(spell.element, Element.water);
      expect(spell.rarity, SpellRarity.legendary);
      expect(spell.effects.length, 3);

      // Check effects
      final damageEffect = spell.effects.firstWhere(
        (e) => e.type == EffectType.damage,
      );
      expect(damageEffect.value, 15);

      final weakenEffect = spell.effects.firstWhere(
        (e) => e.type == EffectType.weaken,
      );
      expect(weakenEffect.value, 50);
      expect(weakenEffect.duration, 3);

      final slowEffect = spell.effects.firstWhere(
        (e) => e.type == EffectType.slow,
      );
      expect(slowEffect.value, 30);
      expect(slowEffect.duration, 2);
    });

    test('Legendary spells are in allSpells', () {
      final allSpells = SpellDefinitions.allSpells;

      expect(allSpells.any((s) => s.id == 'forgeCollapse'), true);
      expect(allSpells.any((s) => s.id == 'tidalSeverance'), true);
    });

    test('legendarySpells getter returns correct spells', () {
      final legendarySpells = SpellDefinitions.legendarySpells;

      expect(legendarySpells.length, 2);
      expect(
        legendarySpells.every((s) => s.rarity == SpellRarity.legendary),
        true,
      );
    });
  });

  group('Spell Mana Cost Tests', () {
    test('Legendary spells have appropriate mana costs', () {
      expect(SpellDefinitions.forgeCollapse.manaCost, 6);
      expect(SpellDefinitions.tidalSeverance.manaCost, 5);
    });

    test('Legendary spells cost more than common spells', () {
      final commonSpell = SpellDefinitions.fireball;
      final legendarySpell = SpellDefinitions.forgeCollapse;

      expect(legendarySpell.manaCost, greaterThan(commonSpell.manaCost));
    });
  });

  group('Enemy Serialization Tests', () {
    test('Enemy with spells can be serialized and deserialized', () {
      final enemy = Enemy(
        id: 'test_caster',
        name: 'Test Caster',
        element: Element.fire,
        currentHP: 50,
        maxHP: 50,
        attackDamage: 10,
        spellLoadout: [SpellDefinitions.fireball],
        maxMana: 5,
      );

      final json = enemy.toJson();
      final restored = Enemy.fromJson(json);

      expect(restored.id, enemy.id);
      expect(restored.name, enemy.name);
      expect(restored.maxMana, enemy.maxMana);
      expect(restored.currentMana, enemy.currentMana);
      expect(restored.spellLoadout.length, enemy.spellLoadout.length);
    });
  });
}
