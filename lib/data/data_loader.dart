import 'dart:convert';
import 'package:flutter/services.dart';

/// Service for loading game data from JSON asset files.
///
/// This centralizes all data loading logic and provides caching
/// to avoid repeated file reads.
class DataLoader {
  DataLoader._();

  static final Map<String, dynamic> _cache = {};

  /// Loads a JSON file from assets/data/ directory.
  static Future<Map<String, dynamic>> loadJson(String filename) async {
    if (_cache.containsKey(filename)) {
      return _cache[filename]!;
    }

    final jsonString = await rootBundle.loadString('assets/data/$filename');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    _cache[filename] = data;
    return data;
  }

  /// Loads the enemies data.
  static Future<List<Map<String, dynamic>>> loadEnemies() async {
    final data = await loadJson('enemies.json');
    return (data['enemies'] as List).cast<Map<String, dynamic>>();
  }

  /// Loads the mages data.
  static Future<List<Map<String, dynamic>>> loadMages() async {
    final data = await loadJson('mages.json');
    return (data['mages'] as List).cast<Map<String, dynamic>>();
  }

  /// Clears the cache (useful for hot reload during development).
  static void clearCache() {
    _cache.clear();
  }

  /// Check if data has been loaded.
  static bool isLoaded(String filename) => _cache.containsKey(filename);
}
