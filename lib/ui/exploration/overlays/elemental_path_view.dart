import 'package:flutter/material.dart';
import '../../../domain/element.dart' as domain;
import '../../../systems/progression_system.dart';
import '../../../progression/elemental_path.dart';
import '../../../progression/elemental_node.dart';

/// Displays a single elemental path with all its nodes.
/// Allows unlocking nodes with crystals.
class ElementalPathView extends StatefulWidget {
  final domain.Element element;
  final ProgressionSystem progressionSystem;
  final VoidCallback onBack;

  const ElementalPathView({
    super.key,
    required this.element,
    required this.progressionSystem,
    required this.onBack,
  });

  @override
  State<ElementalPathView> createState() => _ElementalPathViewState();
}

class _ElementalPathViewState extends State<ElementalPathView>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  int? _selectedNodeIndex;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  ElementalPath? get _path => ElementalPathRegistry.getPath(widget.element);

  int get _unlockedCount => widget.progressionSystem.characterProgress
      .getUnlockedCount(widget.element);

  int get _crystals => widget.progressionSystem.spellCrystals;

  Color get _elementColor {
    switch (widget.element) {
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

  @override
  Widget build(BuildContext context) {
    final path = _path;
    if (path == null) {
      return Center(
        child: Text(
          'Path not found',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return Column(
      children: [
        // Header
        _buildHeader(path),

        // Node list
        Expanded(child: _buildNodeList(path)),

        // Preview panel (if node selected)
        if (_selectedNodeIndex != null)
          _buildPreviewPanel(path.nodes[_selectedNodeIndex!]),
      ],
    );
  }

  Widget _buildHeader(ElementalPath path) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_elementColor.withValues(alpha: 0.3), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
              ),

              const Spacer(),

              // Crystal display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      '$_crystals',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Element title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(path.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.element.displayName.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _elementColor,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    path.theme,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$_unlockedCount / ${path.nodes.length}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Colors.grey.shade300,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _unlockedCount / path.nodes.length,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: AlwaysStoppedAnimation(_elementColor),
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNodeList(ElementalPath path) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: path.nodes.length,
      itemBuilder: (context, index) {
        final node = path.nodes[index];
        final isUnlocked = index < _unlockedCount;
        final isNext = index == _unlockedCount;
        final isSelected = _selectedNodeIndex == index;
        final canAfford = isNext && _crystals >= node.cost;

        return _buildNodeItem(
          node: node,
          index: index,
          isUnlocked: isUnlocked,
          isNext: isNext,
          isSelected: isSelected,
          canAfford: canAfford,
          isLast: index == path.nodes.length - 1,
        );
      },
    );
  }

  Widget _buildNodeItem({
    required ElementalNode node,
    required int index,
    required bool isUnlocked,
    required bool isNext,
    required bool isSelected,
    required bool canAfford,
    required bool isLast,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNodeIndex = _selectedNodeIndex == index ? null : index;
        });
      },
      child: Column(
        children: [
          Row(
            children: [
              // Node circle
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  final glowIntensity = canAfford
                      ? 0.2 + _glowController.value * 0.3
                      : 0.0;

                  return Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isUnlocked
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _elementColor,
                                _elementColor.withValues(alpha: 0.7),
                              ],
                            )
                          : null,
                      color: isUnlocked
                          ? null
                          : isNext
                          ? Colors.grey.shade700
                          : Colors.grey.shade900,
                      border: Border.all(
                        color: isUnlocked
                            ? _elementColor
                            : isNext
                            ? _elementColor.withValues(alpha: 0.5)
                            : Colors.grey.shade700,
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: canAfford
                          ? [
                              BoxShadow(
                                color: _elementColor.withValues(
                                  alpha: glowIntensity,
                                ),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ]
                          : isUnlocked
                          ? [
                              BoxShadow(
                                color: _elementColor.withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isUnlocked
                          ? Icon(Icons.check, color: Colors.white, size: 24)
                          : node.isPassive
                          ? const Text('★', style: TextStyle(fontSize: 20))
                          : Text(
                              node.tierIcon,
                              style: TextStyle(
                                fontSize: 16,
                                color: isNext
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade600,
                              ),
                            ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 16),

              // Node info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            node.displayName,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked
                                  ? Colors.white
                                  : isNext
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        if (!isUnlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: canAfford
                                  ? Colors.amber.withValues(alpha: 0.2)
                                  : Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: canAfford
                                    ? Colors.amber
                                    : Colors.grey.shade700,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('✨', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 4),
                                Text(
                                  '${node.cost}',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: canAfford
                                        ? Colors.amber
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      node.effectDescription,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: isUnlocked
                            ? Colors.greenAccent.shade200
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Connector line (if not last)
          if (!isLast)
            Container(
              width: 2,
              height: 24,
              margin: const EdgeInsets.only(left: 27),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isUnlocked ? _elementColor : Colors.grey.shade700,
                    index + 1 < _unlockedCount
                        ? _elementColor
                        : Colors.grey.shade700,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel(ElementalNode node) {
    final isUnlocked = node.index < _unlockedCount;
    final isNext = node.index == _unlockedCount;
    final canAfford = isNext && _crystals >= node.cost;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        border: Border(
          top: BorderSide(
            color: _elementColor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Node name and tier
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _elementColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'TIER ${node.tier}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _elementColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  node.displayName,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedNodeIndex = null),
                icon: const Icon(Icons.close, size: 20),
                color: Colors.grey,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Effect (benefit)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.add_circle, size: 16, color: Colors.greenAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.effectDescription,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Tradeoff
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.remove_circle, size: 16, color: Colors.red.shade300),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.tradeoffDescription,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Colors.red.shade300,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action button
          if (isUnlocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _elementColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _elementColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'UNLOCKED',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else if (isNext)
            _buildUnlockButton(node, canAfford)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Unlock previous nodes first',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnlockButton(ElementalNode node, bool canAfford) {
    return GestureDetector(
      onTap: canAfford ? () => _unlockNode(node) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: canAfford
              ? LinearGradient(
                  colors: [Colors.amber.shade700, Colors.amber.shade600],
                )
              : null,
          color: canAfford ? null : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
          boxShadow: canAfford
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✨', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              'UNLOCK FOR ${node.cost}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: canAfford ? Colors.white : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unlockNode(ElementalNode node) async {
    final cost = await widget.progressionSystem.characterProgress
        .unlockNextNode(widget.element, widget.progressionSystem.spendCrystals);

    if (cost != null) {
      setState(() {
        _selectedNodeIndex = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(widget.element.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${node.displayName} unlocked!',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            backgroundColor: _elementColor.withValues(alpha: 0.9),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
