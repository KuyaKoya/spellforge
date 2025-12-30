import 'package:flutter/foundation.dart';

import '../../domain/enemy.dart';
import '../../domain/mage.dart';
import '../../nodes/nodes.dart';
import '../../director/director_system.dart';
import 'components/components.dart';

/// Result of an exploration interaction.
sealed class ExplorationResult {}

/// Player confirmed engagement with an enemy.
class EngageEnemyResult extends ExplorationResult {
  final Enemy enemy;
  final bool isElite;

  EngageEnemyResult({required this.enemy, this.isElite = false});
}

/// Player confirmed traveling through a door.
class TravelDoorResult extends ExplorationResult {
  final DoorDirection direction;
  final String destinationId;

  TravelDoorResult({required this.direction, required this.destinationId});
}

/// Player entered a shop.
class EnterShopResult extends ExplorationResult {}

/// Player engaged with an event.
class EngageEventResult extends ExplorationResult {
  final Map<String, dynamic> eventData;

  EngageEventResult({required this.eventData});
}

/// Player used a shrine.
class UseShrineResult extends ExplorationResult {}

/// Configuration for a room.
class RoomConfiguration {
  /// Unique identifier for this room.
  final String roomId;

  /// Title of the room (displayed at top).
  final String? title;

  /// Description (for accessibility/logs).
  final String? description;

  /// Enemy in this room, if any.
  final Enemy? enemy;

  /// Whether the enemy is elite.
  final bool isEliteEnemy;

  /// Available doors/exits.
  final List<DoorConfig> doors;

  /// Whether the enemy has been defeated.
  final bool enemyDefeated;

  /// Node type this room represents.
  final NodeType? nodeType;

  const RoomConfiguration({
    required this.roomId,
    this.title,
    this.description,
    this.enemy,
    this.isEliteEnemy = false,
    this.doors = const [],
    this.enemyDefeated = false,
    this.nodeType,
  });

  /// Create a combat room configuration.
  factory RoomConfiguration.combat({
    required String roomId,
    required Enemy enemy,
    required List<DoorConfig> doors,
    bool isElite = false,
  }) {
    return RoomConfiguration(
      roomId: roomId,
      title: isElite ? 'Elite Encounter' : 'Combat Room',
      enemy: enemy,
      isEliteEnemy: isElite,
      doors: doors,
      nodeType: isElite ? NodeType.elite : NodeType.combat,
    );
  }

  /// Create a crossroads room (multiple exits).
  factory RoomConfiguration.crossroads({
    required String roomId,
    required List<DoorConfig> doors,
  }) {
    return RoomConfiguration(roomId: roomId, title: 'Crossroads', doors: doors);
  }

  /// Create a copy with enemy defeated.
  RoomConfiguration withEnemyDefeated() {
    return RoomConfiguration(
      roomId: roomId,
      title: title,
      description: description,
      enemy: enemy,
      isEliteEnemy: isEliteEnemy,
      doors: doors,
      enemyDefeated: true,
      nodeType: nodeType,
    );
  }
}

/// Configuration for a door.
class DoorConfig {
  /// Direction of the door.
  final DoorDirection direction;

  /// Destination room/node ID.
  final String destinationId;

  /// Type of destination (for preview).
  final String destinationType;

  /// Current state of the door.
  final DoorState state;

  /// Label for the door.
  final String? label;

  const DoorConfig({
    required this.direction,
    required this.destinationId,
    this.destinationType = 'unknown',
    this.state = DoorState.available,
    this.label,
  });

  DoorConfig copyWith({
    DoorDirection? direction,
    String? destinationId,
    String? destinationType,
    DoorState? state,
    String? label,
  }) {
    return DoorConfig(
      direction: direction ?? this.direction,
      destinationId: destinationId ?? this.destinationId,
      destinationType: destinationType ?? this.destinationType,
      state: state ?? this.state,
      label: label ?? this.label,
    );
  }
}

/// Controller for exploration room state and interactions.
///
/// Manages the flow of:
/// - Room initialization
/// - Interactable state
/// - Interaction callbacks
/// - Director integration
/// - Result propagation
class ExplorationController extends ChangeNotifier {
  /// Current room configuration.
  RoomConfiguration? _roomConfig;

  /// Player's mage data.
  Mage? _mage;

  /// Director system reference.
  DirectorSystem? _director;

  /// Current interactable being previewed.
  InteractableComponent? _activeInteractable;

  /// Result to be consumed by the game loop.
  ExplorationResult? _pendingResult;

  /// Director message to display.
  String? _directorMessage;

  /// Timer for director message dismissal.
  int _directorMessageTimer = 0;

  /// Whether exploration is paused (for preview mode).
  bool _isPaused = false;

  // ==================== ACCESSORS ====================

  /// Current room configuration.
  RoomConfiguration? get roomConfig => _roomConfig;

  /// Player's mage.
  Mage? get mage => _mage;

  /// Whether a room is loaded.
  bool get hasRoom => _roomConfig != null;

  /// Whether exploration is paused.
  bool get isPaused => _isPaused;

  /// Current active interactable.
  InteractableComponent? get activeInteractable => _activeInteractable;

  /// Preview data for the active interactable.
  Map<String, dynamic>? get activePreviewData =>
      _activeInteractable?.previewData;

  /// Pending result to be consumed.
  ExplorationResult? consumeResult() {
    final result = _pendingResult;
    _pendingResult = null;
    return result;
  }

  /// Current director message.
  String? get directorMessage => _directorMessage;

  /// Whether the room has a living enemy.
  bool get hasLivingEnemy =>
      _roomConfig?.enemy != null && !(_roomConfig?.enemyDefeated ?? true);

  /// Whether doors are blocked by an enemy.
  bool get areDoorsBlocked => hasLivingEnemy;

  // ==================== INITIALIZATION ====================

  /// Initialize with a room configuration.
  void loadRoom({
    required RoomConfiguration config,
    required Mage mage,
    DirectorSystem? director,
  }) {
    _roomConfig = config;
    _mage = mage;
    _director = director;
    _activeInteractable = null;
    _pendingResult = null;
    _isPaused = false;

    // Trigger director room entry
    _triggerDirectorRoomEntry();

    notifyListeners();
  }

  /// Update mage reference (after combat, etc.).
  void updateMage(Mage mage) {
    _mage = mage;
    notifyListeners();
  }

  /// Mark enemy as defeated.
  void markEnemyDefeated() {
    if (_roomConfig != null) {
      _roomConfig = _roomConfig!.withEnemyDefeated();
      notifyListeners();
    }
  }

  /// Clear the room.
  void clearRoom() {
    _roomConfig = null;
    _mage = null;
    _activeInteractable = null;
    _pendingResult = null;
    _isPaused = false;
    _directorMessage = null;
    notifyListeners();
  }

  // ==================== INTERACTION HANDLING ====================

  /// Handle player approaching an interactable.
  void onApproachInteractable(InteractableComponent interactable) {
    // Don't interrupt existing preview
    if (_activeInteractable != null && _activeInteractable != interactable) {
      return;
    }

    // Don't approach if interactable can't be interacted with
    if (!interactable.canInteract) {
      return;
    }

    _activeInteractable = interactable;
    _isPaused = true;
    interactable.approach();

    // Trigger director based on type
    _triggerDirectorApproach(interactable);

    notifyListeners();
  }

  /// Handle player confirming an interaction.
  void onConfirmInteraction() {
    if (_activeInteractable == null) return;

    final interactable = _activeInteractable!;
    interactable.confirm();

    // Generate result based on type
    switch (interactable.type) {
      case InteractableType.enemy:
        final data = interactable.previewData;
        _pendingResult = EngageEnemyResult(
          enemy: data['enemy'] as Enemy,
          isElite: data['isElite'] as bool? ?? false,
        );
        break;

      case InteractableType.door:
        // Check if blocked
        if (areDoorsBlocked) {
          showDirectorMessage(
            '"The path remains sealed while threats linger."',
          );
          interactable.cancel();
          return;
        }

        final data = interactable.previewData;
        _pendingResult = TravelDoorResult(
          direction: data['direction'] as DoorDirection,
          destinationId: data['destinationId'] as String,
        );
        break;

      case InteractableType.shop:
        _pendingResult = EnterShopResult();
        break;

      case InteractableType.event:
        final data = interactable.previewData;
        _pendingResult = EngageEventResult(eventData: data);
        break;

      case InteractableType.shrine:
        _pendingResult = UseShrineResult();
        break;
    }

    _isPaused = false;
    _activeInteractable = null;
    notifyListeners();
  }

  /// Handle player cancelling an interaction.
  void onCancelInteraction() {
    if (_activeInteractable == null) return;

    final interactable = _activeInteractable!;

    // Track retreat for director
    if (interactable.type == InteractableType.enemy) {
      _triggerDirectorRetreat();
    }

    interactable.cancel();
    _activeInteractable = null;
    _isPaused = false;
    notifyListeners();
  }

  // ==================== DIRECTOR INTEGRATION ====================

  void _triggerDirectorRoomEntry() {
    if (_director == null || _roomConfig == null) return;

    // Could add director tracking here
    // For now, show contextual message based on room type
    if (_roomConfig!.enemy != null && !_roomConfig!.enemyDefeated) {
      if (_roomConfig!.isEliteEnemy) {
        showDirectorMessage('"A stronger presence awaits."');
      }
    }
  }

  void _triggerDirectorApproach(InteractableComponent interactable) {
    if (_director == null) return;

    if (interactable.type == InteractableType.enemy) {
      showDirectorMessage('"They sense your presence."');
    }
  }

  void _triggerDirectorRetreat() {
    if (_director == null) return;
    // Could track repeated retreats
    showDirectorMessage('"A moment of hesitation."');
  }

  /// Show a director message.
  void showDirectorMessage(String message, {int durationMs = 3000}) {
    _directorMessage = message;
    _directorMessageTimer = durationMs;
    notifyListeners();
  }

  /// Clear director message.
  void clearDirectorMessage() {
    _directorMessage = null;
    notifyListeners();
  }

  /// Tick the controller (for animations, timers).
  void tick(int deltaMs) {
    if (_directorMessageTimer > 0) {
      _directorMessageTimer -= deltaMs;
      if (_directorMessageTimer <= 0) {
        clearDirectorMessage();
      }
    }
  }
}
