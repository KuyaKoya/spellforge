import 'package:flutter/material.dart';
import '../../domain/effect.dart';

/// Displays a row of status effect icons with stack counts.
class StatusEffectRow extends StatelessWidget {
  final List<ActiveStatusEffect> effects;
  final bool compact;
  final double iconSize;

  const StatusEffectRow({
    super.key,
    required this.effects,
    this.compact = false,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) return const SizedBox.shrink();

    // Group effects by type for stacking display
    final groupedEffects = <EffectType, _EffectStack>{};
    for (final effect in effects) {
      if (groupedEffects.containsKey(effect.type)) {
        groupedEffects[effect.type]!.count++;
        groupedEffects[effect.type]!.totalValue += effect.value;
        if (effect.remainingDuration >
            groupedEffects[effect.type]!.maxDuration) {
          groupedEffects[effect.type]!.maxDuration = effect.remainingDuration;
        }
      } else {
        groupedEffects[effect.type] = _EffectStack(
          type: effect.type,
          count: 1,
          totalValue: effect.value,
          maxDuration: effect.remainingDuration,
        );
      }
    }

    return Wrap(
      spacing: compact ? 4 : 6,
      runSpacing: compact ? 2 : 4,
      children: groupedEffects.values.map((stack) {
        return StatusEffectIcon(
          effectType: stack.type,
          stackCount: stack.count,
          value: stack.totalValue,
          duration: stack.maxDuration,
          size: iconSize,
          compact: compact,
        );
      }).toList(),
    );
  }
}

class _EffectStack {
  final EffectType type;
  int count;
  int totalValue;
  int maxDuration;

  _EffectStack({
    required this.type,
    required this.count,
    required this.totalValue,
    required this.maxDuration,
  });
}

/// Individual status effect icon with tooltip info.
class StatusEffectIcon extends StatelessWidget {
  final EffectType effectType;
  final int stackCount;
  final int value;
  final int duration;
  final double size;
  final bool compact;

  const StatusEffectIcon({
    super.key,
    required this.effectType,
    this.stackCount = 1,
    required this.value,
    required this.duration,
    this.size = 24,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getEffectConfig(effectType);

    return Tooltip(
      message: _getTooltipText(),
      child: Container(
        width: size + (compact ? 0 : 8),
        height: size + (compact ? 0 : 8),
        decoration: BoxDecoration(
          color: config.backgroundColor.withValues(alpha: 0.3),
          border: Border.all(
            color: config.color.withValues(alpha: 0.7),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(compact ? 4 : 6),
          boxShadow: [
            BoxShadow(
              color: config.color.withValues(alpha: 0.2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main icon
            Center(
              child: Text(config.icon, style: TextStyle(fontSize: size * 0.6)),
            ),

            // Stack count badge (if > 1)
            if (stackCount > 1)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: config.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    'x$stackCount',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Duration indicator (bottom)
            if (!compact && duration > 0)
              Positioned(
                bottom: -2,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161b22),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: config.color.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '$duration',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: config.color,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getTooltipText() {
    final config = _getEffectConfig(effectType);
    final stackText = stackCount > 1 ? ' (x$stackCount)' : '';
    return '${config.name}$stackText\n$value ${config.valueLabel}\n$duration turn(s) remaining';
  }

  _EffectConfig _getEffectConfig(EffectType type) {
    switch (type) {
      case EffectType.burn:
        return _EffectConfig(
          name: 'Burn',
          icon: '🔥',
          color: const Color(0xFFf85149),
          backgroundColor: const Color(0xFF5c1c1c),
          valueLabel: 'damage/turn',
        );
      case EffectType.slow:
        return _EffectConfig(
          name: 'Slow',
          icon: '🐌',
          color: const Color(0xFF79c0ff),
          backgroundColor: const Color(0xFF1c3a5e),
          valueLabel: 'action(s) reduced',
        );
      case EffectType.weaken:
        return _EffectConfig(
          name: 'Weaken',
          icon: '💔',
          color: const Color(0xFFa371f7),
          backgroundColor: const Color(0xFF3c2a5c),
          valueLabel: '% damage reduction',
        );
      case EffectType.armor:
        return _EffectConfig(
          name: 'Shield',
          icon: '🛡️',
          color: const Color(0xFF58a6ff),
          backgroundColor: const Color(0xFF1c3a5e),
          valueLabel: 'armor',
        );
      case EffectType.delay:
        return _EffectConfig(
          name: 'Delay',
          icon: '⏸️',
          color: const Color(0xFF8b949e),
          backgroundColor: const Color(0xFF21262d),
          valueLabel: 'turn(s)',
        );
      case EffectType.actionGain:
        return _EffectConfig(
          name: 'Haste',
          icon: '⚡',
          color: const Color(0xFFe3b341),
          backgroundColor: const Color(0xFF5c4a1c),
          valueLabel: 'extra action(s)',
        );
      case EffectType.damage:
        // Damage is instant, not a status effect
        return _EffectConfig(
          name: 'Damage',
          icon: '💥',
          color: const Color(0xFFf85149),
          backgroundColor: const Color(0xFF5c1c1c),
          valueLabel: 'damage',
        );
    }
  }
}

class _EffectConfig {
  final String name;
  final String icon;
  final Color color;
  final Color backgroundColor;
  final String valueLabel;

  const _EffectConfig({
    required this.name,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.valueLabel,
  });
}

/// Display status effects for player (horizontal row)
class PlayerStatusEffects extends StatelessWidget {
  final List<ActiveStatusEffect> effects;

  const PlayerStatusEffects({super.key, required this.effects});

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF30363d)),
      ),
      child: StatusEffectRow(effects: effects, iconSize: 22),
    );
  }
}

/// Display status effects for enemy (compact row under HP bar)
class EnemyStatusEffects extends StatelessWidget {
  final List<ActiveStatusEffect> effects;

  const EnemyStatusEffects({super.key, required this.effects});

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: StatusEffectRow(effects: effects, compact: true, iconSize: 16),
    );
  }
}
