import 'package:flutter/material.dart';
import 'catalog_tab.dart';

class MainMenuOverlay extends StatefulWidget {
  final VoidCallback onNewGame;
  final int totalRuns;
  final int bestDepth;
  final int totalFragments;
  final int totalCrystals;
  final String? lastRunElement;

  const MainMenuOverlay({
    super.key,
    required this.onNewGame,
    required this.totalRuns,
    required this.bestDepth,
    required this.totalFragments,
    required this.totalCrystals,
    this.lastRunElement,
  });

  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

class _MainMenuOverlayState extends State<MainMenuOverlay> {
  int _selectedIndex = 1; // Default to Home

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF161b22),
          selectedItemColor: Colors.amber,
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontFamily: 'monospace'),
          onTap: (index) {
            // Character tab (index 0) is currently disabled
            if (index == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Character customization coming soon!',
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                  duration: Duration(seconds: 1),
                  backgroundColor: Color(0xFF161b22),
                ),
              );
              return;
            }
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                color: Colors.grey,
              ), // Visual cue for disabled
              activeIcon: Icon(Icons.person),
              label: 'CHARACTER',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: 'CATALOG',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 1:
        return _buildHomeTab();
      case 2:
        return const CatalogTab();
      default:
        return _buildHomeTab();
    }
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
            onPressed: widget.onNewGame,
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
                'START EXPLORATION',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Phase 7.6 (Beta)',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 48),

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
                      _buildStat('TOTAL RUNS', '${widget.totalRuns}'),
                      const SizedBox(width: 32),
                      _buildStat('BEST DEPTH', '${widget.bestDepth}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStat('FRAGMENTS', '${widget.totalFragments} 💎'),
                      const SizedBox(width: 32),
                      _buildStat('CRYSTALS', '${widget.totalCrystals} ✨'),
                    ],
                  ),
                  if (widget.lastRunElement != null) ...[
                    const SizedBox(height: 16),
                    _buildStat(
                      'LAST ELEMENT',
                      widget.lastRunElement!.toUpperCase(),
                    ),
                  ],
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
