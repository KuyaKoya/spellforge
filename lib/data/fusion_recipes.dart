import 'spell_definitions.dart';
import 'fusion_spell_definitions.dart';
import '../domain/spell.dart';

/// Defines fusion recipes: which two spells combine to create a fusion spell.
///
/// Fusion rules:
/// - Order doesn't matter (Fireball + Water Bolt = Water Bolt + Fireball)
/// - Same spell can be fused with itself (Fireball + Fireball = Solar Fireball)
/// - Fusion spells have rarity: SpellRarity.fusion
class FusionRecipes {
  FusionRecipes._();

  /// A recipe defining what fusion spell is created from two base spells.
  static final List<FusionRecipe> allRecipes = [
    // ==================== FIREBALL FUSIONS ====================
    FusionRecipe('fireball', 'fireball', 'solarFireball'),
    FusionRecipe('fireball', 'inferno', 'hellfireOrb'),
    FusionRecipe('fireball', 'blazeStrike', 'flareImpact'),
    FusionRecipe('fireball', 'waterBolt', 'steamburstFireball'),
    FusionRecipe('fireball', 'tidalWave', 'thermalTsunami'),
    FusionRecipe('fireball', 'frostArmor', 'flashMelt'),
    FusionRecipe('fireball', 'rockThrow', 'magmaShot'),
    FusionRecipe('fireball', 'earthquake', 'volcanicRupture'),
    FusionRecipe('fireball', 'stoneWall', 'moltenBastion'),
    FusionRecipe('fireball', 'windSlash', 'explosiveEmber'),
    FusionRecipe('fireball', 'gust', 'scatterFlame'),
    FusionRecipe('fireball', 'hurricane', 'firestormCore'),
    FusionRecipe('fireball', 'phoenixFlame', 'eternalSun'),
    FusionRecipe('fireball', 'typhoon', 'infernoCyclone'),
    FusionRecipe('fireball', 'forgeCollapse', 'smelterImpact'),
    FusionRecipe('fireball', 'tidalSeverance', 'boilingCataclysm'),

    // ==================== INFERNO FUSIONS ====================
    FusionRecipe('inferno', 'inferno', 'worldPyre'),
    FusionRecipe('inferno', 'blazeStrike', 'cinderExecution'),
    FusionRecipe('inferno', 'waterBolt', 'superheatedSteam'),
    FusionRecipe('inferno', 'tidalWave', 'evaporationSurge'),
    FusionRecipe('inferno', 'frostArmor', 'thermalShock'),
    FusionRecipe('inferno', 'rockThrow', 'lavaBarrage'),
    FusionRecipe('inferno', 'earthquake', 'magmaCataclysm'),
    FusionRecipe('inferno', 'stoneWall', 'obsidianBulwark'),
    FusionRecipe('inferno', 'windSlash', 'scorchingGale'),
    FusionRecipe('inferno', 'gust', 'flameUplift'),
    FusionRecipe('inferno', 'hurricane', 'apocalypticFirestorm'),
    FusionRecipe('inferno', 'phoenixFlame', 'undyingInferno'),
    FusionRecipe('inferno', 'typhoon', 'hellwindSpiral'),
    FusionRecipe('inferno', 'forgeCollapse', 'anvilOfFire'),
    FusionRecipe('inferno', 'tidalSeverance', 'ashenDeluge'),

    // ==================== BLAZE STRIKE FUSIONS ====================
    FusionRecipe('blazeStrike', 'blazeStrike', 'blazingVerdict'),
    FusionRecipe('blazeStrike', 'waterBolt', 'scaldingSlash'),
    FusionRecipe('blazeStrike', 'tidalWave', 'steamCleave'),
    FusionRecipe('blazeStrike', 'frostArmor', 'heatFracture'),
    FusionRecipe('blazeStrike', 'rockThrow', 'shatterbrand'),
    FusionRecipe('blazeStrike', 'earthquake', 'seismicBrand'),
    FusionRecipe('blazeStrike', 'stoneWall', 'sunderedRampart'),
    FusionRecipe('blazeStrike', 'windSlash', 'ignitionCut'),
    FusionRecipe('blazeStrike', 'gust', 'flareSweep'),
    FusionRecipe('blazeStrike', 'hurricane', 'burningCrosswind'),
    FusionRecipe('blazeStrike', 'phoenixFlame', 'judgmentOfAsh'),
    FusionRecipe('blazeStrike', 'typhoon', 'incineratingArc'),
    FusionRecipe('blazeStrike', 'forgeCollapse', 'forgedExecution'),
    FusionRecipe('blazeStrike', 'tidalSeverance', 'boilingRend'),

    // ==================== WATER BOLT FUSIONS ====================
    FusionRecipe('waterBolt', 'waterBolt', 'aquaLance'),
    FusionRecipe('waterBolt', 'tidalWave', 'surgingTorrent'),
    FusionRecipe('waterBolt', 'frostArmor', 'glacialShot'),
    FusionRecipe('waterBolt', 'rockThrow', 'erosionSpike'),
    FusionRecipe('waterBolt', 'earthquake', 'liquefaction'),
    FusionRecipe('waterBolt', 'stoneWall', 'seepingBastion'),
    FusionRecipe('waterBolt', 'windSlash', 'mistCutter'),
    FusionRecipe('waterBolt', 'gust', 'vaporBurst'),
    FusionRecipe('waterBolt', 'hurricane', 'stormJet'),
    FusionRecipe('waterBolt', 'phoenixFlame', 'scaldingRebirth'),
    FusionRecipe('waterBolt', 'typhoon', 'pressureSpear'),
    FusionRecipe('waterBolt', 'forgeCollapse', 'quenchImpact'),
    FusionRecipe('waterBolt', 'tidalSeverance', 'razorCurrent'),

    // ==================== TIDAL WAVE FUSIONS ====================
    FusionRecipe('tidalWave', 'tidalWave', 'oceanicJudgment'),
    FusionRecipe('tidalWave', 'frostArmor', 'frozenSurge'),
    FusionRecipe('tidalWave', 'rockThrow', 'mudslide'),
    FusionRecipe('tidalWave', 'earthquake', 'continentalFlood'),
    FusionRecipe('tidalWave', 'stoneWall', 'breakwater'),
    FusionRecipe('tidalWave', 'windSlash', 'waveCleaver'),
    FusionRecipe('tidalWave', 'gust', 'rollingSquall'),
    FusionRecipe('tidalWave', 'hurricane', 'maelstrom'),
    FusionRecipe('tidalWave', 'phoenixFlame', 'steamApocalypse'),
    FusionRecipe('tidalWave', 'typhoon', 'worldVortex'),
    FusionRecipe('tidalWave', 'forgeCollapse', 'drownedForge'),
    FusionRecipe('tidalWave', 'tidalSeverance', 'abyssalDivide'),

    // ==================== FROST ARMOR FUSIONS ====================
    FusionRecipe('frostArmor', 'frostArmor', 'absoluteZeroAegis'),
    FusionRecipe('frostArmor', 'rockThrow', 'permafrostShards'),
    FusionRecipe('frostArmor', 'earthquake', 'cryoFault'),
    FusionRecipe('frostArmor', 'stoneWall', 'glacierBastion'),
    FusionRecipe('frostArmor', 'windSlash', 'iceEdge'),
    FusionRecipe('frostArmor', 'gust', 'freezingDraft'),
    FusionRecipe('frostArmor', 'hurricane', 'blizzardWall'),
    FusionRecipe('frostArmor', 'phoenixFlame', 'thermalParadox'),
    FusionRecipe('frostArmor', 'typhoon', 'polarCyclone'),
    FusionRecipe('frostArmor', 'forgeCollapse', 'brittleRuin'),
    FusionRecipe('frostArmor', 'tidalSeverance', 'frozenRift'),

    // ==================== ROCK THROW FUSIONS ====================
    FusionRecipe('rockThrow', 'rockThrow', 'meteorSlam'),
    FusionRecipe('rockThrow', 'earthquake', 'avalancheBreak'),
    FusionRecipe('rockThrow', 'stoneWall', 'spikedRampart'),
    FusionRecipe('rockThrow', 'windSlash', 'shrapnelCut'),
    FusionRecipe('rockThrow', 'gust', 'scatterstone'),
    FusionRecipe('rockThrow', 'hurricane', 'debrisStorm'),
    FusionRecipe('rockThrow', 'phoenixFlame', 'cinderfall'),
    FusionRecipe('rockThrow', 'typhoon', 'crushingSpiral'),
    FusionRecipe('rockThrow', 'forgeCollapse', 'anvilDrop'),
    FusionRecipe('rockThrow', 'tidalSeverance', 'gravelSurge'),

    // ==================== EARTHQUAKE FUSIONS ====================
    FusionRecipe('earthquake', 'earthquake', 'worldbreaker'),
    FusionRecipe('earthquake', 'stoneWall', 'continentalAegis'),
    FusionRecipe('earthquake', 'windSlash', 'faultCleaver'),
    FusionRecipe('earthquake', 'gust', 'upliftTremor'),
    FusionRecipe('earthquake', 'hurricane', 'cyclonicRupture'),
    FusionRecipe('earthquake', 'phoenixFlame', 'moltenSundering'),
    FusionRecipe('earthquake', 'typhoon', 'cataclysmicGyre'),
    FusionRecipe('earthquake', 'forgeCollapse', 'coreCollapse'),
    FusionRecipe('earthquake', 'tidalSeverance', 'tectonicDivide'),

    // ==================== STONE WALL FUSIONS ====================
    FusionRecipe('stoneWall', 'stoneWall', 'adamantFortress'),
    FusionRecipe('stoneWall', 'windSlash', 'razorBulwark'),
    FusionRecipe('stoneWall', 'gust', 'stonewake'),
    FusionRecipe('stoneWall', 'hurricane', 'stormCitadel'),
    FusionRecipe('stoneWall', 'phoenixFlame', 'ashenKeep'),
    FusionRecipe('stoneWall', 'typhoon', 'bastionOfTides'),
    FusionRecipe('stoneWall', 'forgeCollapse', 'ironcladRampart'),
    FusionRecipe('stoneWall', 'tidalSeverance', 'breakwaterDivide'),

    // ==================== WIND SLASH FUSIONS ====================
    FusionRecipe('windSlash', 'windSlash', 'skyRend'),
    FusionRecipe('windSlash', 'gust', 'crosswindCut'),
    FusionRecipe('windSlash', 'hurricane', 'jetstreamCleave'),
    FusionRecipe('windSlash', 'phoenixFlame', 'solarSlice'),
    FusionRecipe('windSlash', 'typhoon', 'vacuumArc'),
    FusionRecipe('windSlash', 'forgeCollapse', 'shearingCollapse'),
    FusionRecipe('windSlash', 'tidalSeverance', 'razorSquall'),

    // ==================== GUST FUSIONS ====================
    FusionRecipe('gust', 'gust', 'tempestPulse'),
    FusionRecipe('gust', 'hurricane', 'stormBirth'),
    FusionRecipe('gust', 'phoenixFlame', 'flareUpdraft'),
    FusionRecipe('gust', 'typhoon', 'spiralBurst'),
    FusionRecipe('gust', 'forgeCollapse', 'pressureImplosion'),
    FusionRecipe('gust', 'tidalSeverance', 'windRift'),

    // ==================== HURRICANE FUSIONS ====================
    FusionRecipe('hurricane', 'hurricane', 'endlessTempest'),
    FusionRecipe('hurricane', 'phoenixFlame', 'solarStorm'),
    FusionRecipe('hurricane', 'typhoon', 'worldstorm'),
    FusionRecipe('hurricane', 'forgeCollapse', 'stormfall'),
    FusionRecipe('hurricane', 'tidalSeverance', 'cycloneDivide'),

    // ==================== TYPHOON FUSIONS ====================
    FusionRecipe('typhoon', 'typhoon', 'oceanKing'),
    FusionRecipe('typhoon', 'phoenixFlame', 'steamDominion'),
    FusionRecipe('typhoon', 'forgeCollapse', 'maelstromCollapse'),
    FusionRecipe('typhoon', 'tidalSeverance', 'abyssVortex'),

    // ==================== PHOENIX FLAME FUSIONS ====================
    FusionRecipe('phoenixFlame', 'phoenixFlame', 'eternalRebirth'),
    FusionRecipe('phoenixFlame', 'forgeCollapse', 'forgedAscension'),
    FusionRecipe('phoenixFlame', 'tidalSeverance', 'finalDeluge'),

    // ==================== FORGE COLLAPSE FUSIONS ====================
    FusionRecipe('forgeCollapse', 'forgeCollapse', 'worldAnvil'),
    FusionRecipe('forgeCollapse', 'tidalSeverance', 'cataclysmDivide'),

    // ==================== TIDAL SEVERANCE FUSIONS ====================
    FusionRecipe('tidalSeverance', 'tidalSeverance', 'oceansEnd'),
  ];

  /// Lookup table for fast recipe checking.
  /// Key format: "spell1Id|spell2Id" (alphabetically sorted)
  static final Map<String, String> _recipeMap = _buildRecipeMap();

  static Map<String, String> _buildRecipeMap() {
    final map = <String, String>{};
    for (final recipe in allRecipes) {
      final key = recipe.getSortedKey();
      map[key] = recipe.resultId;
    }
    return map;
  }

  /// Check if two spells can be fused.
  static bool canFuse(String spell1Id, String spell2Id) {
    final key = _makeSortedKey(spell1Id, spell2Id);
    return _recipeMap.containsKey(key);
  }

  /// Get the resulting fusion spell ID for two input spells.
  /// Returns null if the combination doesn't exist.
  static String? getFusionResult(String spell1Id, String spell2Id) {
    final key = _makeSortedKey(spell1Id, spell2Id);
    return _recipeMap[key];
  }

  /// Get the resulting fusion Spell object for two input spells.
  /// Returns null if the combination doesn't exist or the fusion spell isn't defined.
  static Spell? getFusionSpell(String spell1Id, String spell2Id) {
    final resultId = getFusionResult(spell1Id, spell2Id);
    if (resultId == null) return null;
    return FusionSpellDefinitions.getById(resultId);
  }

  /// Get all recipes that use a specific spell.
  static List<FusionRecipe> getRecipesFor(String spellId) {
    return allRecipes
        .where((r) => r.spell1Id == spellId || r.spell2Id == spellId)
        .toList();
  }

  /// Get all available fusion recipes (spells that are defined).
  static List<FusionRecipe> getAvailableRecipes() {
    return allRecipes
        .where((r) => FusionSpellDefinitions.getById(r.resultId) != null)
        .toList();
  }

  /// Get all pending recipes (fusion spells not yet implemented).
  static List<FusionRecipe> getPendingRecipes() {
    return allRecipes
        .where((r) => FusionSpellDefinitions.getById(r.resultId) == null)
        .toList();
  }

  static String _makeSortedKey(String id1, String id2) {
    final sorted = [id1, id2]..sort();
    return '${sorted[0]}|${sorted[1]}';
  }
}

/// A single fusion recipe.
class FusionRecipe {
  final String spell1Id;
  final String spell2Id;
  final String resultId;

  const FusionRecipe(this.spell1Id, this.spell2Id, this.resultId);

  /// Get a consistent key regardless of spell order.
  String getSortedKey() {
    final sorted = [spell1Id, spell2Id]..sort();
    return '${sorted[0]}|${sorted[1]}';
  }

  /// Get the base spell objects (from SpellDefinitions).
  Spell? get spell1 => _getSpellById(spell1Id);
  Spell? get spell2 => _getSpellById(spell2Id);
  Spell? get result => FusionSpellDefinitions.getById(resultId);

  /// Whether this recipe's fusion spell is implemented.
  bool get isImplemented => result != null;

  /// Get display name for the fusion.
  String get displayName {
    final s1 = spell1?.name ?? spell1Id;
    final s2 = spell2?.name ?? spell2Id;
    final res = result?.name ?? resultId;
    return '$s1 + $s2 → $res';
  }

  static Spell? _getSpellById(String id) {
    try {
      return SpellDefinitions.allSpells.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => displayName;
}
