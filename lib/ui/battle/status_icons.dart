import 'package:flutter/material.dart';
import '../../domain/effect.dart';

/// Status effect icons display.
///
/// Phase 7 - A2.2: Status Effect Indicators
///
/// All buffs/debuffs visible as icons with:
/// - Icon for effect type
/// - Stack count badge
/// - Duration indicator
///
/// Placement:
/// - Enemy: Under HP bar
/// - Player: Next to status panel
///
/// Minimum Set: Burn, Slow, Weaken, Shield
class StatusIconsRow extends StatelessWidget {
  final List<ActiveStatusEffect> effects;
  final bool compact;

  const StatusIconsRow({
    super.key,
    required this.effects,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: compact ? 2 : 4,
      runSpacing: 2,
      children: effects.map((effect) {
        return StatusIcon(effect: effect, compact: compact);
      }).toList(),
    );
  }
}

/// Individual status effect icon.
class StatusIcon extends StatefulWidget {
  final ActiveStatusEffect effect;
  final bool compact;

  const StatusIcon({super.key, required this.effect, this.compact = false});

  @override
  State<StatusIcon> createState() => _StatusIconState();
}

class _StatusIconState extends State<StatusIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconData(widget.effect.type);
    final size = widget.compact ? 20.0 : 28.0;

    return Tooltip(
      message: widget.effect.displayText,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _shouldPulse ? _pulseAnimation.value : 1.0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: iconData.backgroundColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: iconData.borderColor,
                  width: widget.compact ? 1 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: iconData.glowColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Icon
                  Center(
                    child: Text(
                      iconData.emoji,
                      style: TextStyle(fontSize: widget.compact ? 10 : 14),
                    ),
                  ),
                  // Duration badge (bottom-right)
                  if (!widget.compact)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: _buildDurationBadge(),
                    ),
                  // Stack count badge (top-right)
                  if (widget.effect.value > 1)
                    Positioned(right: -2, top: -2, child: _buildStackBadge()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool get _shouldPulse {
    // Pulse for harmful effects
    return widget.effect.type == EffectType.burn ||
        widget.effect.type == EffectType.weaken ||
        widget.effect.type == EffectType.slow;
  }

  Widget _buildDurationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF21262d),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF30363d)),
      ),
      child: Text(
        '${widget.effect.remainingDuration}',
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8b949e),
        ),
      ),
    );
  }

  Widget _buildStackBadge() {
    final iconData = _getIconData(widget.effect.type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: iconData.borderColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'x${widget.effect.value}',
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 7,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  _StatusIconData _getIconData(EffectType type) {
    switch (type) {
      case EffectType.burn:
        return _StatusIconData(
          emoji: '🔥',
          backgroundColor: const Color(0xFF3d1a1a),
          borderColor: const Color(0xFFf85149),
          glowColor: const Color(0xFFf85149),
        );
      case EffectType.slow:
        return _StatusIconData(
          emoji: '🐌',
          backgroundColor: const Color(0xFF1a2d3d),
          borderColor: const Color(0xFF58a6ff),
          glowColor: const Color(0xFF58a6ff),
        );
      case EffectType.weaken:
        return _StatusIconData(
          emoji: '💔',
          backgroundColor: const Color(0xFF2d1a3d),
          borderColor: const Color(0xFFa371f7),
          glowColor: const Color(0xFFa371f7),
        );
      case EffectType.armor:
        return _StatusIconData(
          emoji: '🛡️',
          backgroundColor: const Color(0xFF1a3d2e),
          borderColor: const Color(0xFF3fb950),
          glowColor: const Color(0xFF3fb950),
        );
      case EffectType.actionGain:
        return _StatusIconData(
          emoji: '⚡',
          backgroundColor: const Color(0xFF3d3a1a),
          borderColor: const Color(0xFFf0e68c),
          glowColor: const Color(0xFFf0e68c),
        );
      case EffectType.delay:
        return _StatusIconData(
          emoji: '⏳',
          backgroundColor: const Color(0xFF2d2d1a),
          borderColor: const Color(0xFF8b8b6b),
          glowColor: const Color(0xFF8b8b6b),
        );
      case EffectType.damage:
        // Damage is instant, shouldn't appear as status
        return _StatusIconData(
          emoji: '💥',
          backgroundColor: const Color(0xFF3d1a1a),
          borderColor: const Color(0xFFf85149),
          glowColor: const Color(0xFFf85149),
        );
    }
  }
}

class _StatusIconData {
  final String emoji;
  final Color backgroundColor;
  final Color borderColor;
  final Color glowColor;

  const _StatusIconData({
    required this.emoji,
    required this.backgroundColor,
    required this.borderColor,
    required this.glowColor,
  });
}

/// Displays a summary of all active status effects.
class StatusEffectsSummary extends StatelessWidget {
  final List<ActiveStatusEffect> effects;
  final String label;

  const StatusEffectsSummary({
    super.key,
    required this.effects,
    this.label = 'Effects',
  });

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group effects by type
    final grouped = <EffectType, List<ActiveStatusEffect>>{};
    for (final effect in effects) {
      grouped.putIfAbsent(effect.type, () => []).add(effect);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            color: Color(0xFF8b949e),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        StatusIconsRow(effects: effects, compact: true),
      ],
    );
  }
}
