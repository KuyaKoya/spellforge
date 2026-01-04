import 'package:flutter/material.dart';
import 'catalog_tab.dart';

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
    return DefaultTabController(
      length: 2,
      child: Container(
        color: const Color(0xFF0d1117),
        child: Column(
          children: [
            // Top Tab Bar
            Container(
              color: const Color(0xFF0d1117),
              child: const TabBar(
                dividerColor: Colors.transparent,
                indicatorColor: Colors.amber,
                labelColor: Colors.amber,
                unselectedLabelColor: Colors.grey,
                labelStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                tabs: [
                  Tab(text: 'HOME'),
                  Tab(text: 'CATALOG'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(), // Prevent swipe
                children: [_buildHomeTab(), const CatalogTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Center(
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
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 10,
              shadowColor: Colors.greenAccent.withValues(alpha: 0.5),
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
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade800)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStat('TOTAL RUNS', '$totalRuns'),
                      const SizedBox(width: 32),
                      _buildStat('BEST DEPTH', '$bestDepth'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStat('FRAGMENTS', '$totalFragments 💎'),
                      const SizedBox(width: 32),
                      _buildStat('CRYSTALS', '$totalCrystals ✨'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
