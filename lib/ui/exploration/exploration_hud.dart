import 'package:flutter/material.dart';

import '../../domain/mage.dart';
import '../../domain/element.dart' as game_element;
import '../../systems/shop_system.dart';

/// Minimal, icon-driven exploration HUD.
///
/// Always visible during exploration:
/// - Compact HP/Mana bars (bottom-left)
/// - Spell icons (4 slots, bottom-center)
/// - Director indicator (bottom-right)
class ExplorationHUD extends StatelessWidget {
  /// Player's mage.
  final Mage mage;

  /// Whether the Director is active.
  final bool directorActive;

  /// Callback when a spell is tapped for inspection.
  final void Function(int index)? onSpellTap;

  /// Temporary buffs active on the player.
  final List<TemporaryBuff>? temporaryBuffs;

  const ExplorationHUD({
    super.key,
    required this.mage,
    this.directorActive = false,
    this.onSpellTap,
    this.temporaryBuffs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => _showStatsOverlay(context),
        child: SizedBox(
          width: double.infinity,
          child: _PlayerStatusCompact(
            mage: mage,
            temporaryBuffs: temporaryBuffs,
          ),
        ),
      ),
    );
  }

  void _showStatsOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          _PlayerStatsOverlay(mage: mage, temporaryBuffs: temporaryBuffs),
    );
  }
}

/// Compact player status display.
class _PlayerStatusCompact extends StatelessWidget {
  final Mage mage;
  final List<TemporaryBuff>? temporaryBuffs;

  const _PlayerStatusCompact({required this.mage, this.temporaryBuffs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Identity & Stats
          Row(
            children: [
              // Identity
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getElementIcon(mage.primaryElement),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    mage.name,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFc9d1d9),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Level badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf8d030).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFFf8d030).withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Lv${mage.level}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFf8d030),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              if (temporaryBuffs != null) ..._buildBuffIcons(),
              const Spacer(),
              // Stats
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatChip(
                    label: 'ATK',
                    value: mage.attack,
                    color: const Color(0xFFf85149),
                  ),
                  const SizedBox(width: 6),
                  _StatChip(
                    label: 'DEF',
                    value: mage.defense,
                    color: const Color(0xFF58a6ff),
                  ),
                  const SizedBox(width: 6),
                  _StatChip(
                    label: 'SPD',
                    value: mage.speed,
                    color: const Color(0xFF79c0ff),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Bars
          Row(
            children: [
              // HP
              Expanded(
                child: _CompactBar(
                  label: 'HP',
                  current: mage.currentHP,
                  max: mage.maxHP,
                  color: const Color(0xFF3fb950),
                ),
              ),
              const SizedBox(width: 16),
              // MP
              Expanded(
                child: _CompactBar(
                  label: 'MP',
                  current: mage.mana,
                  max: mage.maxMana,
                  color: const Color(0xFF58a6ff),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 3: EXP (Full width)
          _CompactBar(
            label: 'EXP',
            current: mage.currentExp,
            max: mage.expToNextLevel > 0 ? mage.expToNextLevel : 1,
            color: const Color(0xFFf8d030),
          ),
        ],
      ),
    );
  }

  String _getElementIcon(game_element.Element element) {
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

  List<Widget> _buildBuffIcons() {
    final activeBuffs = temporaryBuffs?.where((b) => b.isActive).toList() ?? [];
    if (activeBuffs.isEmpty) return [];

    return activeBuffs.map((buff) {
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Tooltip(
          message: buff.displayText,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF3fb950).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF3fb950), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚡', style: TextStyle(fontSize: 9)),
                const SizedBox(width: 2),
                Text(
                  '+${buff.value}%',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3fb950),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  '${buff.remainingNodes}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8,
                    color: Color(0xFF3fb950),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

/// Stat chip for displaying ATK/DEF/SPD.
class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 7,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '$value',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact stat bar.
class _CompactBar extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final Color color;

  const _CompactBar({
    required this.label,
    required this.current,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF21262d),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$current',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Spell bar showing 4 spell slots.
/// Overlay showing full player stats.
class _PlayerStatsOverlay extends StatelessWidget {
  final Mage mage;
  final List<TemporaryBuff>? temporaryBuffs;

  const _PlayerStatsOverlay({required this.mage, this.temporaryBuffs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0d1117),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: const Color(0xFF30363d)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PLAYER STATUS',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8b949e),
                  letterSpacing: 2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Color(0xFF30363d)),
          const SizedBox(height: 16),

          // Identity & Level
          Row(
            children: [
              Text(
                _getElementIcon(mage.primaryElement),
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mage.name,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Level ${mage.level} Mage',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFF8b949e),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // EXP Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'EXP: ${mage.currentExp} / ${mage.expToNextLevel > 0 ? mage.expToNextLevel : "MAX"}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFFf8d030),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 100,
                    height: 4,
                    child: LinearProgressIndicator(
                      value: mage.expProgress,
                      backgroundColor: const Color(0xFF21262d),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFf8d030),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatColumn(
                  'HP',
                  '${mage.currentHP}/${mage.maxHP}',
                  const Color(0xFF3fb950),
                ),
              ),
              Expanded(
                child: _buildStatColumn(
                  'MP',
                  '${mage.mana}/${mage.maxMana}',
                  const Color(0xFF58a6ff),
                ),
              ),
              Expanded(
                child: _buildStatColumn(
                  'ATK',
                  '${mage.attack}',
                  const Color(0xFFf85149),
                ),
              ),
              Expanded(
                child: _buildStatColumn(
                  'DEF',
                  '${mage.defense}',
                  const Color(0xFF58a6ff),
                ),
              ),
              Expanded(
                child: _buildStatColumn(
                  'SPD',
                  '${mage.speed}',
                  const Color(0xFF79c0ff),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Buffs
          if (temporaryBuffs != null && temporaryBuffs!.isNotEmpty) ...[
            const Text(
              'ACTIVE BUFFS',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8b949e),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: temporaryBuffs!.where((b) => b.isActive).map((buff) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3fb950).withValues(alpha: 0.2),
                    border: Border.all(color: const Color(0xFF3fb950)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    buff.displayText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFF3fb950),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Spells
          const Text(
            'SPELL LOADOUT',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8b949e),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: mage.spellLoadout.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final spell = mage.spellLoadout[index];
                return Container(
                  width: 200,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161b22),
                    border: Border.all(color: const Color(0xFF30363d)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        spell.elementIcon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              spell.name,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${spell.manaCost} MP',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: Color(0xFF58a6ff),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getElementIcon(game_element.Element element) {
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
}
