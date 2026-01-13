import 'package:flutter/material.dart';

import '../../../domain/boss_enemy.dart';
import '../../../domain/elite_enemy.dart';
import '../../../domain/enemy.dart';
import '../../../domain/element.dart' as game_element;
import '../../utils/game_colors.dart';
import '../../components/passive_inspection_widget.dart';
import 'preview_panel.dart';

/// Enhanced enemy preview panel (shown when approaching an enemy).
///
/// Displays:
/// - Enemy name and element
/// - HP bar
/// - Mana bar (if applicable)
/// - Attack/Defense stats
/// - Intent indicator
/// - Passive traits
/// - Elite indicator
/// - Director reaction
class EnemyPreviewPanel extends PreviewPanel {
  /// Enemy data.
  final Enemy enemy;

  /// Whether this is an elite enemy.
  final bool isElite;

  /// Player's current spell loadout (for effectiveness hints).
  final List<game_element.Element>? playerSpellElements;

  EnemyPreviewPanel({
    super.key,
    required this.enemy,
    this.isElite = false,
    this.playerSpellElements,
    super.directorLine,
    super.onConfirm,
    super.onCancel,
  }) : super(
         title: enemy.name,
         icon: Text(
           _getElementIcon(enemy.element),
           style: const TextStyle(fontSize: 20),
         ),
         confirmLabel: 'ENGAGE',
         cancelLabel: 'BACK',
         accentColor: GameColors.getElementColor(enemy.element),
         riskHint: isElite ? 'Elite encounter - Defeat means run ends!' : null,
       );

  static String _getElementIcon(game_element.Element element) {
    switch (element) {
      case game_element.Element.fire:
        return '🔥';
      case game_element.Element.water:
        return '💧';
      case game_element.Element.earth:
        return '🪨';
      case game_element.Element.air:
        return '💨';
    }
  }

  String get _intentIcon {
    switch (enemy.intent) {
      case EnemyIntent.attack:
        return '⚔️';
      case EnemyIntent.defend:
        return '🛡️';
      case EnemyIntent.debuff:
        return '💀';
      case EnemyIntent.spell:
        return '✨';
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    // Check if this is an elite or boss enemy with passives
    final isBoss = enemy is BossEnemy;
    final eliteEnemy = enemy is EliteEnemy ? enemy as EliteEnemy : null;
    final hasPassives = eliteEnemy != null && eliteEnemy.passives.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Element, Elite, and Boss badges
        Row(
          children: [
            PreviewTag(
              text: enemy.element.displayName.toUpperCase(),
              color: accentColor,
              icon: Text(
                _getElementIcon(enemy.element),
                style: const TextStyle(fontSize: 10),
              ),
            ),
            if (isBoss) ...[
              const SizedBox(width: 8),
              const PreviewTag(
                text: 'BOSS',
                color: Color(0xFFbc8cff),
                icon: Text('⚔️', style: TextStyle(fontSize: 10)),
              ),
            ] else if (isElite) ...[
              const SizedBox(width: 8),
              const PreviewTag(
                text: 'ELITE',
                color: Color(0xFFffd700),
                icon: Text('👑', style: TextStyle(fontSize: 10)),
              ),
            ],
          ],
        ),

        const SizedBox(height: 12),

        // HP bar
        StatRow(
          label: 'HP',
          value: '${enemy.currentHP}/${enemy.maxHP}',
          barPercent: enemy.currentHP / enemy.maxHP,
          barColor: const Color(0xFF3fb950),
          valueColor: const Color(0xFF3fb950),
        ),

        const SizedBox(height: 4),

        // Note: Enemies don't use mana in this game
        const SizedBox(height: 8),

        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatBox(
              icon: '⚔️',
              label: 'ATK',
              value: '${enemy.attackDamage}',
              color: const Color(0xFFf85149),
            ),
            _StatBox(
              icon: '🛡️',
              label: 'DEF',
              value: '${enemy.armorGain}',
              color: const Color(0xFF58a6ff),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Intent indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF21262d),
            borderRadius: BorderRadius.circular(6),
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
              Text(_intentIcon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                enemy.intent.displayName.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),

        // Spell effectiveness hints
        if (playerSpellElements != null && playerSpellElements!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildEffectivenessHints(),
        ],

        // Phase 7.5: Passive display for elite and boss enemies
        if (hasPassives) ...[
          const SizedBox(height: 12),
          PassiveInspectionWidget(
            passives: eliteEnemy.passives,
            alwaysVisible: isBoss,
            accentColor: isBoss
                ? const Color(0xFFbc8cff)
                : const Color(0xFFffd700),
          ),
        ],

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEffectivenessHints() {
    final strongElements = <game_element.Element>[];
    final weakElements = <game_element.Element>[];

    for (final element in playerSpellElements!) {
      final mult = element.getMultiplierAgainst(enemy.element);
      if (mult > 1.0) {
        strongElements.add(element);
      } else if (mult < 1.0) {
        weakElements.add(element);
      }
    }

    if (strongElements.isEmpty && weakElements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SPELL EFFECTIVENESS',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            ...strongElements.map(
              (e) => PreviewTag(
                text: '✅ ${_getElementIcon(e)}',
                color: const Color(0xFF3fb950),
              ),
            ),
            ...weakElements.map(
              (e) => PreviewTag(
                text: '❌ ${_getElementIcon(e)}',
                color: const Color(0xFFf85149),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Stat box for compact display.
class _StatBox extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
