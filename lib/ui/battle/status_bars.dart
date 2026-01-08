import 'package:flutter/material.dart';
import '../../domain/mage.dart';
import '../../domain/enemy.dart';
import '../../domain/elite_enemy.dart';
import '../../systems/shop_system.dart';
import 'status_icons.dart';

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
                  // Phase 7 A2.2: Status effect icons under HP bar
                  if (enemy.statusEffects.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    StatusIconsRow(effects: enemy.statusEffects, compact: true),
                  ],
                  // Phase 7.9.3: Passive ability icons for elite/boss enemies
                  ..._buildPassiveIcons(),
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

  /// Builds passive icons for elite/boss enemies.
  List<Widget> _buildPassiveIcons() {
    if (enemy is! EliteEnemy) return [];

    final elite = enemy as EliteEnemy;
    if (elite.passives.isEmpty) return [];

    return [
      const SizedBox(height: 4),
      PassiveIconsRow(
        passives: elite.passives
            .map(
              (p) => PassiveDisplayInfo(
                icon: p.icon,
                name: p.name,
                description: p.description,
                triggerHint: p.triggerHint,
                category: p.category.name,
              ),
            )
            .toList(),
        compact: true,
      ),
    ];
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// POKÉMON-STYLE PLAYER STATUS PANEL
/// Position: Bottom-right of screen (Zone 3)
/// ═══════════════════════════════════════════════════════════════════════════
class PokemonPlayerStatusPanel extends StatelessWidget {
  final Mage mage;
  final List<TemporaryBuff>? temporaryBuffs;
  final int? currentExpOverride;
  final int? maxExpOverride;
  final int? levelOverride;

  const PokemonPlayerStatusPanel({
    super.key,
    required this.mage,
    this.temporaryBuffs,
    this.currentExpOverride,
    this.maxExpOverride,
    this.levelOverride,
  });

  @override
  Widget build(BuildContext context) {
    final currentExp = currentExpOverride ?? mage.currentExp;
    final maxExp =
        maxExpOverride ?? (mage.expToNextLevel > 0 ? mage.expToNextLevel : 1);
    final level = levelOverride ?? mage.level;
    // If override is provided, calculate percent from it. Otherwise use mage.expProgress if available, or calculate.
    // Since we have local variables now, just calculate.
    final expPercent = (currentExp / maxExp).clamp(0.0, 1.0);

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

                  // EXP bar
                  _buildStatBar(
                    label: 'EXP',
                    labelColor: const Color(0xFFf8d030),
                    percent: expPercent,
                    gradientColors: [
                      const Color(0xFFF8E858),
                      const Color(0xFFF8D030),
                    ],
                    height: 4,
                    showValue: true,
                    value:
                        '$currentExp/${maxExp == 1 && mage.expToNextLevel <= 0 ? "MAX" : maxExp}',
                  ),
                  const SizedBox(height: 4),

                  // Level and stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lv$level',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF484848),
                        ),
                      ),
                      // ATK/DEF/SPD
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatChip('⚔️', mage.attack),
                          const SizedBox(width: 2),
                          _buildStatChip('🛡️', mage.defense),
                          const SizedBox(width: 2),
                          _buildStatChip('💨', mage.speed),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Buff/debuff icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [..._buildBuffIcons(), ..._buildStatusIcons()],
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

  Widget _buildStatChip(String icon, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 6)),
          Text(
            '$value',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 7,
              fontWeight: FontWeight.w600,
              color: Color(0xFF484848),
            ),
          ),
        ],
      ),
    );
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
    // Phase 7 A2.2: Status effect icons next to player panel
    if (mage.statusEffects.isEmpty) {
      return [];
    }
    return [StatusIconsRow(effects: mage.statusEffects, compact: true)];
  }

  List<Widget> _buildBuffIcons() {
    final activeBuffs = temporaryBuffs?.where((b) => b.isActive).toList() ?? [];
    if (activeBuffs.isEmpty) return [];

    return activeBuffs.map((buff) {
      return Padding(
        padding: const EdgeInsets.only(right: 4),
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
                const Text('⚡', style: TextStyle(fontSize: 8)),
                const SizedBox(width: 2),
                Text(
                  '+${buff.value}%',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3fb950),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  '${buff.remainingNodes}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 7,
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
