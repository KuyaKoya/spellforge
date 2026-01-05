import 'package:flutter/material.dart';
import '../../nodes/nodes.dart';

/// Node progression breadcrumbs widget.
/// LOCKED DESIGN: Symbolic, static, abstract.
///
/// Communicates progress without certainty, movement without destination.
///
/// Iconography Rules (LOCKED):
/// - Entry: Hollow circle (beginning without commitment)
/// - Combat: Split diamond (conflict, duality)
/// - Relic/Rest/Shop: Fractured square (incomplete power)
/// - Shrine: Vertical line (reinforcement, accumulation)
/// - Boss: Closed gate (barrier, not enemy)
/// - Unknown/Future: Veiled symbol (obscured future)
///
/// Visual States (LOCKED):
/// - Completed: Low opacity, desaturated
/// - Current: Subtle glow / brighter stroke
/// - Future: Blurred or abstracted
///
/// Hard Rules:
/// - No text labels
/// - No color coding by element
/// - No animations beyond glow pulse on current node
class NodeBreadcrumbs extends StatefulWidget {
  final NodeMapSystem nodeMapSystem;
  final int currentDepth;
  final int totalDepths;
  final int runNumber;

  const NodeBreadcrumbs({
    super.key,
    required this.nodeMapSystem,
    required this.currentDepth,
    required this.totalDepths,
    required this.runNumber,
  });

  @override
  State<NodeBreadcrumbs> createState() => _NodeBreadcrumbsState();
}

class _NodeBreadcrumbsState extends State<NodeBreadcrumbs>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    // Subtle glow pulse for current node only
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0d1117),
        border: Border(bottom: BorderSide(color: Color(0xFF21262d), width: 1)),
      ),
      child: Row(
        children: [
          // Loop indicator (subtle, only after first run)
          if (widget.runNumber > 1) _buildLoopIndicator(),

          // Breadcrumb trail
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildBreadcrumbs(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBreadcrumbs() {
    final widgets = <Widget>[];

    // Phase 7.6: Pre-scan for elite and boss positions
    final eliteDepths = <int>{};
    final bossDepth = widget.totalDepths; // Boss is always at final depth

    for (int depth = 1; depth <= widget.totalDepths; depth++) {
      final depthLevel = widget.nodeMapSystem.getDepthAt(depth - 1);
      if (depthLevel != null) {
        final hasElite = depthLevel.nodeChoices.any(
          (n) => n.type == NodeType.elite,
        );
        final hasBoss = depthLevel.nodeChoices.any(
          (n) => n.type == NodeType.bossCombat,
        );
        if (hasElite) eliteDepths.add(depth);
        if (hasBoss) eliteDepths.add(depth); // Treat boss positions similarly
      }
    }

    for (int depth = 1; depth <= widget.totalDepths; depth++) {
      final isPast = depth < widget.currentDepth;
      final isCurrent = depth == widget.currentDepth;
      final isFuture = depth > widget.currentDepth;

      // Get node type if available
      NodeType? nodeType;
      if (isPast || isCurrent) {
        final depthLevel = widget.nodeMapSystem.getDepthAt(depth - 1);
        if (depthLevel?.selectedNode != null) {
          nodeType = depthLevel!.selectedNode!.type;
        } else if (depthLevel != null && depthLevel.nodeChoices.isNotEmpty) {
          nodeType = depthLevel.nodeChoices.first.type;
        }
      }

      // Phase 7.6: Determine path safety visual states
      final isEliteNode = eliteDepths.contains(depth);
      final isPreBoss = depth == bossDepth - 1;
      final isPreElite = eliteDepths.contains(depth + 1) && !isPreBoss;
      final isGuaranteedSafe =
          (isPreBoss || isPreElite) && nodeType?.isNonCombat == true;

      widgets.add(
        _buildNodeIcon(
          depth: depth,
          nodeType: nodeType,
          isPast: isPast,
          isCurrent: isCurrent,
          isFuture: isFuture,
          isElite: isEliteNode,
          isPreBoss: isPreBoss,
          isGuaranteedSafe: isGuaranteedSafe,
        ),
      );

      // Connector (except after last)
      if (depth < widget.totalDepths) {
        widgets.add(
          _buildConnector(isPast: isPast, isPreBoss: depth == bossDepth - 1),
        );
      }
    }

    return widgets;
  }

  Widget _buildNodeIcon({
    required int depth,
    required NodeType? nodeType,
    required bool isPast,
    required bool isCurrent,
    required bool isFuture,
    bool isElite = false,
    bool isPreBoss = false,
    bool isGuaranteedSafe = false,
  }) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(24, 24),
          painter: _NodeIconPainter(
            nodeType: nodeType,
            isPast: isPast,
            isCurrent: isCurrent,
            isFuture: isFuture,
            glowOpacity: isCurrent ? _glowAnimation.value : 0.0,
            isElite: isElite,
            isPreBoss: isPreBoss,
            isGuaranteedSafe: isGuaranteedSafe,
          ),
        );
      },
    );
  }

  /// Phase 7.6: Connector with calm motif before boss
  Widget _buildConnector({required bool isPast, bool isPreBoss = false}) {
    // Before boss: calm, muted visual motif (Rule 16)
    final color = isPreBoss
        ? const Color(0xFF3d4a5c).withValues(alpha: 0.4)
        : (isPast
              ? const Color(0xFF30363d).withValues(alpha: 0.5)
              : const Color(0xFF21262d).withValues(alpha: 0.3));

    return Container(
      width: 12,
      height: isPreBoss ? 2 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: isPreBoss ? BorderRadius.circular(1) : null,
      ),
    );
  }

  Widget _buildLoopIndicator() {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Text(
        '${widget.runNumber}',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}

/// Custom painter for abstract node icons.
/// LOCKED ICONOGRAPHY - No literal representations.
/// Phase 7.6 additions: Elite, pre-boss, and guaranteed-safe indicators.
class _NodeIconPainter extends CustomPainter {
  final NodeType? nodeType;
  final bool isPast;
  final bool isCurrent;
  final bool isFuture;
  final double glowOpacity;
  // Phase 7.6 path safety indicators
  final bool isElite;
  final bool isPreBoss;
  final bool isGuaranteedSafe;

  _NodeIconPainter({
    required this.nodeType,
    required this.isPast,
    required this.isCurrent,
    required this.isFuture,
    required this.glowOpacity,
    this.isElite = false,
    this.isPreBoss = false,
    this.isGuaranteedSafe = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseColor = _getBaseColor();

    // Phase 7.6: Guaranteed safe node glow (faint, protective)
    if (isGuaranteedSafe && !isPast) {
      final safeGlowPaint = Paint()
        ..color = const Color(0xFF58a6ff).withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(center, 11, safeGlowPaint);
    }

    // Phase 7.6: Elite node danger glow
    if (isElite && !isPast) {
      final eliteGlowPaint = Paint()
        ..color = const Color(0xFFf85149).withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(center, 9, eliteGlowPaint);
    }

    // Glow effect for current node only
    if (isCurrent && glowOpacity > 0) {
      final glowPaint = Paint()
        ..color = const Color(0xFF8b949e).withValues(alpha: glowOpacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center, 10, glowPaint);
    }

    final paint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCurrent ? 1.5 : (isElite ? 1.5 : 1.0);

    final fillPaint = Paint()
      ..color = baseColor.withValues(alpha: isPast ? 0.1 : 0.0)
      ..style = PaintingStyle.fill;

    if (isFuture) {
      _drawVeiledSymbol(canvas, center, paint);
    } else {
      _drawNodeSymbol(canvas, center, paint, fillPaint);
    }
  }

  Color _getBaseColor() {
    // LOCKED: No element color coding - but Phase 7.6 adds danger/calm tinting
    if (isPast) {
      return const Color(
        0xFF484f58,
      ).withValues(alpha: 0.6); // Low opacity, desaturated
    } else if (isCurrent) {
      // Phase 7.6: Danger tint for elite, calm tint for pre-boss
      if (isElite) {
        return const Color(0xFFf85149); // Danger red
      } else if (isPreBoss) {
        return const Color(0xFF58a6ff); // Calm blue
      }
      return const Color(0xFF8b949e); // Brighter stroke (standard)
    } else {
      // Future nodes
      if (isElite) {
        return const Color(0xFFf85149).withValues(alpha: 0.5); // Faded danger
      } else if (isPreBoss) {
        return const Color(0xFF58a6ff).withValues(alpha: 0.4); // Faded calm
      }
      return const Color(0xFF30363d).withValues(alpha: 0.4); // Abstracted
    }
  }

  void _drawNodeSymbol(
    Canvas canvas,
    Offset center,
    Paint strokePaint,
    Paint fillPaint,
  ) {
    if (nodeType == null) {
      _drawHollowCircle(canvas, center, strokePaint);
      return;
    }

    switch (nodeType!) {
      case NodeType.combat:
      case NodeType.elite:
        _drawSplitDiamond(canvas, center, strokePaint, fillPaint);
        break;
      case NodeType.spellLearn:
      case NodeType.enhancementShrine:
        _drawVerticalLine(canvas, center, strokePaint);
        break;
      case NodeType.shop:
      case NodeType.rest:
      case NodeType.randomEvent:
        _drawFracturedSquare(canvas, center, strokePaint, fillPaint);
        break;
      case NodeType.bossCombat:
        _drawClosedGate(canvas, center, strokePaint, fillPaint);
        break;
    }
  }

  /// Entry/Unknown: Hollow circle - beginning without commitment
  void _drawHollowCircle(Canvas canvas, Offset center, Paint paint) {
    canvas.drawCircle(center, 6, paint);
  }

  /// Combat: Split diamond - conflict, duality
  void _drawSplitDiamond(
    Canvas canvas,
    Offset center,
    Paint strokePaint,
    Paint fillPaint,
  ) {
    final path = Path();
    path.moveTo(center.dx, center.dy - 7);
    path.lineTo(center.dx + 6, center.dy);
    path.lineTo(center.dx, center.dy + 7);
    path.lineTo(center.dx - 6, center.dy);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    // Split line through center
    canvas.drawLine(
      Offset(center.dx, center.dy - 4),
      Offset(center.dx, center.dy + 4),
      strokePaint,
    );
  }

  /// Relic/Rest/Shop: Fractured square - incomplete power
  void _drawFracturedSquare(
    Canvas canvas,
    Offset center,
    Paint strokePaint,
    Paint fillPaint,
  ) {
    final rect = Rect.fromCenter(center: center, width: 10, height: 10);
    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, strokePaint);

    // Fracture lines
    canvas.drawLine(
      Offset(center.dx - 5, center.dy - 2),
      Offset(center.dx + 2, center.dy + 5),
      strokePaint..strokeWidth = 0.5,
    );
  }

  /// Shrine: Vertical line - reinforcement, accumulation
  void _drawVerticalLine(Canvas canvas, Offset center, Paint strokePaint) {
    canvas.drawLine(
      Offset(center.dx, center.dy - 7),
      Offset(center.dx, center.dy + 7),
      strokePaint..strokeWidth = 2.0,
    );
    // Small horizontal marks
    canvas.drawLine(
      Offset(center.dx - 3, center.dy - 4),
      Offset(center.dx + 3, center.dy - 4),
      strokePaint..strokeWidth = 1.0,
    );
    canvas.drawLine(
      Offset(center.dx - 3, center.dy + 4),
      Offset(center.dx + 3, center.dy + 4),
      strokePaint..strokeWidth = 1.0,
    );
  }

  /// Boss: Closed gate - barrier, not enemy
  void _drawClosedGate(
    Canvas canvas,
    Offset center,
    Paint strokePaint,
    Paint fillPaint,
  ) {
    // Two vertical lines (pillars)
    canvas.drawLine(
      Offset(center.dx - 5, center.dy - 6),
      Offset(center.dx - 5, center.dy + 6),
      strokePaint..strokeWidth = 2.0,
    );
    canvas.drawLine(
      Offset(center.dx + 5, center.dy - 6),
      Offset(center.dx + 5, center.dy + 6),
      strokePaint..strokeWidth = 2.0,
    );
    // Horizontal bar (closed)
    canvas.drawLine(
      Offset(center.dx - 5, center.dy),
      Offset(center.dx + 5, center.dy),
      strokePaint..strokeWidth = 1.5,
    );
  }

  /// Future: Veiled symbol - obscured future
  void _drawVeiledSymbol(Canvas canvas, Offset center, Paint paint) {
    // Blurred/abstracted circle with fade
    final fadePaint = Paint()
      ..color = paint.color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    canvas.drawCircle(center, 5, fadePaint);

    // Small dot in center
    canvas.drawCircle(
      center,
      1.5,
      Paint()..color = paint.color.withValues(alpha: 0.3),
    );
  }

  @override
  bool shouldRepaint(covariant _NodeIconPainter oldDelegate) {
    return oldDelegate.nodeType != nodeType ||
        oldDelegate.isPast != isPast ||
        oldDelegate.isCurrent != isCurrent ||
        oldDelegate.isFuture != isFuture ||
        oldDelegate.glowOpacity != glowOpacity;
  }
}
