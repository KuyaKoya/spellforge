/// Progression module - manages run state and persistent meta-progression.
///
/// This module contains:
/// - [RunState] - Transient state for a single run (HP, spells, node index)
/// - [MetaState] - Persistent progression (fragments, crystals, statistics)
/// - [LevelingService] - XP/level calculations and rewards
/// - [CharacterProgress] - Elemental node unlocks (Phase 7.8)
/// - [ElementalPath] - Path definitions for elemental trees
/// - [ElementalNode] - Individual node in an elemental path
/// - [NodeModifier] - Stat modifiers from unlocked nodes
library;

export 'run_state.dart';
export 'meta_state.dart';
export 'leveling_service.dart';
export 'character_progress.dart';
export 'elemental_path.dart';
export 'elemental_node.dart';
export 'node_modifier.dart';
