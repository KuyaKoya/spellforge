import 'package:flutter/material.dart';

import '../../domain/enemy_passive.dart';

/// Widget for displaying enemy passive abilities in the inspection panel.
///
/// Shows:
/// - Passive icon
/// - Passive name
/// - Trigger condition highlight
/// - Short description
///
/// Phase 7.5 UI Requirement: Enemy Inspection Panel Must Show passives.
class PassiveInspectionWidget extends StatelessWidget {
  /// The list of passives to display.
  final List<EnemyPassive> passives;

  /// Whether passives are always visible (bosses) or need to be discovered.
  final bool alwaysVisible;

  /// Optional accent color for styling.
  final Color? accentColor;

  const PassiveInspectionWidget({
    super.key,
    required this.passives,
    this.alwaysVisible = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (passives.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        ...passives.map(_buildPassiveCard),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          '⚠ PASSIVES',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: accentColor ?? const Color(0xFFffd700),
            letterSpacing: 1,
          ),
        ),
        if (alwaysVisible) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFffd700).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'ALWAYS VISIBLE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 7,
                fontWeight: FontWeight.w600,
                color: Color(0xFFffd700),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPassiveCard(EnemyPassive passive) {
    final categoryColor = _getCategoryColor(passive.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF21262d),
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: categoryColor, width: 2)),
      ),
      child: Row(
        children: [
          // Icon
          Text(passive.icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          // Name and trigger
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passive.name,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFf0f6fc),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  passive.triggerHint,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8,
                    color: categoryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(PassiveCategory category) {
    switch (category) {
      case PassiveCategory.elemental:
        return const Color(0xFF79c0ff);
      case PassiveCategory.behavioral:
        return const Color(0xFFf0883e);
      case PassiveCategory.systemic:
        return const Color(0xFFbc8cff);
    }
  }
}

/// Compact version for battle UI display.
class PassiveIndicators extends StatelessWidget {
  /// The passives to show indicators for.
  final List<EnemyPassive> passives;

  /// Maximum passives to show (remaining shown as +N).
  final int maxVisible;

  const PassiveIndicators({
    super.key,
    required this.passives,
    this.maxVisible = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (passives.isEmpty) return const SizedBox.shrink();

    final visible = passives.take(maxVisible).toList();
    final remaining = passives.length - visible.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visible.map(
          (p) => Tooltip(
            message: '${p.name}: ${p.triggerHint}',
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF21262d),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(p.icon, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF21262d),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '+$remaining',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8b949e),
              ),
            ),
          ),
      ],
    );
  }
}
