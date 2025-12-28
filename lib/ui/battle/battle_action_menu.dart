import 'package:flutter/material.dart';
import '../../domain/mage.dart';
import '../../domain/enemy.dart';
import '../../domain/spell.dart';
import 'battle_screen.dart';

/// Battle action menu with 2x2 grid layout.
///
/// Root Menu (LOCKED):
/// - Spells
/// - Inspect
/// - Items
/// - Retreat
///
/// Interaction (LOCKED):
/// - Tap → Cast/Select
/// - Long-press → SpellDetailOverlay
class BattleActionMenu extends StatelessWidget {
  final BattleMenuState state;
  final Mage mage;
  final List<Enemy> enemies;
  final void Function(BattleMenuAction) onAction;
  final void Function(Spell) onSpellSelect;
  final void Function(Spell)? onSpellLongPress;
  final VoidCallback? onSpellLongPressEnd;
  final void Function(int)? onTargetSelect;

  const BattleActionMenu({
    super.key,
    required this.state,
    required this.mage,
    required this.enemies,
    required this.onAction,
    required this.onSpellSelect,
    this.onSpellLongPress,
    this.onSpellLongPressEnd,
    this.onTargetSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Fixed width removed - adapts to parent Flex
      padding: const EdgeInsets.all(4),
      // Decoration removed - visually cleaner in bottom bar
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (state) {
      case BattleMenuState.root:
        return _RootMenu(onAction: onAction);
      case BattleMenuState.spellSelect:
        return _SpellSelectMenu(
          mage: mage,
          enemies: enemies,
          onSpellSelect: onSpellSelect,
          onSpellLongPress: onSpellLongPress,
          onSpellLongPressEnd: onSpellLongPressEnd,
          onBack: () => onAction(BattleMenuAction.back),
        );
      case BattleMenuState.targetSelect:
        return _TargetSelectMenu(
          enemies: enemies,
          onTargetSelect: onTargetSelect,
          onBack: () => onAction(BattleMenuAction.back),
        );
      case BattleMenuState.inspect:
        return _InspectMenu(
          mage: mage,
          enemies: enemies,
          onBack: () => onAction(BattleMenuAction.back),
        );
    }
  }
}

/// Root action menu (2x2 grid).
class _RootMenu extends StatelessWidget {
  final void Function(BattleMenuAction) onAction;

  const _RootMenu({required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MenuButton(
            label: 'SPELLS',
            icon: '✨',
            onTap: () => onAction(BattleMenuAction.spells),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _MenuButton(
            label: 'INSPECT',
            icon: '🔍',
            onTap: () => onAction(BattleMenuAction.inspect),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _MenuButton(
            label: 'ITEMS',
            icon: '🎒',
            onTap: () => onAction(BattleMenuAction.items),
            disabled: true,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _MenuButton(
            label: 'RETREAT',
            icon: '🚪',
            onTap: () => onAction(BattleMenuAction.retreat),
            color: const Color(0xFF6e7681),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _MenuButton(
            label: 'END TURN',
            icon: '⏭️',
            onTap: () => onAction(BattleMenuAction.endTurn),
            color: const Color(0xFFe3b341),
          ),
        ),
      ],
    );
  }
}

/// Spell selection menu (2x2 grid).
class _SpellSelectMenu extends StatelessWidget {
  final Mage mage;
  final List<Enemy> enemies;
  final void Function(Spell) onSpellSelect;
  final void Function(Spell)? onSpellLongPress;
  final VoidCallback? onSpellLongPressEnd;
  final VoidCallback onBack;

  const _SpellSelectMenu({
    required this.mage,
    required this.enemies,
    required this.onSpellSelect,
    this.onSpellLongPress,
    this.onSpellLongPressEnd,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final spells = mage.spellLoadout;

    return Row(
      children: [
        _BackButton(onTap: onBack),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: spells.map((spell) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _SpellButton(
                    spell: spell,
                    canCast: mage.canCast(spell),
                    enemies: enemies,
                    onTap: () => onSpellSelect(spell),
                    onLongPress: () => onSpellLongPress?.call(spell),
                    onLongPressEnd: onSpellLongPressEnd,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Spell button with element accent, mana cost, and effectiveness indicator.
class _SpellButton extends StatelessWidget {
  final Spell spell;
  final bool canCast;
  final List<Enemy> enemies;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onLongPressEnd;

  const _SpellButton({
    required this.spell,
    required this.canCast,
    required this.enemies,
    required this.onTap,
    this.onLongPress,
    this.onLongPressEnd,
  });

  Color get _elementColor {
    switch (spell.element.name) {
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

  /// Get the best effectiveness indicator against current enemies
  String get _effectivenessIndicator {
    if (enemies.isEmpty) return '';
    
    bool hasStrong = false;
    bool hasWeak = false;
    
    for (final enemy in enemies) {
      final multiplier = spell.element.getMultiplierAgainst(enemy.element);
      if (multiplier > 1.0) hasStrong = true;
      if (multiplier < 1.0) hasWeak = true;
    }
    
    if (hasStrong && !hasWeak) return '▲'; // All effective or mixed
    if (hasWeak && !hasStrong) return '▼'; // All weak
    if (hasStrong && hasWeak) return '●'; // Mixed
    return ''; // All neutral
  }

  Color get _effectivenessColor {
    if (enemies.isEmpty) return Colors.transparent;
    
    bool hasStrong = false;
    bool hasWeak = false;
    
    for (final enemy in enemies) {
      final multiplier = spell.element.getMultiplierAgainst(enemy.element);
      if (multiplier > 1.0) hasStrong = true;
      if (multiplier < 1.0) hasWeak = true;
    }
    
    if (hasStrong && !hasWeak) return const Color(0xFF3fb950); // Green
    if (hasWeak && !hasStrong) return const Color(0xFFf85149); // Red
    if (hasStrong && hasWeak) return const Color(0xFFe3b341); // Yellow
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canCast ? onTap : null,
      onLongPressStart: (_) => onLongPress?.call(),
      onLongPressEnd: (_) => onLongPressEnd?.call(),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: canCast ? const Color(0xFF21262d) : const Color(0xFF161b22),
          border: Border.all(
            color: canCast ? _elementColor : const Color(0xFF30363d),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            // Icon with effectiveness indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(spell.elementIcon, style: const TextStyle(fontSize: 16)),
                if (_effectivenessIndicator.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      _effectivenessIndicator,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _effectivenessColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),

            // Name (truncated)
            Text(
              spell.name,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: canCast
                    ? const Color(0xFFc9d1d9)
                    : const Color(0xFF484f58),
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            // Mana cost
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '💧${spell.manaCost}',
                  style: TextStyle(
                    fontSize: 8,
                    color: canCast
                        ? const Color(0xFF58a6ff)
                        : const Color(0xFF484f58),
                  ),
                ),
                // Modifier glyphs (if any)
                if (spell.starLevel > 1)
                  Text(
                    ' ${'★' * (spell.starLevel - 1)}',
                    style: const TextStyle(
                      fontSize: 7,
                      color: Color(0xFFe3b341),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Target selection menu.
class _TargetSelectMenu extends StatelessWidget {
  final List<Enemy> enemies;
  final void Function(int)? onTargetSelect;
  final VoidCallback onBack;

  const _TargetSelectMenu({
    required this.enemies,
    this.onTargetSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BackButton(onTap: onBack),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: enemies.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: SizedBox(
                    width: 120, // Specific width for target buttons
                    child: _MenuButton(
                      label: entry.value.name,
                      icon: entry.value.element.displayName.characters.first,
                      onTap: () => onTargetSelect?.call(entry.key),
                      color: const Color(0xFFf85149),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Inspect menu for viewing battle state.
class _InspectMenu extends StatelessWidget {
  final Mage mage;
  final List<Enemy> enemies;
  final VoidCallback onBack;

  const _InspectMenu({
    required this.mage,
    required this.enemies,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BackButton(onTap: onBack),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Player
                 Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 4),
                  child: _InspectItem(
                    label: mage.name,
                    detail: '${mage.currentHP}/${mage.maxHP} HP',
                  ),
                ),
                // Enemies
                ...enemies.map((enemy) {
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 4),
                    child: _InspectItem(
                      label: enemy.name,
                      detail: '${enemy.currentHP}/${enemy.maxHP} HP',
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Simple inspect item row.
class _InspectItem extends StatelessWidget {
  final String label;
  final String detail;

  const _InspectItem({required this.label, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF21262d),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Color(0xFFc9d1d9),
            ),
          ),
          Text(
            detail,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic menu button.
class _MenuButton extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;
  final Color? color;
  final bool disabled;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = disabled
        ? const Color(0xFF30363d)
        : (color ?? const Color(0xFF58a6ff));

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFF161b22) : const Color(0xFF21262d),
          border: Border.all(color: buttonColor.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: disabled ? const Color(0xFF484f58) : buttonColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Back button.
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF30363d)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '← BACK',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}
