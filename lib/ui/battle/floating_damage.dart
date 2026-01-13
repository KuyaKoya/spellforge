import 'package:flutter/material.dart';
import '../../domain/element.dart' as game_element;
import '../utils/game_colors.dart';

/// Controller for floating damage numbers.
///
/// Phase 7 - A2.1: Damage Feedback
///
/// Visual Priority (LOCKED):
/// 1. Animation
/// 2. Floating Numbers
/// 3. Status Icons
/// 4. Combat Log
///
/// Damage Numbers:
/// - Color-coded by damage type
/// - Directional movement based on source
/// - Appear near target
/// - Fade quickly
///
/// Color Rules:
/// - Damage: red/orange (element-colored optional)
/// - Burn/DoT: darker red, smaller
/// - Healing: green
/// - Shield absorb: blue/gray
class FloatingDamageController {
  final List<_FloatingDamageData> _activeNumbers = [];
  int _idCounter = 0;

  /// Shows damage number near target.
  void showDamage({
    required int targetIndex,
    required int damage,
    required bool isPlayer,
    DamageType damageType = DamageType.direct,
    game_element.Element? element,
  }) {
    final id = _idCounter++;
    _activeNumbers.add(
      _FloatingDamageData(
        id: id,
        value: damage,
        text: '-$damage',
        isPlayer: isPlayer,
        targetIndex: targetIndex,
        type: _FloatingType.damage,
        damageType: damageType,
        element: element,
      ),
    );

    // Auto-remove after animation
    final duration = damageType == DamageType.burn ? 1200 : 1500;
    Future.delayed(Duration(milliseconds: duration), () {
      _activeNumbers.removeWhere((n) => n.id == id);
    });
  }

  /// Shows healing number near target.
  void showHealing({
    required int targetIndex,
    required int amount,
    required bool isPlayer,
  }) {
    final id = _idCounter++;
    _activeNumbers.add(
      _FloatingDamageData(
        id: id,
        value: amount,
        text: '+$amount',
        isPlayer: isPlayer,
        targetIndex: targetIndex,
        type: _FloatingType.damage,
        damageType: DamageType.healing,
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      _activeNumbers.removeWhere((n) => n.id == id);
    });
  }

  /// Shows shield absorb number near target.
  void showShieldAbsorb({
    required int targetIndex,
    required int amount,
    required bool isPlayer,
  }) {
    final id = _idCounter++;
    _activeNumbers.add(
      _FloatingDamageData(
        id: id,
        value: amount,
        text: '🛡️$amount',
        isPlayer: isPlayer,
        targetIndex: targetIndex,
        type: _FloatingType.damage,
        damageType: DamageType.shieldAbsorb,
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
    StatusCategory category = StatusCategory.debuff,
  }) {
    final id = _idCounter++;
    _activeNumbers.add(
      _FloatingDamageData(
        id: id,
        value: 0,
        text: status,
        isPlayer: isPlayer,
        targetIndex: targetIndex,
        type: _FloatingType.status,
        statusCategory: category,
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

/// Type of damage for color coding.
enum DamageType {
  direct, // Standard damage - red/orange
  burn, // DoT damage - darker red, smaller
  healing, // Healing - green
  shieldAbsorb, // Shield blocked - blue/gray
}

/// Category of status effect.
enum StatusCategory {
  buff, // Positive - green tint
  debuff, // Negative - red tint
  neutral, // Neutral - gray
}

enum _FloatingType { damage, status }

class _FloatingDamageData {
  final int id;
  final int value;
  final String text;
  final bool isPlayer;
  final int targetIndex;
  final _FloatingType type;
  final DamageType damageType;
  final StatusCategory statusCategory;
  final game_element.Element? element;

  _FloatingDamageData({
    required this.id,
    required this.value,
    required this.text,
    required this.isPlayer,
    required this.targetIndex,
    required this.type,
    this.damageType = DamageType.direct,
    this.statusCategory = StatusCategory.neutral,
    this.element,
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
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Burn damage animates faster
    final isBurn = widget.data.damageType == DamageType.burn;
    final duration = isBurn ? 1000 : 1200;

    _controller = AnimationController(
      duration: Duration(milliseconds: duration),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Directional slide based on damage type
    final slideEnd = _getSlideDirection();
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: slideEnd,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Pop-in effect for big damage
    final isLargeDamage = widget.data.value >= 20;
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: isLargeDamage ? 1.3 : 1.1),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: isLargeDamage ? 1.3 : 1.1, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  Offset _getSlideDirection() {
    switch (widget.data.damageType) {
      case DamageType.healing:
        // Healing floats up
        return const Offset(0, -1.5);
      case DamageType.shieldAbsorb:
        // Shield absorb slides sideways
        return const Offset(-0.5, -0.8);
      case DamageType.burn:
        // Burn floats up slowly with slight sway
        return const Offset(0.2, -1.0);
      case DamageType.direct:
        // Direct damage: player attacks go up-right, enemy attacks go up-left
        return widget.data.isPlayer
            ? const Offset(0.3, -1.2) // Damage to player
            : const Offset(-0.3, -1.2); // Damage to enemy
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    if (widget.data.type == _FloatingType.status) {
      switch (widget.data.statusCategory) {
        case StatusCategory.buff:
          return const Color(0xFF3fb950); // Green
        case StatusCategory.debuff:
          return const Color(0xFFf85149); // Red
        case StatusCategory.neutral:
          return const Color(0xFF8b949e); // Gray
      }
    }

    switch (widget.data.damageType) {
      case DamageType.direct:
        // Element-based color if provided
        if (widget.data.element != null) {
          return GameColors.getElementColor(widget.data.element!);
        }
        return const Color(0xFFf85149); // Default red
      case DamageType.burn:
        return const Color(0xFFb33a2c); // Darker red
      case DamageType.healing:
        return const Color(0xFF3fb950); // Green
      case DamageType.shieldAbsorb:
        return const Color(0xFF58a6ff); // Blue
    }
  }

  double get _fontSize {
    if (widget.data.type == _FloatingType.status) {
      return 14;
    }

    switch (widget.data.damageType) {
      case DamageType.burn:
        return 18; // Smaller for DoT
      case DamageType.shieldAbsorb:
        return 16;
      case DamageType.healing:
        return 22;
      case DamageType.direct:
        // Scale with damage
        if (widget.data.value >= 30) return 32;
        if (widget.data.value >= 20) return 28;
        return 24;
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
      // Enemy damage appears top-right area with offset per enemy
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
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration:
                    widget.data.damageType == DamageType.healing ||
                        widget.data.damageType == DamageType.shieldAbsorb
                    ? BoxDecoration(
                        color: _color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      )
                    : null,
                child: Text(
                  widget.data.text,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: _fontSize,
                    fontWeight: FontWeight.bold,
                    color: _color,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                      Shadow(
                        color: _color.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
