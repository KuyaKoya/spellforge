import 'package:flutter/material.dart';

class GameOverOverlay extends StatelessWidget {
  final bool isVictory;
  final int depthReached;
  final int totalDepths;
  final int fragmentsCollected;
  final int turnsTaken;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;

  const GameOverOverlay({
    super.key,
    required this.isVictory,
    required this.depthReached,
    required this.totalDepths,
    required this.fragmentsCollected,
    required this.turnsTaken,
    required this.onRestart,
    required this.onMainMenu,
  });

  @override
  Widget build(BuildContext context) {
    final title = isVictory ? 'VICTORY' : 'DEFEAT';
    final color = isVictory ? Colors.amber : Colors.red;
    final icon = isVictory
        ? Icons.emoji_events
        : Icons.sentiment_very_dissatisfied;

    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: const Color(0xFF161b22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 50,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 80, color: color),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isVictory
                    ? 'The Spire has been conquered.'
                    : 'Your journey ends here.',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 48),
              _buildStatRow('Depth Reached', '$depthReached / $totalDepths'),
              _buildStatRow('Fragments Found', '$fragmentsCollected 💎'),
              const SizedBox(height: 48),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: onMainMenu,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('MAIN MENU'),
                    ),
                    const SizedBox(width: 24),
                    ElevatedButton(
                      onPressed: onRestart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('PLAY AGAIN'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: Colors.grey.shade500,
              letterSpacing: 1,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
