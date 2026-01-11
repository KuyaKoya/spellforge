import 'package:shared_preferences/shared_preferences.dart';
import '../domain/element.dart';
import 'elemental_path.dart';
import 'elemental_node.dart';
import 'node_modifier.dart';
import 'core_path.dart';

/// Manages persistent character progression across runs.
/// Tracks crystals and unlocked elemental nodes.
class CharacterProgress {
  static const String _fireNodesKey = 'character_fire_nodes';
  static const String _waterNodesKey = 'character_water_nodes';
  static const String _earthNodesKey = 'character_earth_nodes';
  static const String _airNodesKey = 'character_air_nodes';
  static const String _coreNodesKey = 'character_core_nodes';

  SharedPreferences? _prefs;

  /// Unlocked node counts per element (0-10).
  final Map<Element, int> _unlockedNodes = {
    Element.fire: 0,
    Element.water: 0,
    Element.earth: 0,
    Element.air: 0,
  };

  /// Unlocked core node count (0-10).
  int _unlockedCoreNodes = 0;

  /// Gets the unlocked core node count.
  int get unlockedCoreNodes => _unlockedCoreNodes;

  /// Gets the unlocked node count for an element.
  int getUnlockedCount(Element element) => _unlockedNodes[element] ?? 0;

  /// Gets all unlocked node counts.
  Map<Element, int> get unlockedNodes => Map.unmodifiable(_unlockedNodes);

  /// Gets the total number of unlocked nodes across all elements (including core).
  int get totalUnlockedNodes =>
      _unlockedNodes.values.fold(0, (a, b) => a + b) + _unlockedCoreNodes;

  /// Initializes from storage.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadData();
  }

  void _loadData() {
    _unlockedNodes[Element.fire] = _prefs?.getInt(_fireNodesKey) ?? 0;
    _unlockedNodes[Element.water] = _prefs?.getInt(_waterNodesKey) ?? 0;
    _unlockedNodes[Element.earth] = _prefs?.getInt(_earthNodesKey) ?? 0;
    _unlockedNodes[Element.air] = _prefs?.getInt(_airNodesKey) ?? 0;
    _unlockedCoreNodes = _prefs?.getInt(_coreNodesKey) ?? 0;
  }

  Future<void> _saveData() async {
    await _prefs?.setInt(_fireNodesKey, _unlockedNodes[Element.fire] ?? 0);
    await _prefs?.setInt(_waterNodesKey, _unlockedNodes[Element.water] ?? 0);
    await _prefs?.setInt(_earthNodesKey, _unlockedNodes[Element.earth] ?? 0);
    await _prefs?.setInt(_airNodesKey, _unlockedNodes[Element.air] ?? 0);
    await _prefs?.setInt(_coreNodesKey, _unlockedCoreNodes);
  }

  /// Gets the next node to unlock for an element.
  ElementalNode? getNextNode(Element element) {
    final path = ElementalPathRegistry.getPath(element);
    if (path == null) return null;

    final currentCount = getUnlockedCount(element);
    if (currentCount >= path.nodes.length) return null;

    return path.nodes[currentCount];
  }

  /// Gets the cost to unlock the next node for an element.
  int? getNextNodeCost(Element element) {
    return getNextNode(element)?.cost;
  }

  /// Whether the next node can be unlocked (has enough crystals).
  bool canUnlockNext(Element element, int availableCrystals) {
    final cost = getNextNodeCost(element);
    if (cost == null) return false;
    return availableCrystals >= cost;
  }

  /// Attempts to unlock the next node for an element.
  /// Returns the cost if successful, null if failed.
  Future<int?> unlockNextNode(
    Element element,
    Future<bool> Function(int) spendCrystals,
  ) async {
    final nextNode = getNextNode(element);
    if (nextNode == null) return null;

    final cost = nextNode.cost;
    final success = await spendCrystals(cost);
    if (!success) return null;

    _unlockedNodes[element] = getUnlockedCount(element) + 1;
    await _saveData();

    return cost;
  }

  /// Gets all unlocked nodes for an element.
  List<ElementalNode> getUnlockedNodesFor(Element element) {
    final path = ElementalPathRegistry.getPath(element);
    if (path == null) return [];

    final count = getUnlockedCount(element);
    return path.nodes.take(count).toList();
  }

  // ==================== CORE PATH METHODS ====================

  /// Gets the next core node to unlock.
  CoreNode? getNextCoreNode() {
    final path = CorePathRegistry.path;
    if (path == null) return null;
    if (_unlockedCoreNodes >= path.nodes.length) return null;
    return path.nodes[_unlockedCoreNodes];
  }

  /// Gets the cost to unlock the next core node.
  int? getNextCoreCost() => getNextCoreNode()?.cost;

  /// Gets the currency for the next core node.
  CoreCurrency? getNextCoreCurrency() => getNextCoreNode()?.currency;

  /// Whether the next core node can be unlocked.
  bool canUnlockNextCore(int availableFragments, int availableCrystals) {
    final nextNode = getNextCoreNode();
    if (nextNode == null) return false;

    if (nextNode.currency == CoreCurrency.fragments) {
      return availableFragments >= nextNode.cost;
    } else {
      return availableCrystals >= nextNode.cost;
    }
  }

  /// Attempts to unlock the next core node.
  /// Returns the cost if successful, null if failed.
  Future<int?> unlockNextCoreNode({
    required Future<bool> Function(int) spendFragments,
    required Future<bool> Function(int) spendCrystals,
  }) async {
    final nextNode = getNextCoreNode();
    if (nextNode == null) return null;

    final cost = nextNode.cost;
    bool success;

    if (nextNode.currency == CoreCurrency.fragments) {
      success = await spendFragments(cost);
    } else {
      success = await spendCrystals(cost);
    }

    if (!success) return null;

    _unlockedCoreNodes++;
    await _saveData();

    return cost;
  }

  /// Gets progress percentage for core path (0.0 - 1.0).
  double getCoreProgressPercent() {
    final path = CorePathRegistry.path;
    if (path == null) return 0.0;
    return _unlockedCoreNodes / path.nodes.length;
  }

  // ==================== MODIFIER AGGREGATION ====================

  /// Gets all active modifiers from unlocked nodes (elemental + core).
  List<NodeModifier> getActiveModifiers() {
    final modifiers = <NodeModifier>[];

    // Add elemental modifiers
    modifiers.addAll(ElementalPathRegistry.getActiveModifiers(_unlockedNodes));

    // Add core modifiers
    modifiers.addAll(CorePathRegistry.getActiveModifiers(_unlockedCoreNodes));

    return modifiers;
  }

  /// Gets a summary of active benefits.
  List<String> getActiveBenefits() {
    return getActiveModifiers()
        .where((m) => m.isPositive)
        .map((m) => m.description)
        .toList();
  }

  /// Gets a summary of active tradeoffs.
  List<String> getActiveTradeoffs() {
    return getActiveModifiers()
        .where((m) => !m.isPositive)
        .map((m) => m.description)
        .toList();
  }

  /// Gets progress percentage for an element (0.0 - 1.0).
  double getProgressPercent(Element element) {
    final path = ElementalPathRegistry.getPath(element);
    if (path == null) return 0.0;
    return getUnlockedCount(element) / path.nodes.length;
  }

  /// Gets a summary string.
  String getSummary() {
    final buffer = StringBuffer();
    buffer.writeln('=== CHARACTER PROGRESS ===');

    // Core path
    final corePath = CorePathRegistry.path;
    final coreMax = corePath?.nodes.length ?? 10;
    buffer.writeln('🌟 Core: $_unlockedCoreNodes/$coreMax');

    // Elemental paths
    for (final element in Element.values) {
      final count = getUnlockedCount(element);
      final path = ElementalPathRegistry.getPath(element);
      final max = path?.nodes.length ?? 10;
      buffer.writeln('${element.icon} ${element.displayName}: $count/$max');
    }
    buffer.writeln('Total Nodes: $totalUnlockedNodes');
    return buffer.toString();
  }

  /// Resets all progress (for testing).
  Future<void> resetAll() async {
    for (final element in Element.values) {
      _unlockedNodes[element] = 0;
    }
    _unlockedCoreNodes = 0;
    await _saveData();
  }

  /// Debug: Unlock all nodes (for testing).
  Future<void> unlockAll() async {
    for (final element in Element.values) {
      final path = ElementalPathRegistry.getPath(element);
      if (path != null) {
        _unlockedNodes[element] = path.nodes.length;
      }
    }
    final corePath = CorePathRegistry.path;
    if (corePath != null) {
      _unlockedCoreNodes = corePath.nodes.length;
    }
    await _saveData();
  }
}
