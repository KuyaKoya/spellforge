import 'package:flutter/material.dart';

/// Combat log entry types.
/// LOCKED: System facts only, no narrative.
enum CombatLogType {
  spellCast,
  damage,
  statusEffect,
  elementalInteraction,
  turnMarker,
  enemyAction,
  system;

  /// Element icons allowed - LOCKED
  String get icon {
    switch (this) {
      case CombatLogType.spellCast:
        return '◆';
      case CombatLogType.damage:
        return '→';
      case CombatLogType.statusEffect:
        return '○';
      case CombatLogType.elementalInteraction:
        return '⚡';
      case CombatLogType.turnMarker:
        return '─';
      case CombatLogType.enemyAction:
        return '◇';
      case CombatLogType.system:
        return '·';
    }
  }
}

/// A single combat log entry.
class CombatLogEntry {
  final CombatLogType type;
  final String message;
  final Map<String, dynamic>? details;

  CombatLogEntry({required this.type, required this.message, this.details});
}

/// Combat Log panel widget.
/// LOCKED UX: System transparency - feels like a machine reporting facts.
///
/// Access:
/// - Dedicated toggle during combat
/// - Default collapsed
///
/// Visual Identity (LOCKED):
/// - High contrast
/// - Monospace or system font
/// - Clear separators
/// - Element icons allowed
///
/// Behavior:
/// - Reset every combat
/// - Hard cap on entries (last 50)
/// - Auto-scroll to latest
///
/// ABSOLUTE RULE: Numbers only. No lore. Never same event as Journey Log.
class CombatLogPanel extends StatefulWidget {
  final List<CombatLogEntry> entries;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final bool compact; // Compact mode for side panel layout

  /// LOCKED: Hard cap on entries
  static const int maxEntries = 50;

  const CombatLogPanel({
    super.key,
    required this.entries,
    this.isExpanded = false,
    this.onToggle,
    this.compact = false,
  });

  @override
  State<CombatLogPanel> createState() => _CombatLogPanelState();
}

class _CombatLogPanelState extends State<CombatLogPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant CombatLogPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to latest - LOCKED behavior
    if (widget.entries.length > oldWidget.entries.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactView();
    }
    return widget.isExpanded ? _buildExpandedView() : _buildCollapsedView();
  }

  /// Compact view for side-by-side layout in bottom bar
  Widget _buildCompactView() {
    final displayEntries = widget.entries.length > CombatLogPanel.maxEntries
        ? widget.entries.sublist(
            widget.entries.length - CombatLogPanel.maxEntries,
          )
        : widget.entries;

    return Container(
      color: const Color(0xFF0d1117),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF161b22),
              border: Border(
                bottom: BorderSide(color: Color(0xFF30363d), width: 1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'LOG',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.entries.length}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Compact entry list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(6),
              itemCount: displayEntries.length,
              itemBuilder: (context, index) {
                return _buildCompactEntry(displayEntries[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactEntry(CombatLogEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        '${entry.type.icon} ${entry.message}${entry.details != null ? ' ${_formatDetails(entry.details!)}' : ''}',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 9,
          color: Colors.grey.shade400,
          height: 1.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCollapsedView() {
    return GestureDetector(
      onTap: widget.onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF161b22),
          border: Border(top: BorderSide(color: Color(0xFF30363d), width: 1)),
        ),
        child: Row(
          children: [
            Text(
              'COMBAT LOG',
              style: TextStyle(
                // Monospace - LOCKED
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${widget.entries.length})',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.keyboard_arrow_up,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedView() {
    // Apply hard cap - LOCKED
    final displayEntries = widget.entries.length > CombatLogPanel.maxEntries
        ? widget.entries.sublist(
            widget.entries.length - CombatLogPanel.maxEntries,
          )
        : widget.entries;

    return Container(
      height: 180,
      decoration: const BoxDecoration(
        // High contrast background - LOCKED
        color: Color(0xFF0d1117),
        border: Border(top: BorderSide(color: Color(0xFF30363d), width: 1)),
      ),
      child: Column(
        children: [
          // Header with toggle
          GestureDetector(
            onTap: widget.onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF161b22),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF30363d), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'COMBAT LOG',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade400,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),

          // Entry list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: displayEntries.length,
              itemBuilder: (context, index) {
                return _buildEntry(displayEntries[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntry(CombatLogEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon - LOCKED element icons allowed
          SizedBox(
            width: 16,
            child: Text(
              entry.type.icon,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ),

          // Message - high contrast, monospace - LOCKED
          Expanded(
            child: Text(
              entry.message,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Color(0xFFc9d1d9), // High contrast
                height: 1.3,
              ),
            ),
          ),

          // Details (numbers)
          if (entry.details != null)
            Text(
              _formatDetails(entry.details!),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDetails(Map<String, dynamic> details) {
    return details.entries.map((e) => '${e.value}').join(' ');
  }
}

/// Utility class to build combat log entries.
/// LOCKED: Numbers and system facts only.
class CombatLogBuilder {
  CombatLogBuilder._();

  static CombatLogEntry spellCast(String caster, String spell, String element) {
    return CombatLogEntry(
      type: CombatLogType.spellCast,
      message: '$caster → $spell [$element]',
    );
  }

  static CombatLogEntry damage(String target, int amount, {String? type}) {
    final typeStr = type != null ? ' ($type)' : '';
    return CombatLogEntry(
      type: CombatLogType.damage,
      message: '$target$typeStr',
      details: {'dmg': amount},
    );
  }

  static CombatLogEntry statusApplied(
    String target,
    String status,
    int duration,
  ) {
    return CombatLogEntry(
      type: CombatLogType.statusEffect,
      message: '$status → $target',
      details: {'turns': duration},
    );
  }

  static CombatLogEntry elementalEffect(String effect, double multiplier) {
    return CombatLogEntry(
      type: CombatLogType.elementalInteraction,
      message: effect,
      details: {'×': multiplier},
    );
  }

  static CombatLogEntry turnMarker(int turn) {
    return CombatLogEntry(
      type: CombatLogType.turnMarker,
      message: 'Turn $turn',
    );
  }

  static CombatLogEntry enemyAction(String enemy, String action) {
    return CombatLogEntry(
      type: CombatLogType.enemyAction,
      message: '$enemy: $action',
    );
  }

  static CombatLogEntry system(String message) {
    return CombatLogEntry(type: CombatLogType.system, message: message);
  }
}
