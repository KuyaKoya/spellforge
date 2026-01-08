import 'package:flutter_test/flutter_test.dart';
import 'package:spellforge/domain/spell.dart';
import 'package:spellforge/domain/element.dart';
import 'package:spellforge/domain/effect.dart';

void main() {
  group('Spell Upgrade Tests', () {
    late Spell damageSpell;
    late Spell effectSpell;
    late Spell mixedSpell;
    late Spell signatureSpell;

    setUp(() {
      damageSpell = Spell(
        id: 'fireball',
        name: 'Fireball',
        element: Element.fire,
        rarity: SpellRarity.common,
        starLevel: 1,
        baseDescription: 'Deals damage.',
        effects: [Effect(type: EffectType.damage, value: 10)],
        manaCost: 10,
      );

      effectSpell = Spell(
        id: 'stoneskin',
        name: 'Stone Skin',
        element: Element.earth,
        rarity: SpellRarity.uncommon,
        starLevel: 1,
        baseDescription: 'Gains armor.',
        effects: [Effect(type: EffectType.armor, value: 8)],
        manaCost: 8,
      );

      mixedSpell = Spell(
        id: 'frostbolt',
        name: 'Frostbolt',
        element: Element.water,
        rarity: SpellRarity.rare,
        starLevel: 1,
        baseDescription: 'Damage and slow.',
        effects: [
          Effect(type: EffectType.damage, value: 12),
          Effect(type: EffectType.slow, value: 10, duration: 2),
        ],
        manaCost: 15,
      );

      signatureSpell = Spell(
        id: 'meteor',
        name: 'Meteor',
        element: Element.fire,
        rarity: SpellRarity.signature,
        starLevel: 1,
        baseDescription: 'Big boom.',
        effects: [Effect(type: EffectType.damage, value: 50)],
        manaCost: 40,
      );
    });

    test('getAvailableUpgradePaths returns correct options', () {
      expect(damageSpell.getAvailableUpgradePaths(), ['damage']);
      expect(effectSpell.getAvailableUpgradePaths(), ['effect_0']);
      expect(
        mixedSpell.getAvailableUpgradePaths(),
        containsAll(['damage', 'effect_1']),
      );
    });

    test('upgrade("damage") increases damage effects', () {
      final upgraded = damageSpell.upgrade('damage');

      expect(upgraded.baseDamage, 13); // 10 * 1.25 = 12.5 -> 13
      expect(upgraded.starLevel, 2);
    });

    test('upgrade("effect_0") increases non-damage effect', () {
      final upgraded = effectSpell.upgrade('effect_0');

      expect(upgraded.effects[0].value, 10); // 8 * 1.25 = 10
      expect(upgraded.starLevel, 2);
    });

    test(
      'upgrade("effect_1") increases only specific effect in mixed spell',
      () {
        final upgraded = mixedSpell.upgrade('effect_1');

        // Damage should stay same
        expect(upgraded.effects[0].value, 12);

        // Slow should increase
        expect(upgraded.effects[1].value, 13); // 10 * 1.25 = 12.5 -> 13
        expect(upgraded.effects[1].duration, 3); // 2 + 1
      },
    );

    test('upgrade("damage") increases only damage in mixed spell', () {
      final upgraded = mixedSpell.upgrade('damage');

      // Damage should increase
      expect(upgraded.effects[0].value, 15); // 12 * 1.25 = 15

      // Slow should stay same
      expect(upgraded.effects[1].value, 10);
      expect(upgraded.effects[1].duration, 2);
    });

    test('Mana cost increases based on rarity', () {
      // Common: +1
      var upgraded = damageSpell.upgrade();
      expect(upgraded.manaCost, 11);

      // Uncommon: +1
      upgraded = effectSpell.upgrade();
      expect(upgraded.manaCost, 9);

      // Rare: +2
      upgraded = mixedSpell.upgrade();
      expect(upgraded.manaCost, 17);

      // Signature: +3
      upgraded = signatureSpell.upgrade();
      expect(upgraded.manaCost, 43);
    });
  });
}
