import 'package:flutter/material.dart';
import '../../../domain/element.dart' as domain;
import '../../../systems/progression_system.dart';
import '../../../progression/elemental_path.dart';
import '../../../progression/character_progress.dart';
import 'elemental_path_view.dart';

/// The Character tab showing elemental ascension paths.
/// Phase 7.8: Meta-progression through elemental node investment.
class CharacterTab extends StatefulWidget {
  final ProgressionSystem progressionSystem;

  const CharacterTab({super.key, required this.progressionSystem});

  @override
  State<CharacterTab> createState() => _CharacterTabState();
}

class _CharacterTabState extends State<CharacterTab>
    with SingleTickerProviderStateMixin {
  domain.Element? _selectedElement;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _selectedElement == null
          ? _buildOverview()
          : ElementalPathView(
              key: ValueKey(_selectedElement),
              element: _selectedElement!,
              progressionSystem: widget.progressionSystem,
              onBack: () => setState(() => _selectedElement = null),
            ),
    );
  }

  Widget _buildOverview() {
    final crystals = widget.progressionSystem.spellCrystals;
    final progress = widget.progressionSystem.characterProgress;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Crystal display
            _buildCrystalHeader(crystals),
            const SizedBox(height: 24),

            // Title
            const Text(
              'ELEMENTAL ASCENSION',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Forge your elemental identity',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Core node (info)
            _buildCoreNode(),
            const SizedBox(height: 24),

            // Element paths
            _buildElementPaths(progress),
            const SizedBox(height: 32),

            // Active bonuses summary
            _buildActiveBonuses(progress),
          ],
        ),
      ),
    );
  }

  Widget _buildCrystalHeader(int crystals) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade900.withValues(alpha: 0.3),
            Colors.amber.shade700.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✨', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text(
            '$crystals',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'CRYSTALS',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.amber.shade200,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreNode() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.3), Colors.grey.shade800],
        ),
        border: Border.all(color: Colors.white38, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(child: Text('🌟', style: TextStyle(fontSize: 32))),
    );
  }

  Widget _buildElementPaths(CharacterProgress characterProgress) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: domain.Element.values.map((element) {
        final path = ElementalPathRegistry.getPath(element);
        final unlockedCount = characterProgress.getUnlockedCount(element);
        final maxNodes = path?.nodes.length ?? 10;
        final progress = unlockedCount / maxNodes;

        return _buildElementButton(
          element: element,
          unlockedCount: unlockedCount,
          maxNodes: maxNodes,
          progress: progress,
        );
      }).toList(),
    );
  }

  Widget _buildElementButton({
    required domain.Element element,
    required int unlockedCount,
    required int maxNodes,
    required double progress,
  }) {
    final color = _getElementColor(element);
    final canAffordNext = widget.progressionSystem.characterProgress
        .canUnlockNext(element, widget.progressionSystem.spellCrystals);

    return GestureDetector(
      onTap: () => setState(() => _selectedElement = element),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulseValue = canAffordNext
              ? 0.3 + _pulseController.value * 0.3
              : 0.0;

          return Container(
            width: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: canAffordNext
                    ? color.withValues(alpha: 0.5 + pulseValue * 0.5)
                    : color.withValues(alpha: 0.3),
                width: canAffordNext ? 2 : 1,
              ),
              boxShadow: canAffordNext
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: pulseValue),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                // Element icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.2),
                    border: Border.all(color: color),
                  ),
                  child: Center(
                    child: Text(
                      element.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Element name
                Text(
                  element.displayName.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),

                // Count
                Text(
                  '$unlockedCount / $maxNodes',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveBonuses(CharacterProgress characterProgress) {
    final benefits = characterProgress.getActiveBenefits();
    final tradeoffs = characterProgress.getActiveTradeoffs();

    if (benefits.isEmpty && tradeoffs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade700),
        ),
        child: Column(
          children: [
            Icon(Icons.spa, size: 32, color: Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(
              'No nodes unlocked yet',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap an element to begin your ascension',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACTIVE BONUSES',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
          const Divider(color: Colors.grey),
          const SizedBox(height: 8),

          // Benefits
          ...benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.add_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (tradeoffs.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(color: Colors.grey),
            const SizedBox(height: 8),
          ],

          // Tradeoffs
          ...tradeoffs.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.remove_circle,
                    size: 14,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.red.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getElementColor(domain.Element element) {
    switch (element) {
      case domain.Element.fire:
        return Colors.orange;
      case domain.Element.water:
        return Colors.blue;
      case domain.Element.earth:
        return Colors.brown;
      case domain.Element.air:
        return Colors.teal;
    }
  }
}
