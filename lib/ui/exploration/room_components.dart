import 'package:flutter/material.dart';

import '../../domain/enemy.dart';
import 'exploration_room_world.dart';

/// Room component types for future extensibility
enum RoomComponentType {
  enemy,
  door,
  chest,
  shrine,
  shop,
}

/// Door state enum
enum DoorState {
  locked,
  available,
  cleared,
}

/// Door data class
class DoorData {
  final DoorPosition position;
  final String destinationNodeId;
  final DoorState state;
  final String? label;

  const DoorData({
    required this.position,
    required this.destinationNodeId,
    this.state = DoorState.available,
    this.label,
  });

  DoorData copyWith({
    DoorPosition? position,
    String? destinationNodeId,
    DoorState? state,
    String? label,
  }) {
    return DoorData(
      position: position ?? this.position,
      destinationNodeId: destinationNodeId ?? this.destinationNodeId,
      state: state ?? this.state,
      label: label ?? this.label,
    );
  }
}

/// Room layout configuration
class RoomLayout {
  final List<DoorData> doors;
  final Enemy? enemy;
  final bool enemyDefeated;
  final String? roomTitle;
  final String? roomDescription;

  const RoomLayout({
    required this.doors,
    this.enemy,
    this.enemyDefeated = false,
    this.roomTitle,
    this.roomDescription,
  });

  /// Create a single-exit room (as per sketch 1)
  factory RoomLayout.singleExit({
    required DoorData northDoor,
    Enemy? enemy,
    bool enemyDefeated = false,
  }) {
    return RoomLayout(
      doors: [northDoor],
      enemy: enemy,
      enemyDefeated: enemyDefeated,
      roomTitle: 'Combat Room',
    );
  }

  /// Create a multi-exit room (as per sketch 2)
  factory RoomLayout.multiExit({
    required List<DoorData> doors,
    Enemy? enemy,
    bool enemyDefeated = false,
  }) {
    return RoomLayout(
      doors: doors,
      enemy: enemy,
      enemyDefeated: enemyDefeated,
      roomTitle: 'Crossroads',
    );
  }

  /// Convert to RoomConfig for the Flame world
  RoomConfig toRoomConfig() {
    return RoomConfig(
      doors: doors.map((d) => d.position).toList(),
      hasEnemy: enemy != null && !enemyDefeated,
      enemy: enemy,
      roomDescription: roomDescription,
    );
  }

  /// Check if a specific door is blocked (enemy alive)
  bool isDoorBlocked(DoorPosition position) {
    if (enemy == null || enemyDefeated) return false;
    // All doors blocked if enemy is alive
    return true;
  }

  /// Get door by position
  DoorData? getDoor(DoorPosition position) {
    for (final door in doors) {
      if (door.position == position) return door;
    }
    return null;
  }
}

/// Interaction prompt widget for room exploration
class InteractionPrompt extends StatelessWidget {
  final String message;
  final String? action;
  final IconData? icon;
  final VoidCallback? onTap;

  const InteractionPrompt({
    super.key,
    required this.message,
    this.action,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22).withValues(alpha: 0.95),
        border: Border.all(color: const Color(0xFF30363d)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFF58a6ff), size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Color(0xFFc9d1d9),
            ),
          ),
          if (action != null && onTap != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF238636),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  action!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Enemy preview panel (shown when approaching enemy)
class EnemyPreviewPanel extends StatelessWidget {
  final Enemy enemy;
  final VoidCallback? onEngage;
  final VoidCallback? onRetreat;

  const EnemyPreviewPanel({
    super.key,
    required this.enemy,
    this.onEngage,
    this.onRetreat,
  });

  Color get _elementColor {
    switch (enemy.element.name) {
      case 'fire':
        return const Color(0xFFf85149);
      case 'water':
        return const Color(0xFF58a6ff);
      case 'earth':
        return const Color(0xFF7c6f4a);
      case 'air':
        return const Color(0xFF79c0ff);
      default:
        return const Color(0xFF6e7681);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22).withValues(alpha: 0.95),
        border: Border.all(color: _elementColor.withValues(alpha: 0.5), width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _elementColor.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Text(
                enemy.element.displayName,
                style: TextStyle(
                  fontSize: 16,
                  color: _elementColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  enemy.name,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFc9d1d9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats
          _StatRow(label: 'HP', value: '${enemy.currentHP}/${enemy.maxHP}', color: const Color(0xFF3fb950)),
          const SizedBox(height: 4),
          _StatRow(label: 'ATK', value: '${enemy.attackDamage}', color: const Color(0xFFf85149)),
          const SizedBox(height: 4),
          _StatRow(label: 'DEF', value: '${enemy.armorGain}', color: const Color(0xFF58a6ff)),

          const SizedBox(height: 12),

          // Intent
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF21262d),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Intent: ',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  enemy.intent.displayName,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _elementColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (onRetreat != null)
                _ActionButton(
                  label: 'BACK',
                  color: const Color(0xFF6e7681),
                  onTap: onRetreat,
                ),
              if (onEngage != null)
                _ActionButton(
                  label: 'ENGAGE',
                  color: const Color(0xFFf85149),
                  onTap: onEngage,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF21262d),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Door confirmation widget
class DoorConfirmation extends StatelessWidget {
  final DoorData door;
  final bool isBlocked;
  final String? blockedReason;
  final VoidCallback? onEnter;
  final VoidCallback? onCancel;

  const DoorConfirmation({
    super.key,
    required this.door,
    this.isBlocked = false,
    this.blockedReason,
    this.onEnter,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final stateColor = switch (door.state) {
      DoorState.locked => const Color(0xFF6e7681),
      DoorState.available => const Color(0xFF58a6ff),
      DoorState.cleared => const Color(0xFF3fb950),
    };

    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22).withValues(alpha: 0.95),
        border: Border.all(color: stateColor.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🚪', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                door.label ?? 'Exit',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFc9d1d9),
                ),
              ),
            ],
          ),

          if (isBlocked && blockedReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFf85149).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      blockedReason!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Color(0xFFf85149),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (onCancel != null)
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF30363d)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'BACK',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              if (onEnter != null && !isBlocked)
                GestureDetector(
                  onTap: onEnter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: stateColor.withValues(alpha: 0.2),
                      border: Border.all(color: stateColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ENTER',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: stateColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
