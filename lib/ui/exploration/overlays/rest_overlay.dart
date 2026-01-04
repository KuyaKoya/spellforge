import 'package:flutter/material.dart';
import '../../../domain/mage.dart';

class RestOverlay extends StatelessWidget {
  final Mage mage;
  final bool isActionCompleted;
  final VoidCallback onRest;
  final VoidCallback onBuff;
  final VoidCallback onRemoveModifier;
  final VoidCallback onLeave;

  const RestOverlay({
    super.key,
    required this.mage,
    this.isActionCompleted = false,
    required this.onRest,
    required this.onBuff,
    required this.onRemoveModifier,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 400,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon/Title
            const Icon(
              Icons.fireplace_outlined,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Rest Site',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isActionCompleted
                  ? 'You feel refreshed and ready to continue.'
                  : 'The fire embraces you with warmth.',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),

            // HP Status
            _buildStatus(
              'HP',
              mage.hpDisplay,
              (mage.currentHP / mage.maxHP).clamp(0.0, 1.0),
              Colors.red.shade400,
            ),
            const SizedBox(height: 24),

            // Actions
            _buildActionButton(
              icon: Icons.hotel,
              label: 'Rest',
              description: 'Recover HP',
              color: isActionCompleted ? Colors.grey : Colors.green.shade400,
              onTap: isActionCompleted ? null : onRest,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.fitness_center,
              label: 'Train',
              description: 'Gain temporary damage buff',
              color: isActionCompleted ? Colors.grey : Colors.orange.shade400,
              onTap: isActionCompleted ? null : onBuff,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.auto_fix_high,
              label: 'Meditate',
              description: 'Remove spell modifiers',
              color: isActionCompleted ? Colors.grey : Colors.blue.shade400,
              onTap: isActionCompleted ? null : onRemoveModifier,
            ),
            const SizedBox(height: 24),

            // Leave
            TextButton(
              onPressed: onLeave,
              child: Text(
                'Leave',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus(String label, String value, double ratio, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                color: Colors.grey.shade400,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: const Color(0xFF30363d),
            color: color,
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
