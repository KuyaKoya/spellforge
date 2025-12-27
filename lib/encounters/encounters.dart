/// Encounters module - manages combat encounter generation and rewards.
///
/// This module contains:
/// - [EncounterType] - Types of combat encounters (standard, elite, boss)
/// - [Encounter] - Encapsulates encounter data (enemies, type, depth)
/// - [EncounterGenerator] - Generates encounters based on depth and type
/// - [CombatResultDTO] - Structured combat result data
/// - [CombatRewards] - Rewards earned from combat
library;

export 'encounter.dart';
export 'encounter_generator.dart';
export 'combat_rewards.dart';
