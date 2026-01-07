import 'package:flutter/material.dart';
import '../../../domain/mage.dart';
import '../../../systems/node_resolver.dart';
import '../../../systems/audio_manager.dart';

class EnhancementShrineOverlay extends StatefulWidget {
  final Mage mage;
  final int spellFragments;
  final bool isActionCompleted;
  final Future<void> Function(int index) onUpgrade;
  final VoidCallback onLeave;

  const EnhancementShrineOverlay({
    super.key,
    required this.mage,
    required this.spellFragments,
    this.isActionCompleted = false,
    required this.onUpgrade,
    required this.onLeave,
  });

  @override
  State<EnhancementShrineOverlay> createState() =>
      _EnhancementShrineOverlayState();
}

class _EnhancementShrineOverlayState extends State<EnhancementShrineOverlay> {
  @override
  void initState() {
    super.initState();
    // Play shrine open sound when overlay appears
    AudioManager.instance.playShrineOpen();
  }

  /// Handle upgrade with audio feedback
  Future<void> _handleUpgrade(int index) async {
    // Phase 7.6.2: Play shrine upgrade sound when actually upgrading
    AudioManager.instance.playShrineUpgrade();
    await widget.onUpgrade(index);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF161b22).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF30363d), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 32),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enhancement Shrine',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Unlock the true potential of your spells.',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade900.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.teal.shade700),
                  ),
                  child: Row(
                    children: [
                      const Text('💎', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.spellFragments}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.tealAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Spell List
            Expanded(
              child: ListView.separated(
                itemCount: widget.mage.spellLoadout.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildSpellCard(
                    context,
                    widget.mage.spellLoadout[index],
                    index,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Leave
            Center(
              child: TextButton(
                onPressed: widget.onLeave,
                child: Text(
                  'Leave Shrine',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpellCard(BuildContext context, dynamic spell, int index) {
    // Dynamic type to avoid strict Spell import if easy, but assume Spell type.
    final cost = NodeResolver.getUpgradeCost(spell);
    final canAfford = widget.spellFragments >= cost;
    final isMax = spell.starLevel >= 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363d)),
      ),
      child: Row(
        children: [
          // Icon/Element
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF161b22),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF30363d)),
            ),
            child: Center(
              child: Text(
                spell.elementIcon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        spell.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStars(spell.starLevel),
                  ],
                ),
                Text(
                  spell.baseDescription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // Action
          if (isMax)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: const Text(
                'MAXED',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: (canAfford && !widget.isActionCompleted)
                  ? () => _handleUpgrade(index)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: (canAfford && !widget.isActionCompleted)
                    ? Colors.amber.shade800
                    : Colors.grey.shade800,
                disabledBackgroundColor: Colors.grey.shade900,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Column(
                children: [
                  const Text('UPGRADE'),
                  Text(
                    '$cost 💎',
                    style: TextStyle(
                      fontSize: 11,
                      color: canAfford
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStars(int level) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) => Icon(
          index < level ? Icons.star : Icons.star_border,
          size: 14,
          color: Colors.amber,
        ),
      ),
    );
  }
}
