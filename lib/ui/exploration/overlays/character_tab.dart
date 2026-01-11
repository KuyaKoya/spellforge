import 'package:flutter/material.dart';
import '../../../domain/element.dart' as domain;
import '../../../systems/progression_system.dart';
import '../../../progression/elemental_path.dart';
import '../../../progression/character_progress.dart';
import '../../../progression/core_path.dart';
import 'elemental_path_view.dart';
import 'core_path_view.dart';
import '../../../systems/inventory_system.dart';
import '../../../data/item_definitions.dart'; // For ItemRegistry
// domain/element.dart is already imported as domain at line 2

/// The Character tab showing elemental ascension paths.
/// Phase 7.8: Meta-progression through elemental node investment.
class CharacterTab extends StatefulWidget {
  final ProgressionSystem progressionSystem;
  final InventorySystem? inventory; // Optional: Only available during a run

  const CharacterTab({
    super.key,
    required this.progressionSystem,
    this.inventory,
  });

  @override
  State<CharacterTab> createState() => _CharacterTabState();
}

class _CharacterTabState extends State<CharacterTab>
    with SingleTickerProviderStateMixin {
  domain.Element? _selectedElement;
  bool _showCorePath = false;
  bool _showRelics = false;
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
    return PopScope(
      // Only allow pop if we're at the overview (no element or core selected)
      canPop: _selectedElement == null && !_showCorePath && !_showRelics,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // If we didn't pop and have something selected, go back to overview
        if (_showCorePath) {
          setState(() => _showCorePath = false);
        } else if (_showRelics) {
          setState(() => _showRelics = false);
        } else if (_selectedElement != null) {
          setState(() => _selectedElement = null);
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showCorePath
            ? CorePathView(
                key: const ValueKey('core'),
                progressionSystem: widget.progressionSystem,
                onBack: () => setState(() => _showCorePath = false),
              )
            : _showRelics
            ? _buildRelicManager()
            : _selectedElement == null
            ? _buildOverview()
            : ElementalPathView(
                key: ValueKey(_selectedElement),
                element: _selectedElement!,
                progressionSystem: widget.progressionSystem,
                onBack: () => setState(() => _selectedElement = null),
              ),
      ),
    );
  }

  Widget _buildOverview() {
    final fragments = widget.progressionSystem.spellFragments;
    final crystals = widget.progressionSystem.spellCrystals;
    final progress = widget.progressionSystem.characterProgress;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Currency display
            _buildCurrencyHeader(fragments, crystals),
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

            // Relic Button (During Run Only)
            if (widget.inventory != null) ...[
              _buildRelicButton(),
              const SizedBox(height: 24),
            ],

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

  Widget _buildCurrencyHeader(int fragments, int crystals) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Fragments
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade900.withValues(alpha: 0.3),
                Colors.purple.shade700.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.purple.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔮', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                '$fragments',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Crystals
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              const Text('✨', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                '$crystals',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoreNode() {
    final progress = widget.progressionSystem.characterProgress;
    final corePath = CorePathRegistry.path;
    final unlockedCount = progress.unlockedCoreNodes;
    final maxNodes = corePath?.maxNodes ?? 10;
    final progressPercent = progress.getCoreProgressPercent();
    final canAfford = progress.canUnlockNextCore(
      widget.progressionSystem.spellFragments,
      widget.progressionSystem.spellCrystals,
    );

    return GestureDetector(
      onTap: () => setState(() => _showCorePath = true),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulseValue = canAfford
              ? 0.3 + _pulseController.value * 0.3
              : 0.0;

          return Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFD700).withValues(alpha: 0.4),
                      Colors.grey.shade800,
                    ],
                  ),
                  border: Border.all(
                    color: canAfford
                        ? const Color(
                            0xFFFFD700,
                          ).withValues(alpha: 0.5 + pulseValue * 0.5)
                        : Colors.white38,
                    width: canAfford ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: canAfford
                          ? const Color(
                              0xFFFFD700,
                            ).withValues(alpha: pulseValue)
                          : Colors.white.withValues(alpha: 0.2),
                      blurRadius: canAfford ? 25 : 20,
                      spreadRadius: canAfford ? 4 : 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🌟', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'CORE',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 70,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$unlockedCount / $maxNodes',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          );
        },
      ),
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

    if (benefits.isEmpty) {
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
        ],
      ),
    );
  }

  Widget _buildRelicButton() {
    return GestureDetector(
      onTap: () => setState(() => _showRelics = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF161b22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade700),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_moon, color: Colors.amber),
            const SizedBox(width: 12),
            const Text(
              'MANAGE RELICS',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelicManager() {
    if (widget.inventory == null) return const SizedBox.shrink();

    final inventory = widget.inventory!;
    final equipped = inventory.progression.equippedRelics;
    // ensure size 4
    if (equipped.length < 4) {
      for (int i = equipped.length; i < 4; i++) equipped.add('');
    }

    final owned = inventory.progression.ownedRelics;
    final activeSets = inventory.getActiveSetBonuses();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _showRelics = false),
              ),
              const Expanded(
                child: Text(
                  'RELIC LOADOUT',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance back button
            ],
          ),
          const SizedBox(height: 24),

          // Equipped Slots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final relicId = equipped[index];
              final isEmpty = relicId.isEmpty;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () {
                    // Tap to unequip
                    if (!isEmpty) {
                      setState(() {
                        inventory.unequipRelic(index);
                      });
                    }
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161b22),
                      border: Border.all(
                        color: isEmpty ? Colors.grey.shade800 : Colors.amber,
                        width: isEmpty ? 1 : 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: !isEmpty
                          ? [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.2),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isEmpty
                          ? Icon(
                              Icons.add,
                              color: Colors.grey.shade800,
                              size: 24,
                            )
                          : const Text('💍', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap slot to unequip',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // Active Set Bonuses
          if (activeSets.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1c2128),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade900),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACTIVE SET BONUSES',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...activeSets.map((element) {
                    return Text(
                      '• ${InventorySystem.getSetBonusDescription(element)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.amberAccent,
                        fontSize: 12,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Unlocked Relics List
          const Text(
            'OWNED RELICS',
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          if (owned.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No relics found. Explore deeper to find them!',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: owned.length,
            itemBuilder: (context, index) {
              final relicId = owned[index];
              final item = ItemRegistry.getItem(relicId);
              if (item == null) return const SizedBox.shrink();

              final isEquipped = equipped.contains(relicId);

              return Opacity(
                opacity: isEquipped ? 0.5 : 1.0,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161b22),
                    border: Border.all(color: Colors.grey.shade800),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: const Text('💍', style: TextStyle(fontSize: 24)),
                    title: Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: isEquipped ? Colors.grey : Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      item.description,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                    trailing: isEquipped
                        ? const Icon(Icons.check, color: Colors.green)
                        : IconButton(
                            icon: const Icon(
                              Icons.arrow_upward,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              _equipToFirstEmpty(inventory, relicId);
                            },
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _equipToFirstEmpty(InventorySystem inventory, String relicId) {
    // Find first empty slot
    final equipped = inventory.progression.equippedRelics;
    int targetSlot = -1;
    for (int i = 0; i < 4; i++) {
      // Handle list size
      if (i >= equipped.length || equipped[i].isEmpty) {
        targetSlot = i;
        break;
      }
    }

    if (targetSlot != -1) {
      setState(() {
        inventory.equipRelic(targetSlot, relicId);
      });
    } else {
      // All full, maybe show snackbar?
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No empty slots! Unequip a relic first.')),
      );
    }
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
