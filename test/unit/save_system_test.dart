import 'package:flutter_test/flutter_test.dart';

import 'package:spellforge/progression/run_save_data.dart';
import 'package:spellforge/domain/element.dart';
import 'package:spellforge/domain/spell.dart';
import 'package:spellforge/domain/effect.dart';

void main() {
  group('RunSaveData', () {
    RunSaveData createValidSaveData() {
      return RunSaveData(
        playerHP: 75,
        playerMaxHP: 100,
        playerMana: 30,
        playerMaxMana: 50,
        playerArmor: 10,
        playerLevel: 3,
        playerExp: 150,
        equippedSpells: [
          {
            'id': 'fireball',
            'name': 'Fireball',
            'element': 'fire',
            'rarity': 'rare',
            'starLevel': 2,
            'baseDescription': 'Deals fire damage',
            'effects': [
              {
                'type': 'damage',
                'value': 25,
                'duration': 0,
                'targetRule': 'single',
              },
            ],
            'manaCost': 8,
            'allowedUpgrades': [],
          },
        ],
        playerStatusEffects: [],
        manaCostModifiers: {'fire': -1},
        extraActionsPerTurn: 0,
        startingElement: 'fire',
        currentNodeIndex: 5,
        currentLevel: 3,
        experienceThisRun: 150,
        combatsWon: 3,
        elitesDefeated: 1,
        spellsLearned: 2,
        spellsUpgraded: 1,
        fragmentsEarnedThisRun: 100,
        crystalsEarnedThisRun: 5,
        rngSeed: 12345,
        shownEliteDialogues: ['Ember Guardian'],
        directorPressureState: 'neutral',
        directorTurnsSinceStateChange: 3,
        directorPressureScore: 50,
        difficultyTier: 1,
        savedAt: DateTime(2026, 1, 8, 12, 0, 0),
      );
    }

    test('toJson/fromJson round-trip preserves all fields', () {
      final saveData = createValidSaveData();

      final json = saveData.toJson();
      final restored = RunSaveData.fromJson(json);

      expect(restored.version, equals(saveData.version));
      expect(restored.currentNodeIndex, equals(saveData.currentNodeIndex));
      expect(restored.rngSeed, equals(saveData.rngSeed));
      expect(restored.playerMaxHP, equals(saveData.playerMaxHP));
      expect(restored.playerHP, equals(saveData.playerHP));
      expect(restored.combatsWon, equals(saveData.combatsWon));
      expect(restored.elitesDefeated, equals(saveData.elitesDefeated));
      expect(restored.startingElement, equals(saveData.startingElement));
      expect(
        restored.directorPressureScore,
        equals(saveData.directorPressureScore),
      );
    });

    test('validate returns true for valid save data', () {
      final saveData = createValidSaveData();

      expect(saveData.validate(), isTrue);
    });

    test('validate returns false for invalid HP', () {
      final saveData = RunSaveData(
        playerHP: -5, // Invalid
        playerMaxHP: 100,
        playerMana: 50,
        playerMaxMana: 50,
        playerArmor: 0,
        playerLevel: 1,
        playerExp: 0,
        equippedSpells: [
          {
            'id': 'spell',
            'name': 'Spell',
            'element': 'fire',
            'rarity': 'common',
            'starLevel': 1,
            'baseDescription': 'desc',
            'effects': [],
            'manaCost': 5,
            'allowedUpgrades': [],
          },
        ],
        playerStatusEffects: [],
        manaCostModifiers: {},
        extraActionsPerTurn: 0,
        startingElement: 'fire',
        currentNodeIndex: 0,
        currentLevel: 1,
        experienceThisRun: 0,
        combatsWon: 0,
        elitesDefeated: 0,
        spellsLearned: 0,
        spellsUpgraded: 0,
        fragmentsEarnedThisRun: 0,
        crystalsEarnedThisRun: 0,
        rngSeed: 12345,
        shownEliteDialogues: [],
        directorPressureState: 'neutral',
        directorTurnsSinceStateChange: 0,
        directorPressureScore: 50,
        difficultyTier: 1,
        savedAt: DateTime.now(),
      );

      expect(saveData.validate(), isFalse);
    });

    test('validate returns false for empty spells', () {
      final saveData = RunSaveData(
        playerHP: 100,
        playerMaxHP: 100,
        playerMana: 50,
        playerMaxMana: 50,
        playerArmor: 0,
        playerLevel: 1,
        playerExp: 0,
        equippedSpells: [], // Invalid - empty
        playerStatusEffects: [],
        manaCostModifiers: {},
        extraActionsPerTurn: 0,
        startingElement: 'fire',
        currentNodeIndex: 0,
        currentLevel: 1,
        experienceThisRun: 0,
        combatsWon: 0,
        elitesDefeated: 0,
        spellsLearned: 0,
        spellsUpgraded: 0,
        fragmentsEarnedThisRun: 0,
        crystalsEarnedThisRun: 0,
        rngSeed: 12345,
        shownEliteDialogues: [],
        directorPressureState: 'neutral',
        directorTurnsSinceStateChange: 0,
        directorPressureScore: 50,
        difficultyTier: 1,
        savedAt: DateTime.now(),
      );

      expect(saveData.validate(), isFalse);
    });
  });

  group('Spell Serialization', () {
    test('toJson/fromJson round-trip preserves Spell state', () {
      final spell = Spell(
        id: 'fireball',
        name: 'Fireball',
        element: Element.fire,
        rarity: SpellRarity.rare,
        starLevel: 2,
        baseDescription: 'Hurls a ball of fire',
        effects: [
          Effect(type: EffectType.damage, value: 25),
          Effect(type: EffectType.burn, value: 5, duration: 3),
        ],
        manaCost: 8,
      );

      final json = spell.toJson();
      final restored = Spell.fromJson(json);

      expect(restored.id, equals(spell.id));
      expect(restored.name, equals(spell.name));
      expect(restored.element, equals(spell.element));
      expect(restored.rarity, equals(spell.rarity));
      expect(restored.starLevel, equals(spell.starLevel));
      expect(restored.manaCost, equals(spell.manaCost));
      expect(restored.effects.length, equals(2));
      expect(restored.effects[0].type, equals(EffectType.damage));
      expect(restored.effects[0].value, equals(25));
      expect(restored.effects[1].type, equals(EffectType.burn));
      expect(restored.effects[1].duration, equals(3));
    });
  });
}
