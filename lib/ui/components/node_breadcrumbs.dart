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

      widgets.add(
        _buildNodeIcon(
          depth: depth,
          nodeType: nodeType,
          isPast: isPast,
          isCurrent: isCurrent,
          isFuture: isFuture,
        ),
      );

      // Connector (except after last)
      if (depth < widget.totalDepths) {
        widgets.add(_buildConnector(isPast: isPast));
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
          ),
        );
      },
    );
  }

  Widget _buildConnector({required bool isPast}) {
    return Container(
      width: 12,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: isPast
          ? const Color(0xFF30363d).withValues(alpha: 0.5)
          : const Color(0xFF21262d).withValues(alpha: 0.3),
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
class _NodeIconPainter extends CustomPainter {
  final NodeType? nodeType;
  final bool isPast;
  final bool isCurrent;
  final bool isFuture;
  final double glowOpacity;

  _NodeIconPainter({
    required this.nodeType,
    required this.isPast,
    required this.isCurrent,
    required this.isFuture,
    required this.glowOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseColor = _getBaseColor();

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
      ..strokeWidth = isCurrent ? 1.5 : 1.0;

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
    // LOCKED: No color coding by element - all symbols use neutral palette
    if (isPast) {
      return const Color(
        0xFF484f58,
      ).withValues(alpha: 0.6); // Low opacity, desaturated
    } else if (isCurrent) {
      return const Color(0xFF8b949e); // Brighter stroke
    } else {
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
