/// Progression module - manages run state and persistent meta-progression.
///
/// This module contains:
/// - [RunState] - Transient state for a single run (HP, spells, node index)
/// - [MetaState] - Persistent progression (fragments, crystals, statistics)
/// - [LevelingService] - XP/level calculations and rewards
library;

export 'run_state.dart';
export 'meta_state.dart';
export 'leveling_service.dart';
