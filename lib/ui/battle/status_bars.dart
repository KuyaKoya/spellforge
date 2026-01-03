import 'package:flutter/material.dart';
import '../../domain/mage.dart';
import '../../domain/enemy.dart';
import 'status_effect_icons.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// POKÉMON-STYLE ENEMY STATUS PANEL
/// Position: Top-left of screen (Zone 1)
/// ═══════════════════════════════════════════════════════════════════════════
class PokemonEnemyStatusPanel extends StatelessWidget {
  final List<Enemy> enemies;
  final int? selectedIndex;

  const PokemonEnemyStatusPanel({
    super.key,
    required this.enemies,
    this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: enemies.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _PokemonEnemyCard(
            enemy: entry.value,
            isSelected: entry.key == selectedIndex,
          ),
        );
      }).toList(),
    );
  }
}

/// Pokémon-style enemy status card (angled nameplate with HP bar)
class _PokemonEnemyCard extends StatelessWidget {
  final Enemy enemy;
  final bool isSelected;

  const _PokemonEnemyCard({required this.enemy, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final hpPercent = (enemy.currentHP / enemy.maxHP).clamp(0.0, 1.0);

    return Container(
      width: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFF8F8F8), const Color(0xFFE8E8E8)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(4),
        ),
        border: Border.all(
          color: isSelected ? const Color(0xFFe3b341) : const Color(0xFF6b6b6b),
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
          if (isSelected)
            BoxShadow(
              color: const Color(0xFFe3b341).withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(2),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name row with element and level
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: const Color(0xFF484848),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      enemy.name.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(_getElementIcon(), style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),

            // HP bar section
            Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                children: [
                  // HP bar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF484848),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'HP',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFf8d030),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF484848),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.all(1),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Stack(
                              children: [
                                // Background
                                Container(color: const Color(0xFF363636)),
                                // HP fill
                                AnimatedFractionallySizedBox(
                                  duration: const Duration(milliseconds: 300),
                                  widthFactor: hpPercent,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: _getHPGradientColors(hpPercent),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Level and HP percentage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lv${_getLevel()}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF484848),
                        ),
                      ),
                      Text(
                        '${(hpPercent * 100).round()}%',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _getHPTextColor(hpPercent),
                        ),
                      ),
                    ],
                  ),
                  // A2.2: Status effect icons under HP bar
                  if (enemy.statusEffects.isNotEmpty)
                    EnemyStatusEffects(effects: enemy.statusEffects),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getElementIcon() {
    switch (enemy.element.name) {
      case 'fire':
        return '🔥';
      case 'water':
        return '💧';
      case 'earth':
        return '🪨';
      case 'air':
        return '💨';
      default:
        return '⚫';
    }
  }

  int _getLevel() {
    // Derive level from enemy stats
    return (enemy.maxHP ~/ 10).clamp(1, 99);
  }

  List<Color> _getHPGradientColors(double percent) {
    if (percent > 0.5) {
      return [const Color(0xFF78F878), const Color(0xFF58D858)]; // Green
    } else if (percent > 0.2) {
      return [const Color(0xFFF8E858), const Color(0xFFF8D030)]; // Yellow
    } else {
      return [const Color(0xFFF88888), const Color(0xFFF85888)]; // Red
    }
  }

  Color _getHPTextColor(double percent) {
    if (percent > 0.5) {
      return const Color(0xFF2d8a2e);
    } else if (percent > 0.2) {
      return const Color(0xFF8a6e2d);
    } else {
      return const Color(0xFF8a2d2d);
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// POKÉMON-STYLE PLAYER STATUS PANEL
/// Position: Bottom-right of screen (Zone 3)
/// ═══════════════════════════════════════════════════════════════════════════
class PokemonPlayerStatusPanel extends StatelessWidget {
  final Mage mage;

  const PokemonPlayerStatusPanel({super.key, required this.mage});

  @override
  Widget build(BuildContext context) {
    final hpPercent = (mage.currentHP / mage.maxHP).clamp(0.0, 1.0);
    final mpPercent = (mage.mana / mage.maxMana).clamp(0.0, 1.0);
    final isLowHP = hpPercent < 0.25;

    return Container(
      width: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFF8F8F8), const Color(0xFFE8E8E8)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(12),
        ),
        border: Border.all(
          color: isLowHP ? const Color(0xFFf85888) : const Color(0xFF6b6b6b),
          width: isLowHP ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(-3, 3),
            blurRadius: 0,
          ),
          if (isLowHP)
            BoxShadow(
              color: const Color(0xFFf85888).withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(2),
          bottomLeft: Radius.circular(2),
          bottomRight: Radius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: const Color(0xFF484848),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      mage.name.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(_getElementIcon(), style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),

            // HP and MP section
            Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                children: [
                  // HP bar
                  _buildStatBar(
                    label: 'HP',
                    labelColor: const Color(0xFFf8d030),
                    percent: hpPercent,
                    gradientColors: _getHPGradientColors(hpPercent),
                    height: 10,
                    showValue: true,
                    value: '${mage.currentHP}/${mage.maxHP}',
                  ),
                  const SizedBox(height: 4),

                  // MP bar (thinner)
                  _buildStatBar(
                    label: 'MP',
                    labelColor: const Color(0xFF58a6ff),
                    percent: mpPercent,
                    gradientColors: [
                      const Color(0xFF78C8F8),
                      const Color(0xFF58A6FF),
                    ],
                    height: 6,
                    showValue: true,
                    value: '${mage.mana}/${mage.maxMana}',
                  ),
                  const SizedBox(height: 4),

                  // Level
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lv${_getLevel()}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF484848),
                        ),
                      ),
                      // Buff/debuff icons placeholder
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _buildStatusIcons(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBar({
    required String label,
    required Color labelColor,
    required double percent,
    required List<Color> gradientColors,
    required double height,
    bool showValue = false,
    String? value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFF484848),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 7,
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFF484848),
              borderRadius: BorderRadius.circular(height / 2),
            ),
            padding: const EdgeInsets.all(1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(height / 2 - 1),
              child: Stack(
                children: [
                  Container(color: const Color(0xFF363636)),
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 300),
                    widthFactor: percent,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: gradientColors,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showValue && value != null) ...[
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: Color(0xFF484848),
            ),
          ),
        ],
      ],
    );
  }

  String _getElementIcon() {
    switch (mage.primaryElement.name) {
      case 'fire':
        return '🔥';
      case 'water':
        return '💧';
      case 'earth':
        return '🪨';
      case 'air':
        return '💨';
      default:
        return '🧙';
    }
  }

  int _getLevel() {
    return (mage.maxHP ~/ 5).clamp(1, 99);
  }

  List<Color> _getHPGradientColors(double percent) {
    if (percent > 0.5) {
      return [const Color(0xFF78F878), const Color(0xFF58D858)];
    } else if (percent > 0.2) {
      return [const Color(0xFFF8E858), const Color(0xFFF8D030)];
    } else {
      return [const Color(0xFFF88888), const Color(0xFFF85888)];
    }
  }

  List<Widget> _buildStatusIcons() {
    // Placeholder for buff/debuff icons
    // TODO: Integrate with mage status effects
    return [];
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// LEGACY COMPONENTS (Retained for backward compatibility)
/// ═══════════════════════════════════════════════════════════════════════════

/// Legacy enemy status bar
class EnemyStatusBar extends StatelessWidget {
  final List<Enemy> enemies;
  final int? selectedIndex;

  const EnemyStatusBar({super.key, required this.enemies, this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return PokemonEnemyStatusPanel(
      enemies: enemies,
      selectedIndex: selectedIndex,
    );
  }
}

/// Legacy player status bar
class PlayerStatusBar extends StatelessWidget {
  final Mage mage;

  const PlayerStatusBar({super.key, required this.mage});

  @override
  Widget build(BuildContext context) {
    return PokemonPlayerStatusPanel(mage: mage);
  }
}
