import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../progression/run_save_data.dart';

/// Save eligibility states - MUST NOT save during these.
enum SaveBlockReason {
  midCombat,
  midAnimation,
  directorDialogue,
  rewardSelection,
  spellLearning,
  targetSelection,
}

/// Manages save/load for a single run save slot.
///
/// Phase 7.9.3: Implements deterministic save/load with:
/// - Single auto-overwrite save slot
/// - Save eligibility gates
/// - Load validation with fallback reset
class SaveManager {
  static const String _saveKey = 'spellforge_run_save';
  static const String _hasSaveKey = 'spellforge_has_save';

  SharedPreferences? _prefs;

  /// Singleton instance.
  static final SaveManager instance = SaveManager._();
  SaveManager._();

  /// Current save block reasons (if any).
  final Set<SaveBlockReason> _blockReasons = {};

  /// Whether saving is currently blocked.
  bool get isSaveBlocked => _blockReasons.isNotEmpty;

  /// Debug: Get current block reasons.
  Set<SaveBlockReason> get blockReasons => Set.unmodifiable(_blockReasons);

  /// Initialize the save manager.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    if (kDebugMode) {
      print('[SaveManager] Initialized');
    }
  }

  /// Blocks saving for a given reason.
  void blockSave(SaveBlockReason reason) {
    _blockReasons.add(reason);
    if (kDebugMode) {
      print('[SaveManager] Save blocked: $reason');
    }
  }

  /// Unblocks saving for a given reason.
  void unblockSave(SaveBlockReason reason) {
    _blockReasons.remove(reason);
    if (kDebugMode) {
      print('[SaveManager] Save unblocked: $reason');
    }
  }

  /// Clears all save blocks.
  void clearAllBlocks() {
    _blockReasons.clear();
  }

  /// Whether a save exists.
  bool get hasSave => _prefs?.getBool(_hasSaveKey) ?? false;

  /// Saves the run state.
  ///
  /// Returns true if save succeeded, false if blocked or failed.
  Future<bool> saveRun(RunSaveData data) async {
    if (_prefs == null) {
      if (kDebugMode) print('[SaveManager] Not initialized');
      return false;
    }

    if (isSaveBlocked) {
      if (kDebugMode) {
        print('[SaveManager] Save blocked by: $_blockReasons');
      }
      return false;
    }

    try {
      final json = jsonEncode(data.toJson());
      await _prefs!.setString(_saveKey, json);
      await _prefs!.setBool(_hasSaveKey, true);

      if (kDebugMode) {
        print('[SaveManager] Saved at node ${data.currentNodeIndex}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[SaveManager] Save failed: $e');
      }
      return false;
    }
  }

  /// Loads the run state.
  ///
  /// Returns null if no save exists or validation fails.
  /// On validation failure, the save is automatically deleted.
  Future<RunSaveData?> loadRun() async {
    if (_prefs == null) {
      if (kDebugMode) print('[SaveManager] Not initialized');
      return null;
    }

    if (!hasSave) {
      if (kDebugMode) print('[SaveManager] No save exists');
      return null;
    }

    try {
      final json = _prefs!.getString(_saveKey);
      if (json == null) return null;

      final data = RunSaveData.fromJson(jsonDecode(json));

      // Validate the loaded data
      if (!data.validate()) {
        if (kDebugMode) {
          print('[SaveManager] Save validation failed, discarding');
        }
        await deleteSave();
        return null;
      }

      if (kDebugMode) {
        print('[SaveManager] Loaded save from node ${data.currentNodeIndex}');
      }
      return data;
    } catch (e) {
      if (kDebugMode) {
        print('[SaveManager] Load failed: $e, discarding save');
      }
      await deleteSave();
      return null;
    }
  }

  /// Deletes the current save.
  Future<void> deleteSave() async {
    if (_prefs == null) return;

    await _prefs!.remove(_saveKey);
    await _prefs!.setBool(_hasSaveKey, false);

    if (kDebugMode) {
      print('[SaveManager] Save deleted');
    }
  }

  /// Debug: Get save info without loading full data.
  Future<String?> getSaveInfo() async {
    if (!hasSave) return null;

    try {
      final json = _prefs?.getString(_saveKey);
      if (json == null) return null;

      final data = jsonDecode(json) as Map<String, dynamic>;
      return 'Node: ${data['currentNodeIndex']}, '
          'HP: ${data['playerHP']}/${data['playerMaxHP']}, '
          'Saved: ${data['savedAt']}';
    } catch (e) {
      return 'Error reading save: $e';
    }
  }
}
