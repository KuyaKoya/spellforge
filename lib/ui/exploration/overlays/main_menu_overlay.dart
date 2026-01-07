import 'package:flutter/material.dart';
import 'catalog_tab.dart';
import 'character_tab.dart';
import '../../../narrative/narrative.dart';
import '../../../systems/progression_system.dart';
import '../../narrative_overlay.dart';
import '../../settings/settings_overlay.dart';

class MainMenuOverlay extends StatefulWidget {
  final VoidCallback onNewGame;
  final int totalRuns;
  final int bestDepth;
  final int totalFragments;
  final int totalCrystals;
  final String? lastRunElement;
  final ProgressionSystem progressionSystem; // Phase 7.7: For intro lore check

  // Phase 7.9.3: Save resume support
  final bool hasSavedRun;
  final VoidCallback? onContinue;
  final VoidCallback? onDiscard;

  const MainMenuOverlay({
    super.key,
    required this.onNewGame,
    required this.totalRuns,
    required this.bestDepth,
    required this.totalFragments,
    required this.totalCrystals,
    this.lastRunElement,
    required this.progressionSystem, // Phase 7.7
    // Phase 7.9.3
    this.hasSavedRun = false,
    this.onContinue,
    this.onDiscard,
  });

  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

class _MainMenuOverlayState extends State<MainMenuOverlay> {
  int _selectedIndex = 1; // Default to Home

  @override
  void initState() {
    super.initState();
    // Phase 7.7: Show intro lore on first launch
    _checkAndShowIntroLore();
  }

  /// Phase 7.7: Checks if intro lore should be shown and displays it.
  void _checkAndShowIntroLore() {
    if (!widget.progressionSystem.hasSeenIntro) {
      // Delay slightly to let the menu render first
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;

        final introNode = IntroLore.getIntroSequence(
          onComplete: () async {
            await widget.progressionSystem.markIntroAsSeen();
          },
        );

        showDialog(
          context: context,
          barrierDismissible: false, // Must tap through all screens
          builder: (context) => NarrativeOverlay(
            narrativeNode: introNode,
            onComplete: () {
              Navigator.of(context).pop();
            },
            showFadeIn: true,
          ),
        );
      });
    }
  }

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
            // Phase 7.8: Character tab now enabled
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
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
      case 0:
        // Phase 7.8: Character tab
        return CharacterTab(progressionSystem: widget.progressionSystem);
      case 1:
        return _buildHomeTab();
      case 2:
        return const CatalogTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Stack(
      children: [
        // Main Content
        Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 48),

                // Start Button
                ElevatedButton(
                  onPressed: widget.onNewGame,
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

                // Phase 7.9.3: Continue/Discard saved run
                if (widget.hasSavedRun && widget.onContinue != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: widget.onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1f6feb),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'CONTINUE',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: widget.onDiscard,
                        child: Text(
                          'DISCARD',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved run found',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.amber.shade300,
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Text(
                  'Phase 7.9.3 (Beta)',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),

                // Stats
                Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade800),
                    ),
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
                            _buildStat(
                              'FRAGMENTS',
                              '${widget.totalFragments} 💎',
                            ),
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
          ),
        ),

        // Settings Button (Top Right)
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => SettingsOverlay(
                  progressionSystem: widget.progressionSystem,
                  onReset: () {
                    setState(() {});
                  },
                ),
              );
            },
            icon: const Icon(Icons.settings, color: Colors.amber),
            tooltip: 'Settings',
          ),
        ),
      ],
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
