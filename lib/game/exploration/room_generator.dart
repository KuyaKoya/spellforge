import '../../nodes/nodes.dart';
import '../../systems/node_resolver.dart';
import 'components/door_interactable.dart';
import 'exploration_controller.dart';

/// Generates room configurations from node data.
///
/// Converts the abstract node system into concrete room layouts
/// for the exploration system.
class RoomGenerator {
  /// Helper to generate a unique node ID.
  static String _nodeId(MapNode node) => 'node_${node.depth}_${node.pathIndex}';

  /// Generate a room configuration for a combat node.
  static RoomConfiguration generateCombatRoom({
    required int depth,
    required String nodeId,
    bool isElite = false,
  }) {
    // Generate enemy using existing resolver
    final enemies = isElite
        ? NodeResolver.generateEliteEncounter(depth)
        : NodeResolver.generateCombatEncounter(depth);

    final enemy = enemies.isNotEmpty ? enemies.first : null;

    // Create doors - typically one exit (north)
    final doors = [
      DoorConfig(
        direction: DoorDirection.north,
        destinationId: 'next_$nodeId',
        destinationType: 'unknown', // Will be determined by next node
        state: DoorState.available,
        label: 'Continue',
      ),
    ];

    return RoomConfiguration.combat(
      roomId: nodeId,
      enemy: enemy!,
      doors: doors,
      isElite: isElite,
    );
  }

  /// Generate a room configuration from a MapNode.
  static RoomConfiguration fromNode({
    required MapNode node,
    required int depth,
    MapNode? nextNode,
  }) {
    switch (node.type) {
      case NodeType.combat:
        return _createCombatRoom(
          node: node,
          depth: depth,
          nextNode: nextNode,
          isElite: false,
        );

      case NodeType.elite:
        return _createCombatRoom(
          node: node,
          depth: depth,
          nextNode: nextNode,
          isElite: true,
        );

      case NodeType.bossCombat:
        return _createBossRoom(node: node, depth: depth);

      case NodeType.shop:
      case NodeType.spellLearn:
      case NodeType.enhancementShrine:
      case NodeType.rest:
      case NodeType.randomEvent:
        // These node types don't use the spatial exploration system
        // They have their own dedicated screens
        return _createTransitionRoom(
          node: node,
          depth: depth,
          nextNode: nextNode,
        );
    }
  }

  static RoomConfiguration _createCombatRoom({
    required MapNode node,
    required int depth,
    MapNode? nextNode,
    required bool isElite,
  }) {
    // Generate enemies
    final enemies = isElite
        ? NodeResolver.generateEliteEncounter(depth)
        : NodeResolver.generateCombatEncounter(depth);

    final enemy = enemies.isNotEmpty ? enemies.first : null;

    // Determine next node type for door preview
    final nextType = nextNode?.type.name ?? 'unknown';

    final doors = [
      DoorConfig(
        direction: DoorDirection.north,
        destinationId: nextNode != null ? _nodeId(nextNode) : 'complete',
        destinationType: nextType,
        state: DoorState.available,
        label: nextNode?.type.displayName ?? 'Continue',
      ),
    ];

    return RoomConfiguration(
      roomId: _nodeId(node),
      title: isElite ? 'Elite Encounter' : 'Combat Room',
      enemy: enemy,
      isEliteEnemy: isElite,
      doors: doors,
      nodeType: node.type,
    );
  }

  static RoomConfiguration _createBossRoom({
    required MapNode node,
    required int depth,
  }) {
    // Generate boss enemies
    final enemies = NodeResolver.generateBossEncounter(depth);
    final enemy = enemies.isNotEmpty ? enemies.first : null;

    // Boss room has no exits until victory
    final doors = [
      DoorConfig(
        direction: DoorDirection.north,
        destinationId: 'victory',
        destinationType: 'victory',
        state: DoorState.locked,
        label: 'Victory',
      ),
    ];

    return RoomConfiguration(
      roomId: _nodeId(node),
      title: 'The Gatekeepers',
      description: 'The final challenge awaits...',
      enemy: enemy,
      isEliteEnemy: false,
      doors: doors,
      nodeType: node.type,
    );
  }

  static RoomConfiguration _createTransitionRoom({
    required MapNode node,
    required int depth,
    MapNode? nextNode,
  }) {
    // For non-combat nodes, create a simple room with an exit
    // These rooms won't have enemies, just doors

    final nextType = nextNode?.type.name ?? 'unknown';

    final doors = [
      DoorConfig(
        direction: DoorDirection.north,
        destinationId: nextNode != null ? _nodeId(nextNode) : 'complete',
        destinationType: nextType,
        state: DoorState.available,
        label: nextNode?.type.displayName ?? 'Continue',
      ),
    ];

    return RoomConfiguration(
      roomId: _nodeId(node),
      title: node.type.displayName,
      doors: doors,
      nodeType: node.type,
    );
  }

  /// Create a crossroads room with multiple exits.
  static RoomConfiguration createCrossroads({
    required String roomId,
    required List<MapNode> choices,
  }) {
    final doors = <DoorConfig>[];

    // Assign directions based on number of choices
    final directions = [
      DoorDirection.north,
      DoorDirection.east,
      DoorDirection.west,
    ];

    for (int i = 0; i < choices.length && i < directions.length; i++) {
      final choice = choices[i];
      doors.add(
        DoorConfig(
          direction: directions[i],
          destinationId: _nodeId(choice),
          destinationType: choice.type.name,
          state: DoorState.available,
          label: choice.type.displayName,
        ),
      );
    }

    return RoomConfiguration.crossroads(roomId: roomId, doors: doors);
  }
}
