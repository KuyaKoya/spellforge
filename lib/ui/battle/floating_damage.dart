import 'package:flutter/material.dart';

/// Types of floating damage for visual distinction.
enum FloatingDamageType {
  damage, // Normal damage - red/orange
  burn, // DoT damage - darker red, smaller
  healing, // HP restoration - green
  shieldAbsorb, // Damage blocked by shield - blue/gray
  status, // Status effect text - gray
  critical, // Critical hit - larger, yellow
  mana, // Mana gain/loss - blue
}

/// Controller for floating damage numbers.
///
/// Visual Priority (LOCKED):
/// 1. Animation
/// 2. Floating Numbers
/// 3. Status Icons
/// 4. Combat Log
///
/// Damage Numbers (A2.1 Spec):
/// - Damage: red/orange
/// - Burn/DoT: darker red, smaller
/// - Healing: green
/// - Shield absorb: blue/gray
/// - Appear near target with directional movement
/// - Fade quickly
class FloatingDamageController {
  final List<_FloatingDamageData> _activeNumbers = [];
  int _idCounter = 0;

  /// Shows damage number near target with type-specific styling.
  void showDamage({
    required int targetIndex,
    required int damage,
    required bool isPlayer,
    FloatingDamageType damageType = FloatingDamageType.damage,
  }) {
    final id = _idCounter++;
    final prefix = damageType == FloatingDamageType.healing ? '+' : '-';

    _activeNumbers.add(
      _FloatingDamageData(
        id: id,
        text: '$prefix$damage',
        isPlayer: isPlayer,
        targetIndex: targetIndex,
        damageType: damageType,
      ),
    );

    // Auto-remove after animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      _activeNumbers.removeWhere((n) => n.id == id);
    });
  }

  /// Shows burn/DoT damage (smaller, darker)
  void showBurnDamage({
    required int targetIndex,
    required int damage,
    required bool isPlayer,
  }) {
    showDamage(
      targetIndex: targetIndex,
      damage: damage,
      isPlayer: isPlayer,
      damageType: FloatingDamageType.burn,
    );
  }

  /// Shows healing amount (green)
  void showHealing({
    required int targetIndex,
    required int amount,
    required bool isPlayer,
  }) {
    showDamage(
      targetIndex: targetIndex,
      damage: amount,
      isPlayer: isPlayer,
      damageType: FloatingDamageType.healing,
    );
  }

  /// Shows shield absorption (blue/gray)
  void showShieldAbsorb({
    required int targetIndex,
    required int absorbed,
    required bool isPlayer,
  }) {
    final id = _idCounter++;
    _activeNumbers.add(
      _FloatingDamageData(
        id: id,
        text: '🛡️ $absorbed',
        isPlayer: isPlayer,
        targetIndex: targetIndex,
        damageType: FloatingDamageType.shieldAbsorb,
      ),
    );

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
        damageType: FloatingDamageType.status,
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

class _FloatingDamageData {
  final int id;
  final String text;
  final bool isPlayer;
  final int targetIndex;
  final FloatingDamageType damageType;

  _FloatingDamageData({
    required this.id,
    required this.text,
    required this.isPlayer,
    required this.targetIndex,
    required this.damageType,
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
    switch (widget.data.damageType) {
      case FloatingDamageType.damage:
        return const Color(0xFFf85149); // Red/orange for damage
      case FloatingDamageType.burn:
        return const Color(0xFFbd3a3a); // Darker red for burn/DoT
      case FloatingDamageType.healing:
        return const Color(0xFF3fb950); // Green for healing
      case FloatingDamageType.shieldAbsorb:
        return const Color(0xFF79c0ff); // Blue/gray for shield
      case FloatingDamageType.status:
        return const Color(0xFF8b949e); // Gray for status
      case FloatingDamageType.critical:
        return const Color(0xFFe3b341); // Yellow for critical
      case FloatingDamageType.mana:
        return const Color(0xFF58a6ff); // Blue for mana
    }
  }

  double get _fontSize {
    switch (widget.data.damageType) {
      case FloatingDamageType.damage:
      case FloatingDamageType.healing:
        return 24;
      case FloatingDamageType.critical:
        return 28;
      case FloatingDamageType.burn:
        return 18; // Smaller for DoT
      case FloatingDamageType.shieldAbsorb:
      case FloatingDamageType.mana:
        return 16;
      case FloatingDamageType.status:
        return 14;
    }
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
                fontSize: _fontSize,
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
