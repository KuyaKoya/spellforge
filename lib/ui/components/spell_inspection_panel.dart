import 'package:flutter/material.dart';
import '../../domain/spell.dart';
import '../../domain/effect.dart';

/// Spell Inspection panel widget.
/// LOCKED INTERACTION: Long-press, side-mounted, non-blocking.
///
/// Interaction Pattern (LOCKED):
/// - Primary: Long-press on spell icon
/// - Fallback: Keyboard/controller focus + inspect button
///
/// Presentation (LOCKED):
/// - Side-mounted contextual overlay
/// - NOT full modal
/// - NOT center-screen popup
/// - NOT turn-pausing screen
///
/// Content (LOCKED - exactly these):
/// - Spell Name
/// - Element (icon + label)
/// - Base Effect
/// - Current Modifiers
/// - Status Effects Applied
/// - Upgrade Tier
/// - NO flavor text during combat
///
/// Dismissal Rules (LOCKED):
/// - Tap outside overlay
/// - Release long-press
/// - NO close button
class SpellInspectionPanel extends StatelessWidget {
  final Spell spell;
  final bool isRightAligned;

  const SpellInspectionPanel({
    super.key,
    required this.spell,
    this.isRightAligned = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        border: Border.all(color: const Color(0xFF30363d), width: 1),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(-2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpellName(),
          const SizedBox(height: 8),
          _buildElement(),
          const SizedBox(height: 8),
          _buildBaseEffect(),
          if (_hasModifiers) ...[const SizedBox(height: 8), _buildModifiers()],
          if (_hasStatusEffects) ...[
            const SizedBox(height: 8),
            _buildStatusEffects(),
          ],
          const SizedBox(height: 8),
          _buildUpgradeTier(),
        ],
      ),
    );
  }

  /// Spell Name - LOCKED content
  Widget _buildSpellName() {
    return Text(
      spell.name,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFFc9d1d9),
      ),
    );
  }

  /// Element (icon + label) - LOCKED content
  Widget _buildElement() {
    return Row(
      children: [
        Text(spell.elementIcon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          spell.element.displayName,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  /// Base Effect - LOCKED content
  Widget _buildBaseEffect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Effect',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        ...spell.effects.where((e) => e.type == EffectType.damage).map((e) {
          return Text(
            '${e.value} damage',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Color(0xFFc9d1d9),
            ),
          );
        }),
        Text(
          _getTargetingText(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  String _getTargetingText() {
    final hasAoe = spell.effects.any((e) => e.targetRule == TargetRule.all);
    final hasSelf = spell.effects.any((e) => e.targetRule == TargetRule.self);

    if (hasAoe && hasSelf) return 'All + Self';
    if (hasAoe) return 'All enemies';
    if (hasSelf) return 'Self';
    return 'Single target';
  }

  bool get _hasModifiers => false; // Placeholder for modifier system

  /// Current Modifiers - LOCKED content
  Widget _buildModifiers() {
    // Placeholder for when modifier system is implemented
    return const SizedBox.shrink();
  }

  bool get _hasStatusEffects => spell.effects.any((e) => e.isStatusEffect);

  /// Status Effects Applied - LOCKED content
  Widget _buildStatusEffects() {
    final statusEffects = spell.effects.where((e) => e.isStatusEffect).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        ...statusEffects.map((e) {
          return Text(
            '${e.type.displayName}: ${e.value} × ${e.duration}t',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Color(0xFFc9d1d9),
            ),
          );
        }),
      ],
    );
  }

  /// Upgrade Tier - LOCKED content
  Widget _buildUpgradeTier() {
    return Row(
      children: [
        Text(
          'Tier',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          spell.starsDisplay,
          style: const TextStyle(fontSize: 12, color: Color(0xFFe3b341)),
        ),
      ],
    );
  }
}

/// Long-press gesture detector with spell inspection overlay.
/// LOCKED INTERACTION PATTERN.
///
/// Dismissal: Release long-press OR tap outside
/// NO close button
class SpellInspectionWrapper extends StatefulWidget {
  final Spell spell;
  final Widget child;
  final bool enabled;

  const SpellInspectionWrapper({
    super.key,
    required this.spell,
    required this.child,
    this.enabled = true,
  });

  @override
  State<SpellInspectionWrapper> createState() => _SpellInspectionWrapperState();
}

class _SpellInspectionWrapperState extends State<SpellInspectionWrapper> {
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  void _showOverlay(BuildContext context) {
    if (!widget.enabled || _overlayEntry != null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    // Side-mounted positioning - LOCKED
    // Position to the right of the element if possible, otherwise left
    double left;
    bool alignRight = false;

    if (position.dx + size.width + 250 < screenSize.width) {
      // Show to the right
      left = position.dx + size.width + 8;
    } else {
      // Show to the left
      left = position.dx - 248;
      alignRight = true;
    }

    // Vertical positioning - align with element
    double top = position.dy - 20;
    if (top < 50) top = 50;
    if (top + 200 > screenSize.height - 50) {
      top = screenSize.height - 250;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Tap outside to dismiss - NO visible scrim
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideOverlay,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),

          // Side-mounted overlay - LOCKED
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: SpellInspectionPanel(
                spell: widget.spell,
                isRightAligned: !alignRight,
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Long-press to show - LOCKED
      onLongPressStart: (_) => _showOverlay(context),
      // Release to dismiss - LOCKED
      onLongPressEnd: (_) => _hideOverlay(),
      onLongPressCancel: _hideOverlay,
      child: widget.child,
    );
  }
}
