import 'package:flutter/material.dart';

import '../../domain/mage.dart';
import '../../domain/spell.dart';
import '../../domain/element.dart' as game_element;

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

  const ExplorationHUD({
    super.key,
    required this.mage,
    this.directorActive = false,
    this.onSpellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Player status (left)
          _PlayerStatusCompact(mage: mage),

          const SizedBox(width: 16),

          // Spell icons (center)
          Expanded(
            child: _SpellBar(
              spells: mage.spellLoadout,
              primaryElement: mage.primaryElement,
              currentMana: mage.mana,
              onSpellTap: onSpellTap,
            ),
          ),

          const SizedBox(width: 16),

          // Director indicator (right)
          _DirectorIndicator(isActive: directorActive),
        ],
      ),
    );
  }
}

/// Compact player status display.
class _PlayerStatusCompact extends StatelessWidget {
  final Mage mage;

  const _PlayerStatusCompact({required this.mage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22).withValues(alpha: 0.9),
        border: Border.all(color: const Color(0xFF30363d)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mage name and element
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getElementIcon(mage.primaryElement),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Text(
                mage.name,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFc9d1d9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // HP bar
          _CompactBar(
            label: 'HP',
            current: mage.currentHP,
            max: mage.maxHP,
            color: const Color(0xFF3fb950),
          ),
          const SizedBox(height: 4),

          // Mana bar
          _CompactBar(
            label: 'MP',
            current: mage.mana,
            max: mage.maxMana,
            color: const Color(0xFF58a6ff),
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
      mainAxisSize: MainAxisSize.min,
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
        Container(
          width: 60,
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
class _SpellBar extends StatelessWidget {
  final List<Spell> spells;
  final game_element.Element primaryElement;
  final int currentMana;
  final void Function(int index)? onSpellTap;

  const _SpellBar({
    required this.spells,
    required this.primaryElement,
    required this.currentMana,
    this.onSpellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22).withValues(alpha: 0.9),
        border: Border.all(color: const Color(0xFF30363d)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              _SpellSlot(
                spell: i < spells.length ? spells[i] : null,
                slotIndex: i,
                canCast: i < spells.length && currentMana >= spells[i].manaCost,
                onTap: onSpellTap != null ? () => onSpellTap!(i) : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Individual spell slot.
class _SpellSlot extends StatelessWidget {
  final Spell? spell;
  final int slotIndex;
  final bool canCast;
  final VoidCallback? onTap;

  const _SpellSlot({
    required this.spell,
    required this.slotIndex,
    required this.canCast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (spell == null) {
      return _buildEmptySlot();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: canCast
              ? _getElementColor(spell!.element).withValues(alpha: 0.2)
              : const Color(0xFF21262d),
          border: Border.all(
            color: canCast
                ? _getElementColor(spell!.element)
                : const Color(0xFF30363d),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              spell!.elementIcon,
              style: TextStyle(
                fontSize: 14,
                color: canCast ? null : Colors.grey.shade600,
              ),
            ),
            Text(
              '${spell!.manaCost}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 7,
                fontWeight: FontWeight.w600,
                color: canCast
                    ? _getElementColor(spell!.element)
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        border: Border.all(color: const Color(0xFF30363d), width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '${slotIndex + 1}',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Color _getElementColor(game_element.Element element) {
    switch (element) {
      case game_element.Element.fire:
        return const Color(0xFFf85149);
      case game_element.Element.water:
        return const Color(0xFF58a6ff);
      case game_element.Element.earth:
        return const Color(0xFF7c6f4a);
      case game_element.Element.air:
        return const Color(0xFF79c0ff);
    }
  }
}

/// Director presence indicator.
class _DirectorIndicator extends StatefulWidget {
  final bool isActive;

  const _DirectorIndicator({required this.isActive});

  @override
  State<_DirectorIndicator> createState() => _DirectorIndicatorState();
}

class _DirectorIndicatorState extends State<_DirectorIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22).withValues(alpha: 0.9),
        border: Border.all(color: const Color(0xFF30363d)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isActive
                  ? const Color(
                      0xFFf85149,
                    ).withValues(alpha: _pulseAnimation.value)
                  : const Color(0xFF21262d),
              border: Border.all(
                color: widget.isActive
                    ? const Color(0xFFf85149)
                    : const Color(0xFF30363d),
                width: 2,
              ),
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: const Color(
                          0xFFf85149,
                        ).withValues(alpha: _pulseAnimation.value * 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '👁️',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isActive ? null : Colors.grey.shade600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
