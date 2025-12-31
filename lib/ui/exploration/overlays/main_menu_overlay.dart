import 'package:flutter/material.dart';

class MainMenuOverlay extends StatelessWidget {
  final VoidCallback onNewGame;
  final int totalRuns;
  final int bestDepth;
  final int totalFragments;
  final int totalCrystals;

  const MainMenuOverlay({
    super.key,
    required this.onNewGame,
    required this.totalRuns,
    required this.bestDepth,
    required this.totalFragments,
    required this.totalCrystals,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0d1117),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / Title
            const Icon(Icons.auto_fix_high, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: const Text(
                  'SPELLFORGE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 8,
                  ),
                ),
              ),
            ),
            Text(
              'FORGE YOUR PATH',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                color: Colors.amber.shade200,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 80),

            // Start Button
            ElevatedButton(
              onPressed: onNewGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF238636),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 64,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                elevation: 10,
                shadowColor: Colors.greenAccent.withOpacity(0.5),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: const Text(
                  'ENTER THE SPIRE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 64),

            // Stats
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade800)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStat('TOTAL RUNS', '$totalRuns'),
                  const SizedBox(width: 48),
                  _buildStat('BEST DEPTH', '$bestDepth'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Colors.grey.shade600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
