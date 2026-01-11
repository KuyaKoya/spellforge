import 'package:flutter/material.dart';
import '../../../systems/progression_system.dart';
import '../../../progression/core_path.dart';
import '../../../systems/audio_system.dart';

/// Displays the core path with all its nodes.
/// Allows unlocking nodes with fragments (tier 1) or crystals (tier 2-3).
class CorePathView extends StatefulWidget {
  final ProgressionSystem progressionSystem;
  final VoidCallback onBack;

  const CorePathView({
    super.key,
    required this.progressionSystem,
    required this.onBack,
  });

  @override
  State<CorePathView> createState() => _CorePathViewState();
}

class _CorePathViewState extends State<CorePathView>
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

  CorePath? get _path => CorePathRegistry.path;

  int get _unlockedCount =>
      widget.progressionSystem.characterProgress.unlockedCoreNodes;

  int get _fragments => widget.progressionSystem.spellFragments;
  int get _crystals => widget.progressionSystem.spellCrystals;

  static const Color _coreColor = Color(0xFFFFD700); // Gold

  @override
  Widget build(BuildContext context) {
    final path = _path;
    if (path == null) {
      return Center(
        child: Text(
          'Core path not found',
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

  Widget _buildHeader(CorePath path) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_coreColor.withValues(alpha: 0.3), Colors.transparent],
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

              // Currency display
              _buildCurrencyChip(
                icon: '🔮',
                value: _fragments,
                color: Colors.purple,
              ),
              const SizedBox(width: 8),
              _buildCurrencyChip(
                icon: '✨',
                value: _crystals,
                color: Colors.amber,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Core title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(CorePath.icon, style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CorePath.name.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _coreColor,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    CorePath.theme,
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
                '$_unlockedCount / ${path.maxNodes}',
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
                    value: _unlockedCount / path.maxNodes,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: AlwaysStoppedAnimation(_coreColor),
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Currency info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Tier 1: Fragments  •  Tier 2-3: Crystals',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyChip({
    required String icon,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeList(CorePath path) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: path.nodes.length,
      itemBuilder: (context, index) {
        final node = path.nodes[index];
        final isUnlocked = index < _unlockedCount;
        final isNext = index == _unlockedCount;
        final isSelected = _selectedNodeIndex == index;
        final canAfford = isNext && _canAfford(node);

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

  bool _canAfford(CoreNode node) {
    if (node.currency == CoreCurrency.fragments) {
      return _fragments >= node.cost;
    } else {
      return _crystals >= node.cost;
    }
  }

  Widget _buildNodeItem({
    required CoreNode node,
    required int index,
    required bool isUnlocked,
    required bool isNext,
    required bool isSelected,
    required bool canAfford,
    required bool isLast,
  }) {
    final nodeColor = node.currency == CoreCurrency.fragments
        ? Colors.purple
        : Colors.amber;

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
                                _coreColor,
                                _coreColor.withValues(alpha: 0.7),
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
                            ? _coreColor
                            : isNext
                            ? nodeColor.withValues(alpha: 0.5)
                            : Colors.grey.shade700,
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: canAfford
                          ? [
                              BoxShadow(
                                color: nodeColor.withValues(
                                  alpha: glowIntensity,
                                ),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ]
                          : isUnlocked
                          ? [
                              BoxShadow(
                                color: _coreColor.withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isUnlocked
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            )
                          : node.isCapstone
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
                                  ? nodeColor.withValues(alpha: 0.2)
                                  : Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: canAfford
                                    ? nodeColor
                                    : Colors.grey.shade700,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  node.currencyIcon,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${node.cost}',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: canAfford
                                        ? nodeColor
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
                    isUnlocked ? _coreColor : Colors.grey.shade700,
                    index + 1 < _unlockedCount
                        ? _coreColor
                        : Colors.grey.shade700,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel(CoreNode node) {
    final isUnlocked = node.index < _unlockedCount;
    final isNext = node.index == _unlockedCount;
    final canAfford = isNext && _canAfford(node);
    final nodeColor = node.currency == CoreCurrency.fragments
        ? Colors.purple
        : Colors.amber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        border: Border(
          top: BorderSide(color: _coreColor.withValues(alpha: 0.5), width: 2),
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
                  color: _coreColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'TIER ${node.tier}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _coreColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: nodeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      node.currencyIcon,
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      node.currency == CoreCurrency.fragments
                          ? 'FRAGMENTS'
                          : 'CRYSTALS',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: nodeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _selectedNodeIndex = null),
                icon: const Icon(Icons.close, size: 20),
                color: Colors.grey,
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            node.displayName,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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

          const SizedBox(height: 16),

          // Action button
          if (isUnlocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _coreColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _coreColor),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
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

  Widget _buildUnlockButton(CoreNode node, bool canAfford) {
    final nodeColor = node.currency == CoreCurrency.fragments
        ? Colors.purple
        : Colors.amber;

    return GestureDetector(
      onTap: canAfford ? () => _unlockNode(node) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: canAfford
              ? LinearGradient(colors: [nodeColor.shade700, nodeColor.shade600])
              : null,
          color: canAfford ? null : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
          boxShadow: canAfford
              ? [
                  BoxShadow(
                    color: nodeColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(node.currencyIcon, style: const TextStyle(fontSize: 16)),
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

  Future<void> _unlockNode(CoreNode node) async {
    final cost = await widget.progressionSystem.characterProgress
        .unlockNextCoreNode(
          spendFragments: widget.progressionSystem.spendFragments,
          spendCrystals: widget.progressionSystem.spendCrystals,
        );

    if (cost != null) {
      setState(() {
        _selectedNodeIndex = null;
      });

      // Play unlock sound
      AudioSystem.playSkillUnlock();

      if (mounted) {
        final currencyName = node.currency == CoreCurrency.fragments
            ? 'fragments'
            : 'crystals';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🌟', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${node.displayName} unlocked! (-$cost $currencyName)',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            backgroundColor: _coreColor.withValues(alpha: 0.9),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

// Extension to get shade colors for non-material colors
extension ColorShade on Color {
  Color get shade700 => Color.lerp(this, Colors.black, 0.3)!;
  Color get shade600 => Color.lerp(this, Colors.black, 0.2)!;
}
