import 'package:flutter/material.dart';
import '../../../domain/spell.dart';

class EliteRewardOverlay extends StatelessWidget {
  final List<dynamic> rewards;
  final Function(int index) onSelect;

  const EliteRewardOverlay({
    super.key,
    required this.rewards,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(
            0xFF2d1b2e,
          ).withValues(alpha: 0.95), // Purplish for Elite
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Elite Defeated!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your reward:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 32),
            ...rewards.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRewardCard(entry.value, entry.key),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(dynamic rewardData, int index) {
    // rewardData is a Map<String, dynamic>
    final map = rewardData as Map<String, dynamic>;
    final type = map['type'] as String;
    final name = map['name'] as String; // "Spell Crystal", "Fireball", etc.

    // Determine icon and color based on type
    IconData icon;
    Color color;
    String description = '';

    switch (type) {
      case 'crystal':
        icon = Icons.diamond;
        color = Colors.cyanAccent;
        description = 'Used to unlock new abilities.';
        break;
      case 'spell':
        icon = Icons.auto_stories;
        color = Colors.blueAccent;
        final spell = map['spell'] as Spell;
        description = 'Learn: ${spell.baseDescription}';
        break;
      case 'fragments':
        icon = Icons.hexagon; // Gem-like
        color = Colors.tealAccent;
        description = 'Currency for upgrades.';
        break;
      case 'upgrade':
        icon = Icons.upgrade;
        color = Colors.amberAccent;
        description = 'Upgrade an existing spell.';
        break;
      default:
        icon = Icons.card_giftcard;
        color = Colors.white;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(index),
        borderRadius: BorderRadius.circular(8),
        hoverColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black26,
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
