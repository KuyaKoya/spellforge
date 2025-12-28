import 'package:flutter/material.dart';

/// Controller for floating damage numbers.
///
/// Visual Priority (LOCKED):
/// 1. Animation
/// 2. Floating Numbers
/// 3. Status Icons
/// 4. Combat Log
///
/// Damage Numbers:
/// - Element-colored
/// - Appear near target
/// - Fade quickly
class FloatingDamageController {
  final List<_FloatingDamageData> _activeNumbers = [];
  int _idCounter = 0;

  /// Shows damage number near target.
  void showDamage({
    required int targetIndex,
    required int damage,
    required bool isPlayer,
  }) {
    final id = _idCounter++;
    _activeNumbers.add(
      _FloatingDamageData(
        id: id,
        text: '-$damage',
        isPlayer: isPlayer,
        targetIndex: targetIndex,
        type: _FloatingType.damage,
      ),
    );

    // Auto-remove after animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      _activeNumbers.removeWhere((n) => n.id == id);
    });
  }

  /// Shows status effect text near target.
  void showStatus({
    required int targetIndex,
    required String status,
    required bool isPlayer,
  }) {
    final id = _idCounter++;
    _activeNumbers.add(
      _FloatingDamageData(
        id: id,
        text: status,
        isPlayer: isPlayer,
        targetIndex: targetIndex,
        type: _FloatingType.status,
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      _activeNumbers.removeWhere((n) => n.id == id);
    });
  }

  /// Builds Flutter widgets for all active floating numbers.
  List<Widget> buildWidgets() {
    return _activeNumbers.map((data) {
      return _FloatingNumber(key: ValueKey(data.id), data: data);
    }).toList();
  }
}

enum _FloatingType { damage, status }

class _FloatingDamageData {
  final int id;
  final String text;
  final bool isPlayer;
  final int targetIndex;
  final _FloatingType type;

  _FloatingDamageData({
    required this.id,
    required this.text,
    required this.isPlayer,
    required this.targetIndex,
    required this.type,
  });
}

/// Floating damage number widget.
class _FloatingNumber extends StatefulWidget {
  final _FloatingDamageData data;

  const _FloatingNumber({super.key, required this.data});

  @override
  State<_FloatingNumber> createState() => _FloatingNumberState();
}

class _FloatingNumberState extends State<_FloatingNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    if (widget.data.type == _FloatingType.status) {
      return const Color(0xFF8b949e);
    }
    // Damage is always red for clarity
    return const Color(0xFFf85149);
  }

  @override
  Widget build(BuildContext context) {
    // Position based on target
    double top;
    double left;

    if (widget.data.isPlayer) {
      // Player damage appears bottom-left area
      top = MediaQuery.of(context).size.height - 200;
      left = 100;
    } else {
      // Enemy damage appears top-right area
      top = 100 + (widget.data.targetIndex * 50);
      left = MediaQuery.of(context).size.width - 250;
    }

    return Positioned(
      top: top,
      left: left,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: IgnorePointer(
            child: Text(
              widget.data.text,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: widget.data.type == _FloatingType.damage ? 24 : 14,
                fontWeight: FontWeight.bold,
                color: _color,
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
