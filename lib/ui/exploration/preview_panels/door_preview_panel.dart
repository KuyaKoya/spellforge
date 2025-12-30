import 'package:flutter/material.dart';

import '../../../game/exploration/components/door_interactable.dart';
import 'preview_panel.dart';

/// Door preview panel (shown when approaching a door).
///
/// Displays:
/// - Destination type (Combat, Shop, Event, etc.)
/// - Locked/Available/Cleared state
/// - Breadcrumb hint (what room this is)
/// - Director reaction if blocked
class DoorPreviewPanel extends PreviewPanel {
  /// Direction of the door.
  final DoorDirection direction;

  /// Destination type for display.
  final String destinationType;

  /// Current door state.
  final DoorState doorState;

  /// Why the door is blocked (if applicable).
  final String? blockedReason;

  DoorPreviewPanel({
    super.key,
    required this.direction,
    required this.destinationType,
    this.doorState = DoorState.available,
    this.blockedReason,
    super.directorLine,
    super.onConfirm,
    super.onCancel,
  }) : super(
         title: _getTitle(destinationType),
         icon: Text(
           _getIcon(destinationType),
           style: const TextStyle(fontSize: 20),
         ),
         confirmLabel: 'ENTER',
         cancelLabel: 'BACK',
         accentColor: _getStateColor(doorState),
         riskHint: blockedReason,
         confirmEnabled:
             doorState == DoorState.available || doorState == DoorState.cleared,
       );

  static String _getTitle(String destinationType) {
    switch (destinationType.toLowerCase()) {
      case 'combat':
        return 'Combat Room';
      case 'elite':
        return 'Elite Encounter';
      case 'shop':
        return 'Shop';
      case 'rest':
        return 'Rest Site';
      case 'spell_learn':
      case 'spelllearn':
        return 'Spell Shrine';
      case 'enhancement':
      case 'enhancementshrine':
        return 'Enhancement Shrine';
      case 'event':
      case 'randomevent':
        return 'Mystery Event';
      case 'boss':
      case 'bosscombat':
        return 'Boss Chamber';
      default:
        return 'Exit';
    }
  }

  static String _getIcon(String destinationType) {
    switch (destinationType.toLowerCase()) {
      case 'combat':
        return '⚔️';
      case 'elite':
        return '💀';
      case 'shop':
        return '🏪';
      case 'rest':
        return '🛏️';
      case 'spell_learn':
      case 'spelllearn':
        return '📖';
      case 'enhancement':
      case 'enhancementshrine':
        return '⭐';
      case 'event':
      case 'randomevent':
        return '❓';
      case 'boss':
      case 'bosscombat':
        return '👹';
      default:
        return '🚪';
    }
  }

  static Color _getStateColor(DoorState state) {
    switch (state) {
      case DoorState.locked:
        return const Color(0xFF6e7681);
      case DoorState.available:
        return const Color(0xFF58a6ff);
      case DoorState.cleared:
        return const Color(0xFF3fb950);
      case DoorState.blocked:
        return const Color(0xFFf85149);
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Direction badge
        Row(
          children: [
            PreviewTag(
              text: _getDirectionLabel(direction),
              color: accentColor,
              icon: Text(direction.icon, style: const TextStyle(fontSize: 10)),
            ),
            const SizedBox(width: 8),
            PreviewTag(
              text: _getStateLabel(doorState),
              color: _getStateColor(doorState),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Destination info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF21262d),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _getIcon(destinationType),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTitle(destinationType),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFc9d1d9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDestinationHint(destinationType),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  String _getDirectionLabel(DoorDirection direction) {
    switch (direction) {
      case DoorDirection.north:
        return 'NORTH';
      case DoorDirection.south:
        return 'SOUTH';
      case DoorDirection.east:
        return 'EAST';
      case DoorDirection.west:
        return 'WEST';
    }
  }

  String _getStateLabel(DoorState state) {
    switch (state) {
      case DoorState.locked:
        return 'LOCKED';
      case DoorState.available:
        return 'OPEN';
      case DoorState.cleared:
        return 'CLEARED';
      case DoorState.blocked:
        return 'BLOCKED';
    }
  }

  String _getDestinationHint(String destinationType) {
    switch (destinationType.toLowerCase()) {
      case 'combat':
        return 'Battle awaits beyond';
      case 'elite':
        return 'A powerful foe guards this path';
      case 'shop':
        return 'Trade fragments for power';
      case 'rest':
        return 'A place to recover';
      case 'spell_learn':
      case 'spelllearn':
        return 'Learn new magic';
      case 'enhancement':
      case 'enhancementshrine':
        return 'Upgrade your spells';
      case 'event':
      case 'randomevent':
        return 'Fate awaits...';
      case 'boss':
      case 'bosscombat':
        return 'The final challenge';
      default:
        return 'Unknown destination';
    }
  }
}
