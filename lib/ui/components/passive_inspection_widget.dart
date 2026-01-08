import 'package:flutter/material.dart';

import '../../domain/enemy_passive.dart';

/// Widget for displaying enemy passive abilities in the inspection panel.
///
/// Shows:
/// - Passive icon
/// - Passive name
/// - Trigger condition highlight
/// - Short description
/// - Active state indicators (stacks, bonuses)
///
/// Phase 7.5 UI Requirement: Enemy Inspection Panel Must Show passives.
/// Phase 7.9.3: Now shows active passive state.
class PassiveInspectionWidget extends StatelessWidget {
  /// The list of passives to display.
  final List<EnemyPassive> passives;

  /// Whether passives are always visible (bosses) or need to be discovered.
  final bool alwaysVisible;

  /// Optional accent color for styling.
  final Color? accentColor;

  /// Optional passive state for showing active bonuses.
  final PassiveState? passiveState;

  const PassiveInspectionWidget({
    super.key,
    required this.passives,
    this.alwaysVisible = false,
    this.accentColor,
    this.passiveState,
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
        // Show active state summary if available
        if (passiveState != null) _buildStateSummary(),
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
    final stateInfo = _getPassiveStateInfo(passive);

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
                Row(
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
                    // Show active state badge if applicable
                    if (stateInfo != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3fb950).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: const Color(0xFF3fb950),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          stateInfo,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3fb950),
                          ),
                        ),
                      ),
                    ],
                  ],
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

  /// Gets state info string for a specific passive.
  String? _getPassiveStateInfo(EnemyPassive passive) {
    if (passiveState == null) return null;

    switch (passive.id) {
      case 'warTemper':
        if (passiveState!.warTemperStacks > 0) {
          return '+${passiveState!.warTemperStacks} DMG';
        }
        break;
      case 'genericFrenzy':
      case 'forgeOfEndurance':
        if (passiveState!.permanentDamageBonus > 0) {
          return '+${passiveState!.permanentDamageBonus} DMG';
        }
        break;
      case 'cycloneMomentum':
        if (passiveState!.consecutiveActions > 0) {
          return '${passiveState!.consecutiveActions}x';
        }
        break;
      case 'tempestFlow':
        if (passiveState!.extraTurnCounter > 0) {
          return '${passiveState!.extraTurnCounter}/4';
        }
        break;
      case 'blazingAdaptation':
        final totalHits = passiveState!.elementHitCounts.values.fold(
          0,
          (a, b) => a + b,
        );
        if (totalHits > 0) {
          return '$totalHits hits';
        }
        break;
    }
    return null;
  }

  /// Builds a summary of active state bonuses.
  Widget _buildStateSummary() {
    final state = passiveState!;
    final bonuses = <Widget>[];

    if (state.permanentDamageBonus > 0) {
      bonuses.add(
        _buildBonusBadge(
          '⚔️ +${state.permanentDamageBonus}',
          'Permanent Damage',
          const Color(0xFFf85149),
        ),
      );
    }

    if (state.warTemperStacks > 0) {
      bonuses.add(
        _buildBonusBadge(
          '🔥 +${state.warTemperStacks}',
          'War Temper Stacks',
          const Color(0xFFf0883e),
        ),
      );
    }

    if (state.burnImmune) {
      bonuses.add(
        _buildBonusBadge(
          '🛡️ Immune',
          'Burn Immunity',
          const Color(0xFF58a6ff),
        ),
      );
    }

    if (bonuses.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 ACTIVE BONUSES',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 4, children: bonuses),
        ],
      ),
    );
  }

  Widget _buildBonusBadge(String label, String tooltip, Color color) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
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
