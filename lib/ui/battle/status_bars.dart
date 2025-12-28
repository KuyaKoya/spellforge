import 'package:flutter/material.dart';
import '../../domain/mage.dart';
import '../../domain/enemy.dart';
import '../../domain/effect.dart';

/// Enemy status bar widget (Top-Right).
///
/// Composition (LOCKED):
/// - EnemyName + Level
/// - HPBar (animated, no numbers)
/// - ElementIcons (1-2)
/// - StatusEffectIcons
class EnemyStatusBar extends StatelessWidget {
  final List<Enemy> enemies;
  final int? selectedIndex;

  const EnemyStatusBar({super.key, required this.enemies, this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: enemies.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _EnemyStatusCard(
            enemy: entry.value,
            isSelected: entry.key == selectedIndex,
          ),
        );
      }).toList(),
    );
  }
}

class _EnemyStatusCard extends StatelessWidget {
  final Enemy enemy;
  final bool isSelected;

  const _EnemyStatusCard({required this.enemy, this.isSelected = false});

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
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        // Pokémon-style gradient background
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a1f26),
            const Color(0xFF161b22),
          ],
        ),
        border: Border.all(
          color: isSelected ? const Color(0xFFe3b341) : _elementColor.withValues(alpha: 0.5),
          width: isSelected ? 3 : 2,
        ),
        // More rounded like Pokémon UI
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? const Color(0xFFe3b341).withValues(alpha: 0.3)
                : _elementColor.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: isSelected ? 2 : 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Name + Element
          Row(
            children: [
              Expanded(
                child: Text(
                  enemy.name,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFc9d1d9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              _ElementIcon(element: enemy.element.name),
            ],
          ),
          const SizedBox(height: 6),

          // HP Bar with percentage
          Row(
            children: [
              Text(
                'HP',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _AnimatedHPBar(current: enemy.currentHP, max: enemy.maxHP),
              ),
              const SizedBox(width: 6),
              // HP Percentage
              Text(
                '${((enemy.currentHP / enemy.maxHP) * 100).round()}%',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _getHPColor(enemy.currentHP, enemy.maxHP),
                ),
              ),
            ],
          ),

          // Status effect icons (if any)
          if (enemy.statusEffects.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                ..._buildStatusIcons(),
              ],
            ),
          ],

          // Intent indicator
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF21262d),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getIntentIcon(),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                Text(
                  enemy.intent.displayName,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: _getIntentColor(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getIntentIcon() {
    switch (enemy.intent) {
      case EnemyIntent.attack:
        return '⚔️';
      case EnemyIntent.defend:
        return '🛡️';
      case EnemyIntent.debuff:
        return '💀';
    }
  }

  Color _getIntentColor() {
    switch (enemy.intent) {
      case EnemyIntent.attack:
        return const Color(0xFFf85149);
      case EnemyIntent.defend:
        return const Color(0xFF58a6ff);
      case EnemyIntent.debuff:
        return const Color(0xFFa371f7);
    }
  }

  List<Widget> _buildStatusIcons() {
    return enemy.statusEffects.take(3).map((effect) {
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: _StatusIcon(type: effect.type),
      );
    }).toList();
  }

  Color _getHPColor(int current, int max) {
    final percent = current / max;
    if (percent > 0.5) {
      return const Color(0xFF3fb950); // Green
    } else if (percent > 0.25) {
      return const Color(0xFFe3b341); // Yellow
    } else {
      return const Color(0xFFf85149); // Red
    }
  }
}

/// Player status bar widget (Bottom-Left).
///
/// Composition (LOCKED):
/// - MagePortraitSprite
/// - MageName
/// - HPBar
/// - ManaBar
/// - ElementAffinityIcon
/// - BuffDebuffIcons
///
/// Portrait Rule: Subtly changes on low HP
class PlayerStatusBar extends StatelessWidget {
  final Mage mage;

  const PlayerStatusBar({super.key, required this.mage});

  bool get _isLowHP => mage.currentHP < mage.maxHP * 0.3;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        border: Border.all(color: const Color(0xFF30363d)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          // Portrait (changes on low HP)
          _MagePortrait(element: mage.primaryElement.name, isLowHP: _isLowHP),

          const SizedBox(width: 12),

          // Stats column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name row with element
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mage.name,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFc9d1d9),
                        ),
                      ),
                    ),
                    _ElementIcon(element: mage.primaryElement.name),
                  ],
                ),
                const SizedBox(height: 6),

                // HP Bar
                _AnimatedHPBar(
                  current: mage.currentHP,
                  max: mage.maxHP,
                  height: 8,
                  showLabel: true,
                ),
                const SizedBox(height: 4),

                // Mana Bar
                _AnimatedManaBar(current: mage.mana, max: mage.maxMana),

                // Buff/Debuff icons
                if (mage.statusEffects.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _BuffDebuffRow(effects: mage.statusEffects),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated HP bar with smooth transitions.
/// LOCKED: No numbers displayed over bar.
class _AnimatedHPBar extends StatelessWidget {
  final int current;
  final int max;
  final double height;
  final bool showLabel;

  const _AnimatedHPBar({
    required this.current,
    required this.max,
    this.height = 6,
    this.showLabel = false,
  });

  double get _percentage => max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

  Color get _barColor {
    if (_percentage > 0.5) return const Color(0xFF3fb950);
    if (_percentage > 0.25) return const Color(0xFFe3b341);
    return const Color(0xFFf85149);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              'HP',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF21262d),
            borderRadius: BorderRadius.circular(2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              alignment: Alignment.centerLeft,
              widthFactor: _percentage,
              child: Container(color: _barColor),
            ),
          ),
        ),
      ],
    );
  }
}

/// Animated mana bar.
class _AnimatedManaBar extends StatelessWidget {
  final int current;
  final int max;

  const _AnimatedManaBar({required this.current, required this.max});

  double get _percentage => max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            'MP',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFF21262d),
            borderRadius: BorderRadius.circular(2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              alignment: Alignment.centerLeft,
              widthFactor: _percentage,
              child: Container(color: const Color(0xFF58a6ff)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Mage portrait placeholder.
/// Changes appearance on low HP.
class _MagePortrait extends StatelessWidget {
  final String element;
  final bool isLowHP;

  const _MagePortrait({required this.element, required this.isLowHP});

  String get _icon {
    switch (element) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isLowHP ? const Color(0xFF3d1f1f) : const Color(0xFF21262d),
        border: Border.all(
          color: isLowHP ? const Color(0xFFf85149) : const Color(0xFF30363d),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          _icon,
          style: TextStyle(
            fontSize: 20,
            // Subtle visual change on low HP
            color: isLowHP ? Colors.red.shade200 : null,
          ),
        ),
      ),
    );
  }
}

/// Element icon widget.
class _ElementIcon extends StatelessWidget {
  final String element;

  const _ElementIcon({required this.element});

  String get _icon {
    switch (element) {
      case 'fire':
        return '🔥';
      case 'water':
        return '💧';
      case 'earth':
        return '🪨';
      case 'air':
        return '💨';
      default:
        return '⚪';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_icon, style: const TextStyle(fontSize: 14));
  }
}

/// Status effect icon.
class _StatusIcon extends StatelessWidget {
  final EffectType type;

  const _StatusIcon({required this.type});

  String get _icon {
    switch (type) {
      case EffectType.burn:
        return '🔥';
      case EffectType.slow:
        return '🐌';
      case EffectType.weaken:
        return '💀';
      case EffectType.armor:
        return '🛡️';
      default:
        return '○';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: const Color(0xFF21262d),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(child: Text(_icon, style: const TextStyle(fontSize: 10))),
    );
  }
}

/// Buff/debuff icon row for player.
class _BuffDebuffRow extends StatelessWidget {
  final List<ActiveStatusEffect> effects;

  const _BuffDebuffRow({required this.effects});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: effects.take(5).map((effect) {
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: _StatusIcon(type: effect.type),
        );
      }).toList(),
    );
  }
}
