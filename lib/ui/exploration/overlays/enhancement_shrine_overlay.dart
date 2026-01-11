import 'package:flutter/material.dart';
import 'dart:math';
import '../../../domain/mage.dart';
import '../../../domain/spell.dart';
import '../../../systems/node_resolver.dart';
import '../../../systems/audio_manager.dart';

class EnhancementShrineOverlay extends StatefulWidget {
  final Mage mage;
  final int spellFragments;
  final bool isActionCompleted;
  final Future<void> Function(int index, String? upgradePath) onUpgrade;
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

class _EnhancementShrineOverlayState extends State<EnhancementShrineOverlay>
    with TickerProviderStateMixin {
  int? _selectedSpellIndex;
  int? _upgradingIndex;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Phase 7.9: Upgrade Randomization Logic
  final Map<int, String> _upgradePathChoices = {};
  late AnimationController _upgradeBurstController;
  late Animation<double> _upgradeBurstAnimation;

  @override
  void initState() {
    super.initState();
    // Play shrine open sound when overlay appears
    AudioManager.instance.playShrineOpen();

    // Setup glow animation for the shrine icon
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Setup burst animation for upgrade success
    _upgradeBurstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _upgradeBurstAnimation = CurvedAnimation(
      parent: _upgradeBurstController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _upgradeBurstController.dispose();
    super.dispose();
  }

  /// Gets the deterministic random upgrade path for a spell
  String _getUpgradePathFor(int index, Spell spell) {
    if (_upgradePathChoices.containsKey(index)) {
      return _upgradePathChoices[index]!;
    }

    final paths = spell.getAvailableUpgradePaths();
    // Use a random generator but persist the choice for this session
    final random = Random();
    final choice = paths[random.nextInt(paths.length)];

    _upgradePathChoices[index] = choice;
    return choice;
  }

  /// Handle upgrade with audio feedback
  Future<void> _handleUpgrade(int index) async {
    if (_upgradingIndex != null) return;

    setState(() => _upgradingIndex = index);

    // Get the selected path BEFORE calling upgrade
    final spell = widget.mage.spellLoadout[index];
    final upgradePath = _getUpgradePathFor(index, spell);

    // Register the upgrade FIRST (non-blocking) to prevent deadlock
    widget.onUpgrade(index, upgradePath);

    // Phase 7.6.2: Play shrine upgrade sound when actually upgrading
    AudioManager.instance.playShrineUpgrade();

    // Play visual flair (non-blocking)
    _upgradeBurstController.forward(from: 0.0);

    // Auto-close after 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      widget.onLeave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 650,
        constraints: const BoxConstraints(maxHeight: 750),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF1a1f2e), const Color(0xFF0d1117)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),

            // Spell List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView.builder(
                  itemCount: widget.mage.spellLoadout.length,
                  itemBuilder: (context, index) {
                    return _buildSpellCard(
                      context,
                      widget.mage.spellLoadout[index],
                      index,
                    );
                  },
                ),
              ),
            ),

            // Upgrade Preview (when spell selected)
            if (_selectedSpellIndex != null)
              _buildUpgradePreview(
                widget.mage.spellLoadout[_selectedSpellIndex!],
              ),

            const SizedBox(height: 16),

            // Leave Button (disabled while action in progress)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TextButton.icon(
                onPressed: _upgradingIndex != null ? null : widget.onLeave,
                icon: Icon(
                  Icons.exit_to_app,
                  color: _upgradingIndex != null
                      ? Colors.grey.shade700
                      : Colors.grey.shade500,
                  size: 18,
                ),
                label: Text(
                  _upgradingIndex != null ? 'Enhancing...' : 'Leave Shrine',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: _upgradingIndex != null
                        ? Colors.grey.shade700
                        : Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.amber.withValues(alpha: 0.15), Colors.transparent],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: const Text(
              'Enhancement Shrine',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // Animated Shrine Icon
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.amber.withValues(
                            alpha: _glowAnimation.value * 0.3,
                          ),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(
                            alpha: _glowAnimation.value * 0.4,
                          ),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.amber,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Enhance your spells to unlock greater power',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              // Fragment Counter
              _buildFragmentCounter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFragmentCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade900.withValues(alpha: 0.6),
            Colors.teal.shade800.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.tealAccent.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.tealAccent.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💎', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            '${widget.spellFragments}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.tealAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpellCard(BuildContext context, Spell spell, int index) {
    final cost = NodeResolver.getUpgradeCost(spell);
    final canAfford = widget.spellFragments >= cost;
    final isMax = spell.starLevel >= 3;
    final isSelected = _selectedSpellIndex == index;

    return GestureDetector(
      onTap: isMax
          ? null
          : () {
              setState(() {
                _selectedSpellIndex = isSelected ? null : index;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isMax
                ? [
                    Colors.amber.withValues(alpha: 0.08),
                    const Color(0xFF0d1117),
                  ]
                : isSelected
                ? [
                    Colors.amber.withValues(alpha: 0.15),
                    Colors.amber.withValues(alpha: 0.05),
                  ]
                : [const Color(0xFF161b22), const Color(0xFF0d1117)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMax
                ? Colors.amber.withValues(alpha: 0.5)
                : isSelected
                ? Colors.amber.withValues(alpha: 0.6)
                : const Color(0xFF30363d),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Element Icon
                    ScaleTransition(
                      scale: isSelected
                          ? Tween<double>(
                              begin: 1.0,
                              end: 1.2,
                            ).animate(_upgradeBurstAnimation)
                          : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getElementColor(
                                spell.element,
                              ).withValues(alpha: 0.3),
                              _getElementColor(
                                spell.element,
                              ).withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _getElementColor(
                              spell.element,
                            ).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            spell.elementIcon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Spell Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  spell.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _buildStars(spell.starLevel),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildStatChip(
                                '💠 ${spell.manaCost}',
                                Colors.blue.shade300,
                              ),
                              _buildStatChip(
                                '⚔️ ${spell.baseDamage}',
                                Colors.red.shade300,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRarityColor(
                                    spell.rarity,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  spell.rarity.displayName,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: _getRarityColor(spell.rarity),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Spell Description
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 62),
                  child: Text(
                    spell.baseDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Action Area
                if (!isMax)
                  // _buildMaxedBadge()
                  _buildUpgradeButton(spell, index, canAfford),
              ],
            ),
            if (_upgradingIndex == index)
              const Positioned.fill(child: _CardSparkleOverlay()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Widget _buildMaxedBadge() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [
  //           Colors.amber.withValues(alpha: 0.2),
  //           Colors.orange.withValues(alpha: 0.1),
  //         ],
  //       ),
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.max,
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       spacing: 6,
  //       children: [
  //         Icon(Icons.star, color: Colors.amber.shade300, size: 16),
  //         const Text(
  //           'MAXED',
  //           style: TextStyle(
  //             fontFamily: 'monospace',
  //             fontWeight: FontWeight.bold,
  //             fontSize: 12,
  //             color: Colors.amber,
  //             letterSpacing: 1,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildUpgradeButton(Spell spell, int index, bool canAfford) {
    final cost = NodeResolver.getUpgradeCost(spell);
    final isUpgradingThis = _upgradingIndex == index;
    final isAnyUpgrading = _upgradingIndex != null;

    return ElevatedButton(
      onPressed: (canAfford && !isAnyUpgrading)
          ? () => _handleUpgrade(index)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canAfford
            ? Colors.amber.shade700
            : Colors.grey.shade800,
        foregroundColor: Colors.white,
        disabledBackgroundColor: (isUpgradingThis && canAfford)
            ? Colors.amber.shade700
            : Colors.grey.shade900,
        disabledForegroundColor: (isUpgradingThis && canAfford)
            ? Colors.white
            : Colors.grey.shade600,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: canAfford ? 4 : 0,
        shadowColor: Colors.amber.withValues(alpha: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 4,
            children: [
              isUpgradingThis
                  ? const _SparkleLoadingIndicator()
                  : Row(
                      children: [
                        Text(
                          'UPGRADE',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                            color: canAfford
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                        const Text('💎', style: TextStyle(fontSize: 10)),
                        Text(
                          '$cost',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: canAfford
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradePreview(Spell spell) {
    if (spell.starLevel >= 3) return const SizedBox.shrink();

    // Determine what aspect gets upgraded
    // Pass index if available, otherwise assume 0 or handle logic.
    // Actually we need the index of the spell in loadout.
    final index = widget.mage.spellLoadout.indexOf(spell);
    final upgradePath = index != -1 ? _getUpgradePathFor(index, spell) : null;

    final upgradedSpell = spell.upgrade(upgradePath);
    final cost = NodeResolver.getUpgradeCost(spell);
    final canAfford = widget.spellFragments >= cost;

    String upgradeDescription = 'Enhancing Spell Power';
    if (upgradePath == 'damage') {
      upgradeDescription = 'Focus: Boosting Base Damage';
    } else if (upgradePath != null && upgradePath.startsWith('effect_')) {
      final index = int.tryParse(upgradePath.split('_')[1]) ?? 0;
      if (index < spell.effects.length) {
        upgradeDescription =
            'Focus: Enhancing ${spell.effects[index].type.displayName}';
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withValues(alpha: 0.1),
            Colors.orange.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber.shade300, size: 18),
              const SizedBox(width: 8),
              const Text(
                'UPGRADE PREVIEW',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _selectedSpellIndex = null),
                icon: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Upgrade Path Prediction
          if (upgradePath != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_graph, size: 14, color: Colors.blue.shade300),
                  const SizedBox(width: 6),
                  Text(
                    upgradeDescription,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.blue.shade200,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Comparison Row
          Row(
            children: [
              // Current Stats
              Expanded(
                child: _buildStatColumn('CURRENT', spell, Colors.grey.shade400),
              ),

              // Arrow
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.amber.shade400,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: canAfford
                            ? Colors.amber.shade800
                            : Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('💎', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 4),
                          Text(
                            '$cost',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: canAfford
                                  ? Colors.white
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Upgraded Stats
              Expanded(
                child: _buildStatColumn(
                  'AFTER',
                  upgradedSpell,
                  Colors.greenAccent,
                  isUpgraded: true,
                  originalSpell: spell,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Upgrade Changes Description
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Enhancement Effects:',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ..._getUpgradeChanges(spell, upgradedSpell),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    Spell spell,
    Color labelColor, {
    bool isUpgraded = false,
    Spell? originalSpell,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: isUpgraded
            ? Border.all(color: Colors.greenAccent.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: labelColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          _buildStars(spell.starLevel),
          const SizedBox(height: 8),
          _buildComparisonStat(
            '⚔️ Damage',
            spell.baseDamage,
            isUpgraded ? originalSpell?.baseDamage : null,
          ),
          const SizedBox(height: 4),
          _buildComparisonStat(
            '💠 Mana',
            spell.manaCost,
            isUpgraded ? originalSpell?.manaCost : null,
            lowerIsBetter: true,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonStat(
    String label,
    int value,
    int? originalValue, {
    bool lowerIsBetter = false,
  }) {
    final hasChange = originalValue != null && originalValue != value;
    final isImproved =
        hasChange &&
        (lowerIsBetter ? value < originalValue : value > originalValue);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$value',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: hasChange
                ? (isImproved ? Colors.greenAccent : Colors.redAccent)
                : Colors.white,
          ),
        ),
        if (hasChange && isImproved)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.arrow_upward,
              size: 10,
              color: Colors.greenAccent,
            ),
          ),
      ],
    );
  }

  List<Widget> _getUpgradeChanges(Spell current, Spell upgraded) {
    final changes = <Widget>[];

    // Damage increase
    final damageDiff = upgraded.baseDamage - current.baseDamage;
    if (damageDiff > 0) {
      changes.add(
        _buildChangeRow(
          Icons.add_circle_outline,
          '+$damageDiff base damage',
          Colors.greenAccent,
        ),
      );
    }

    // Status effect duration increase
    for (
      int i = 0;
      i < current.effects.length && i < upgraded.effects.length;
      i++
    ) {
      final currentEffect = current.effects[i];
      final upgradedEffect = upgraded.effects[i];

      if (currentEffect.isStatusEffect &&
          upgradedEffect.duration > currentEffect.duration) {
        changes.add(
          _buildChangeRow(
            Icons.timer,
            '+${upgradedEffect.duration - currentEffect.duration} turn(s) for ${currentEffect.type.name}',
            Colors.cyanAccent,
          ),
        );
      }
    }

    // Star level
    changes.add(
      _buildChangeRow(
        Icons.star,
        '★ → ${'★' * upgraded.starLevel}',
        Colors.amber,
      ),
    );

    return changes;
  }

  Widget _buildChangeRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: color,
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
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Icon(
            index < level ? Icons.star : Icons.star_border,
            size: 16,
            color: index < level ? Colors.amber : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Color _getElementColor(dynamic element) {
    switch (element.toString().split('.').last) {
      case 'fire':
        return Colors.orange;
      case 'water':
        return Colors.blue;
      case 'earth':
        return Colors.brown;
      case 'air':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  Color _getRarityColor(SpellRarity rarity) {
    switch (rarity) {
      case SpellRarity.common:
        return Colors.grey.shade400;
      case SpellRarity.uncommon:
        return Colors.green;
      case SpellRarity.rare:
        return Colors.blue;
      case SpellRarity.signature:
        return Colors.amber;
      case SpellRarity.legendary:
        return const Color(0xFFbc8cff); // Purple
      case SpellRarity.fusion:
        return const Color(0xFF00d4aa); // Cyan/Teal
    }
  }
}

class _SparkleLoadingIndicator extends StatefulWidget {
  const _SparkleLoadingIndicator();

  @override
  State<_SparkleLoadingIndicator> createState() =>
      _SparkleLoadingIndicatorState();
}

class _SparkleLoadingIndicatorState extends State<_SparkleLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _SparklePainter(_controller)),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Animation<double> animation;
  final List<Offset> _stars = [
    const Offset(0.5, 0.2), // Top
    const Offset(0.2, 0.6), // Bottom left
    const Offset(0.8, 0.6), // Bottom right
    const Offset(0.5, 0.5), // Center
    const Offset(0.3, 0.3), // Top left
    const Offset(0.7, 0.3), // Top right
  ];

  _SparklePainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < _stars.length; i++) {
      final starRel = _stars[i];
      final pos = Offset(starRel.dx * size.width, starRel.dy * size.height);

      // Create a staggered animation based on index
      final shift = i * (1.0 / _stars.length);
      final t = (animation.value + shift) % 1.0;

      // Twinkle effect: sinusiodal opacity
      final opacity = (sin(t * 2 * pi) + 1) / 2;

      // Main star
      paint.color = Colors.white.withValues(alpha: 0.9 * opacity);

      // Vary size slightly
      final scale = 0.4 + (0.4 * opacity);

      _drawStar(canvas, pos, size.width * 0.2 * scale, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => true;
}

class _CardSparkleOverlay extends StatefulWidget {
  const _CardSparkleOverlay();

  @override
  State<_CardSparkleOverlay> createState() => _CardSparkleOverlayState();
}

class _CardSparkleOverlayState extends State<_CardSparkleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_StarSpec> _stars = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Generate random stars
    for (int i = 0; i < 20; i++) {
      _stars.add(
        _StarSpec(
          position: Offset(_random.nextDouble(), _random.nextDouble()),
          scale: 0.5 + _random.nextDouble() * 1.0, // 0.5 to 1.5
          phaseOffset: _random.nextDouble(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _CardSparklePainter(_controller, _stars)),
    );
  }
}

class _StarSpec {
  final Offset position;
  final double scale;
  final double phaseOffset;

  _StarSpec({
    required this.position,
    required this.scale,
    required this.phaseOffset,
  });
}

class _CardSparklePainter extends CustomPainter {
  final Animation<double> animation;
  final List<_StarSpec> stars;

  _CardSparklePainter(this.animation, this.stars) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var star in stars) {
      final t = (animation.value + star.phaseOffset) % 1.0;
      // Fade in and out
      final opacity = (sin(t * 2 * pi) + 1) / 2;

      paint.color = Colors.amber.withValues(alpha: 0.6 * opacity);

      final center = Offset(
        star.position.dx * size.width,
        star.position.dy * size.height,
      );

      // Draw star
      // Base radius ~10-20 pixels
      final radius = 8.0 * star.scale * (0.8 + 0.2 * opacity);

      _drawStar(canvas, center, radius, paint);

      // Draw core (white)
      paint.color = Colors.white.withValues(alpha: 0.8 * opacity);
      _drawStar(canvas, center, radius * 0.5, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    // 4-point star (diamond shape)
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CardSparklePainter oldDelegate) => true;
}
