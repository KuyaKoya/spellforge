import 'package:flutter/material.dart';
import '../../domain/mage.dart';
import '../../domain/enemy.dart';
import '../../domain/spell.dart';
import 'battle_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// POKÉMON-STYLE ACTION BOX SYSTEM
///
/// Layout states:
/// - Root: 2x2 grid with Spells, Bag, Info, End Turn
/// - Spell Select: Grid of available spells
/// - Target Select: Enemy target buttons
/// - Inspect: Battle info display
/// ═══════════════════════════════════════════════════════════════════════════
class PokemonActionBox extends StatelessWidget {
  final BattleMenuState state;
  final Mage mage;
  final List<Enemy> enemies;
  final void Function(BattleMenuAction) onAction;
  final void Function(Spell) onSpellSelect;
  final void Function(Spell)? onSpellLongPress;
  final VoidCallback? onSpellLongPressEnd;
  final void Function(int)? onTargetSelect;

  const PokemonActionBox({
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
    switch (state) {
      case BattleMenuState.root:
        return _RootActionGrid(mage: mage, onAction: onAction);
      case BattleMenuState.spellSelect:
        return _SpellGrid(
          mage: mage,
          enemies: enemies,
          onSpellSelect: onSpellSelect,
          onSpellLongPress: onSpellLongPress,
          onSpellLongPressEnd: onSpellLongPressEnd,
          onBack: () => onAction(BattleMenuAction.back),
        );
      case BattleMenuState.targetSelect:
        return _TargetGrid(
          enemies: enemies,
          onTargetSelect: onTargetSelect,
          onBack: () => onAction(BattleMenuAction.back),
        );
      case BattleMenuState.inspect:
        return _InspectView(
          mage: mage,
          enemies: enemies,
          onBack: () => onAction(BattleMenuAction.back),
        );
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// ROOT ACTION GRID (2x2 Layout)
/// ┌─────────────────────────────┐
/// │  [ Spells ]  [ Bag ]        │
/// │  [ Info ]    [ End Turn ]   │
/// └─────────────────────────────┘
/// ═══════════════════════════════════════════════════════════════════════════
class _RootActionGrid extends StatelessWidget {
  final Mage mage;
  final void Function(BattleMenuAction) onAction;

  const _RootActionGrid({required this.mage, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'SPELLS',
                  icon: '✨',
                  color: const Color(0xFF58a6ff),
                  onTap: () => onAction(BattleMenuAction.spells),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'BAG',
                  icon: '🎒',
                  color: const Color(0xFF8b949e),
                  onTap: () => onAction(BattleMenuAction.items),
                  disabled: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'INFO',
                  icon: '📋',
                  color: const Color(0xFF8b949e),
                  onTap: () => onAction(BattleMenuAction.inspect),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'END TURN',
                  icon: '⏭️',
                  color: const Color(0xFFe3b341),
                  onTap: () => onAction(BattleMenuAction.endTurn),
                  emphasized: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// SPELL GRID (2x2 + Back button)
/// ┌─────────────────────────────┐
/// │ [Spell 1] [Spell 2]         │
/// │ [Spell 3] [Spell 4] [Back]  │
/// └─────────────────────────────┘
/// ═══════════════════════════════════════════════════════════════════════════
class _SpellGrid extends StatelessWidget {
  final Mage mage;
  final List<Enemy> enemies;
  final void Function(Spell) onSpellSelect;
  final void Function(Spell)? onSpellLongPress;
  final VoidCallback? onSpellLongPressEnd;
  final VoidCallback onBack;

  const _SpellGrid({
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
        // Spell grid (takes most of the space)
        Expanded(
          flex: 4,
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 2.0,
            shrinkWrap: true,
            // physics: const NeverScrollableScrollPhysics(),
            children: List.generate(4, (index) {
              if (index < spells.length) {
                final spell = spells[index];
                return _SpellButton(
                  spell: spell,
                  canCast: mage.canCast(spell),
                  enemies: enemies,
                  onTap: () => onSpellSelect(spell),
                  onLongPress: () => onSpellLongPress?.call(spell),
                  onLongPressEnd: onSpellLongPressEnd,
                );
              } else {
                return _EmptySpellSlot();
              }
            }),
          ),
        ),
        const SizedBox(width: 8),
        // Back button (narrow column)
        SizedBox(width: 48, child: _BackButton(onTap: onBack)),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// SPELL BUTTON (Compact 2x2 grid style)
/// Shows: Element icon + Spell name (color-coded by effectiveness)
/// ═══════════════════════════════════════════════════════════════════════════
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

  /// Get text color based on effectiveness against enemies
  Color get _textColor {
    if (!canCast) return const Color(0xFF484f58);
    if (enemies.isEmpty) return const Color(0xFFc9d1d9);

    bool hasStrong = false;
    bool hasWeak = false;

    for (final enemy in enemies) {
      final multiplier = spell.element.getMultiplierAgainst(enemy.element);
      if (multiplier > 1.0) hasStrong = true;
      if (multiplier < 1.0) hasWeak = true;
    }

    // Green = super effective, Red = not effective, Yellow = mixed, White = neutral
    if (hasStrong && !hasWeak) return const Color(0xFF3fb950);
    if (hasWeak && !hasStrong) return const Color(0xFFf85149);
    if (hasStrong && hasWeak) return const Color(0xFFe3b341);
    return const Color(0xFFc9d1d9);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canCast ? onTap : null,
      onLongPressStart: (_) => onLongPress?.call(),
      onLongPressEnd: (_) => onLongPressEnd?.call(),
      child: Container(
        decoration: BoxDecoration(
          gradient: canCast
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF2d333b), const Color(0xFF22272e)],
                )
              : null,
          color: canCast ? null : const Color(0xFF161b22),
          border: Border.all(
            color: canCast ? _elementColor : const Color(0xFF30363d),
            width: canCast ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: canCast
              ? [
                  BoxShadow(
                    color: _elementColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(spell.elementIcon, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    spell.name,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty spell slot placeholder
class _EmptySpellSlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        border: Border.all(color: const Color(0xFF21262d), width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '─',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// TARGET GRID
/// Shows clickable enemy targets
/// ═══════════════════════════════════════════════════════════════════════════
class _TargetGrid extends StatelessWidget {
  final List<Enemy> enemies;
  final void Function(int)? onTargetSelect;
  final VoidCallback onBack;

  const _TargetGrid({
    required this.enemies,
    this.onTargetSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Target list
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: enemies.asMap().entries.map((entry) {
                final index = entry.key;
                final enemy = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _TargetButton(
                    enemy: enemy,
                    onTap: () => onTargetSelect?.call(index),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Back button
        SizedBox(width: 48, child: _BackButton(onTap: onBack)),
      ],
    );
  }
}

/// Target button for enemy selection
class _TargetButton extends StatelessWidget {
  final Enemy enemy;
  final VoidCallback onTap;

  const _TargetButton({required this.enemy, required this.onTap});

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
        return const Color(0xFF8b949e);
    }
  }

  String get _elementIcon {
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

  @override
  Widget build(BuildContext context) {
    final hpPercent = (enemy.currentHP / enemy.maxHP).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _elementColor.withValues(alpha: 0.3),
              _elementColor.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(color: _elementColor, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: _elementColor.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_elementIcon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    enemy.name,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFc9d1d9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Mini HP bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF363636),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: hpPercent,
                child: Container(
                  decoration: BoxDecoration(
                    color: hpPercent > 0.5
                        ? const Color(0xFF58d854)
                        : hpPercent > 0.2
                        ? const Color(0xFFf8d030)
                        : const Color(0xFFf85888),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// INSPECT VIEW
/// Shows battle information (player and enemy stats)
/// ═══════════════════════════════════════════════════════════════════════════
class _InspectView extends StatelessWidget {
  final Mage mage;
  final List<Enemy> enemies;
  final VoidCallback onBack;

  const _InspectView({
    required this.mage,
    required this.enemies,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Player info
                _InfoCard(
                  name: mage.name,
                  hp: '${mage.currentHP}/${mage.maxHP}',
                  mp: '${mage.mana}/${mage.maxMana}',
                  isPlayer: true,
                ),
                const SizedBox(width: 8),
                // Enemy info
                ...enemies.map(
                  (enemy) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _InfoCard(
                      name: enemy.name,
                      hp: '${enemy.currentHP}/${enemy.maxHP}',
                      isPlayer: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 48, child: _BackButton(onTap: onBack)),
      ],
    );
  }
}

/// Info card for inspect view
class _InfoCard extends StatelessWidget {
  final String name;
  final String hp;
  final String? mp;
  final bool isPlayer;

  const _InfoCard({
    required this.name,
    required this.hp,
    this.mp,
    required this.isPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF21262d),
        border: Border.all(
          color: isPlayer ? const Color(0xFF58a6ff) : const Color(0xFFf85149),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFFc9d1d9),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'HP: $hp',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: Color(0xFF3fb950),
            ),
          ),
          if (mp != null)
            Text(
              'MP: $mp',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: Color(0xFF58a6ff),
              ),
            ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// SHARED COMPONENTS
/// ═══════════════════════════════════════════════════════════════════════════

/// Generic action button (for root menu)
class _ActionButton extends StatelessWidget {
  final String label;
  final String icon;
  final Color color;
  final VoidCallback onTap;
  final bool disabled;
  final bool emphasized;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.disabled = false,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = disabled ? const Color(0xFF484f58) : color;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: !disabled && emphasized
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    buttonColor.withValues(alpha: 0.3),
                    buttonColor.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: disabled
              ? const Color(0xFF161b22)
              : (emphasized ? null : const Color(0xFF21262d)),
          border: Border.all(
            color: buttonColor.withValues(alpha: disabled ? 0.3 : 0.7),
            width: emphasized ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: emphasized && !disabled
              ? [
                  BoxShadow(
                    color: buttonColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: disabled ? const Color(0xFF484f58) : buttonColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Back button
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF21262d),
          border: Border.all(color: const Color(0xFF484f58), width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, size: 16, color: Color(0xFF8b949e)),
              SizedBox(height: 2),
              Text(
                'BACK',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  color: Color(0xFF8b949e),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// SPELL DETAIL CARD (for long-press inspection overlay)
/// ═══════════════════════════════════════════════════════════════════════════
class SpellDetailCard extends StatelessWidget {
  final Spell spell;

  const SpellDetailCard({super.key, required this.spell});

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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        border: Border.all(color: _elementColor, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _elementColor.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name + Element
          Row(
            children: [
              Text(spell.elementIcon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  spell.name,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFc9d1d9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF30363d), height: 1),
          const SizedBox(height: 12),

          // Stats
          _DetailRow(
            label: 'Mana Cost',
            value: '${spell.manaCost}',
            icon: '💧',
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Damage',
            value: '${spell.baseDamage}',
            icon: '⚔️',
            valueColor: _elementColor,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Element',
            value: spell.element.displayName,
            icon: spell.elementIcon,
          ),

          // Effects (if any)
          if (spell.effects.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF30363d), height: 1),
            const SizedBox(height: 12),
            const Text(
              'EFFECTS',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8b949e),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            ...spell.effects.map(
              (effect) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${effect.toString()}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Color(0xFFc9d1d9),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          // Tap to close hint
          Center(
            child: Text(
              'Tap anywhere to close',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: Color(0xFF8b949e),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFFc9d1d9),
          ),
        ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// LEGACY BATTLE ACTION MENU (Retained for compatibility)
/// ═══════════════════════════════════════════════════════════════════════════
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
    return PokemonActionBox(
      state: state,
      mage: mage,
      enemies: enemies,
      onAction: onAction,
      onSpellSelect: onSpellSelect,
      onSpellLongPress: onSpellLongPress,
      onSpellLongPressEnd: onSpellLongPressEnd,
      onTargetSelect: onTargetSelect,
    );
  }
}
