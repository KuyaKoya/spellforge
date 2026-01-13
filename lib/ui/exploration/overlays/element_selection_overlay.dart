import 'dart:math';
import 'package:flutter/material.dart';
import '../../../domain/element.dart' as game_element;
import '../../utils/game_colors.dart';
import '../../../systems/audio_manager.dart';

class ElementSelectionOverlay extends StatefulWidget {
  final Function(game_element.Element) onElementSelected;

  const ElementSelectionOverlay({super.key, required this.onElementSelected});

  @override
  State<ElementSelectionOverlay> createState() =>
      _ElementSelectionOverlayState();
}

class _ElementSelectionOverlayState extends State<ElementSelectionOverlay>
    with SingleTickerProviderStateMixin {
  game_element.Element? _selectedElement;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getElementIcon(game_element.Element element) {
    switch (element) {
      case game_element.Element.fire:
        return Icons.local_fire_department;
      case game_element.Element.water:
        return Icons.water_drop;
      case game_element.Element.earth:
        return Icons.landscape;
      case game_element.Element.air:
        return Icons.air;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: const Text(
                'CHOOSE YOUR AFFINITY',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'Your starting element determines your initial spell and influences the world around you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Rotating background ring
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _controller.value * 2 * pi,
                            child: Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Center info
                      if (_selectedElement != null)
                        _buildCenterInfo(_selectedElement!)
                      else
                        const Text(
                          'SELECT\nONE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.grey,
                            letterSpacing: 2,
                          ),
                        ),

                      // Element buttons
                      ...game_element.Element.values.map(
                        (e) => _buildElementButton(e),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Confirm button
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedElement != null
                      ? () {
                          // Phase 7.6.2: Play base_select on start exploration
                          AudioManager.instance.playBaseSelect();
                          widget.onElementSelected(_selectedElement!);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedElement != null
                        ? GameColors.getElementColor(_selectedElement!)
                        : Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: _selectedElement != null ? 10 : 0,
                  ),
                  child: Text(
                    _selectedElement != null
                        ? 'BEGIN WITH ${_selectedElement!.name.toUpperCase()}'
                        : 'SELECT AN ELEMENT',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
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

  Widget _buildCenterInfo(game_element.Element element) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getElementIcon(element),
          size: 48,
          color: GameColors.getElementColor(element),
        ),
        const SizedBox(height: 8),
        Text(
          element.displayName.toUpperCase(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: GameColors.getElementColor(element),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        _buildAffinityRow('STRONG VS', element.strongAgainst),
        const SizedBox(height: 8),
        _buildAffinityRow('WEAK VS', element.weakAgainst),
      ],
    );
  }

  Widget _buildAffinityRow(String label, game_element.Element target) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
        Text(
          target.displayName.toUpperCase(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: GameColors.getElementColor(target),
          ),
        ),
      ],
    );
  }

  Widget _buildElementButton(game_element.Element element) {
    // Top, Right, Bottom, Left
    double angle = 0;
    switch (element) {
      case game_element.Element.fire:
        angle = -pi / 2;
        break; // Top (Fire)
      case game_element.Element.water:
        angle = pi / 2;
        break; // Bottom (Water)
      case game_element.Element.earth:
        angle = 0;
        break; // Right (Earth)
      case game_element.Element.air:
        angle = pi;
        break; // Left (Air)
    }

    final double radius = 140;

    final isSelected = _selectedElement == element;

    return Positioned(
      left: 160 + radius * cos(angle) - (isSelected ? 40 : 30),
      top: 160 + radius * sin(angle) - (isSelected ? 40 : 30),
      child: GestureDetector(
        onTap: () {
          // Phase 7.6.2: Play base_select when selecting an element
          AudioManager.instance.playBaseSelect();
          setState(() {
            _selectedElement = element;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 80 : 60,
          height: isSelected ? 80 : 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF161b22),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? GameColors.getElementColor(element)
                  : Colors.grey.shade800,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: GameColors.getElementColor(
                        element,
                      ).withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            _getElementIcon(element),
            color: isSelected
                ? GameColors.getElementColor(element)
                : Colors.grey,
            size: isSelected ? 32 : 24,
          ),
        ),
      ),
    );
  }
}
