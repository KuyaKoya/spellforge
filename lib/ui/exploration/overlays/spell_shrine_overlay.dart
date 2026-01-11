import 'package:flutter/material.dart';
import 'dart:math';
import '../../../domain/mage.dart';
import '../../../domain/spell.dart';
import '../../../domain/element.dart' as game_element;
import '../../../nodes/spell_tier_scaling.dart';
import '../../../systems/audio_manager.dart';

class SpellShrineOverlay extends StatefulWidget {
  final List<Spell> spellChoices;
  final Mage mage;
  final bool isActionCompleted;
  final Function(int choiceIndex) onLearn;
  final Function(int loadoutIndex, Spell newSpell) onReplace;
  final VoidCallback onSkip;

  /// Current run depth (1-indexed) for Phase 7.6 depth bonus display
  final int currentDepth;

  const SpellShrineOverlay({
    super.key,
    required this.spellChoices,
    required this.mage,
    this.isActionCompleted = false,
    required this.onLearn,
    required this.onReplace,
    required this.onSkip,
    this.currentDepth = 1,
  });

  @override
  State<SpellShrineOverlay> createState() => _SpellShrineOverlayState();
}

class _SpellShrineOverlayState extends State<SpellShrineOverlay>
    with TickerProviderStateMixin {
  // If not null, we are selecting a slot to replace with this spell
  Spell? _replacingSpell;
  int? _learningIndex; // Index of the spell currently being learned

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _learnBurstController;
  late Animation<double> _learnBurstAnimation;

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

    // Setup learn burst animation
    _learnBurstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _learnBurstAnimation = CurvedAnimation(
      parent: _learnBurstController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _learnBurstController.dispose();
    super.dispose();
  }

  /// Handle learning a spell with audio feedback and animation
  Future<void> _handleLearn(int choiceIndex) async {
    if (_learningIndex != null) return;

    setState(() {
      _learningIndex = choiceIndex;
    });

    // Register the spell FIRST (non-blocking) to prevent deadlock
    widget.onLearn(choiceIndex);

    // Phase 7.6.2: Play shrine (upgrade) sound when learning
    AudioManager.instance.playShrineUpgrade();

    // Play visual flair (non-blocking)
    _learnBurstController.forward(from: 0.0);

    // Auto-close after 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      widget.onSkip();
    }
  }

  /// Handle replacing a spell with audio feedback
  Future<void> _handleReplace(int loadoutIndex, Spell newSpell) async {
    if (_learningIndex != null) return;

    // Use _learningIndex to block leaving during replace
    setState(() {
      _learningIndex = loadoutIndex;
    });

    // Register the replacement FIRST (non-blocking)
    widget.onReplace(loadoutIndex, newSpell);

    // Play the sound
    AudioManager.instance.playShrineUpgrade();

    // Play visual flair (non-blocking)
    _learnBurstController.forward(from: 0.0);

    // Auto-close after 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      widget.onSkip();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_replacingSpell != null) {
      return _buildReplaceScreen();
    }

    return Center(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 750),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF1a1f2e), const Color(0xFF0d1117)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.15),
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
                child: ListView.separated(
                  itemCount: widget.spellChoices.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildSpellChoiceCard(
                      widget.spellChoices[index],
                      index,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Leave Button (disabled while action in progress)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TextButton.icon(
                onPressed: _learningIndex != null ? null : widget.onSkip,
                icon: Icon(
                  Icons.exit_to_app,
                  color: _learningIndex != null
                      ? Colors.grey.shade700
                      : Colors.grey.shade500,
                  size: 18,
                ),
                label: Text(
                  _learningIndex != null ? 'Learning...' : 'Leave Shrine',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: _learningIndex != null
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
          colors: [Colors.cyan.withValues(alpha: 0.15), Colors.transparent],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: const Text(
              'Spell Shrine',
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
                          Colors.cyanAccent.withValues(
                            alpha: _glowAnimation.value * 0.3,
                          ),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(
                            alpha: _glowAnimation.value * 0.4,
                          ),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.menu_book,
                        color: Colors.cyanAccent,
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
                    const Text(
                      'Ancient knowledge inscribed in light.',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Depth Bonus indicator (Phase 7.6 Rule 15)
              _buildDepthBonusIndicator(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpellChoiceCard(Spell spell, int index) {
    final isHighTier =
        spell.rarity == SpellRarity.rare ||
        spell.rarity == SpellRarity.signature;
    final isUpgraded = spell.starLevel >= 2;
    final isLearning = _learningIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isHighTier
              ? [
                  _getRarityColor(spell.rarity).withValues(alpha: 0.15),
                  const Color(0xFF0d1117),
                ]
              : [const Color(0xFF161b22), const Color(0xFF0d1117)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighTier
              ? _getRarityColor(spell.rarity).withValues(alpha: 0.5)
              : _getElementColor(spell.element).withValues(alpha: 0.3),
          width: isHighTier ? 2 : 1,
        ),
        boxShadow: isHighTier
            ? [
                BoxShadow(
                  color: _getRarityColor(spell.rarity).withValues(alpha: 0.1),
                  blurRadius: 12,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      spell.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getElementColor(spell.element),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTierBadge(spell.rarity, isUpgraded),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ScaleTransition(
                    scale: isLearning
                        ? Tween<double>(
                            begin: 1.0,
                            end: 1.2,
                          ).animate(_learnBurstAnimation)
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Learn Button (Hidden when learning this spell)
                  !isLearning
                      ? ElevatedButton(
                          onPressed:
                              (widget.isActionCompleted ||
                                  _learningIndex != null)
                              ? null
                              : () {
                                  if (widget.mage.isLoadoutFull) {
                                    setState(() {
                                      _replacingSpell = spell;
                                    });
                                  } else {
                                    _handleLearn(index);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isActionCompleted
                                ? Colors.grey
                                : const Color(0xFF238636),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade900,
                            disabledForegroundColor: Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'LEARN',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 12),
              // Spell Description
              Padding(
                padding: const EdgeInsets.only(left: 62),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spell.baseDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        height: 1.4,
                      ),
                    ),
                    if (spell.effectsDescription.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        spell.effectsDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Sparkle Overlay when learning
          if (isLearning) const Positioned.fill(child: _CardSparkleOverlay()),
        ],
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

  /// Builds a tier badge for the spell rarity (Phase 7.6 Rule 15).
  Widget _buildTierBadge(SpellRarity rarity, bool isUpgraded) {
    final color = _getRarityColor(rarity);
    final displayText = isUpgraded
        ? '★★ ${rarity.displayName}'
        : rarity.displayName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Gets the color for a spell rarity.
  Color _getRarityColor(SpellRarity rarity) {
    switch (rarity) {
      case SpellRarity.common:
        return const Color(0xFF8b949e); // Gray
      case SpellRarity.uncommon:
        return const Color(0xFF3fb950); // Green
      case SpellRarity.rare:
        return const Color(0xFF58a6ff); // Blue
      case SpellRarity.signature:
        return const Color(0xFFf0b429); // Gold
      case SpellRarity.legendary:
        return const Color(0xFFbc8cff); // Purple
      case SpellRarity.fusion:
        return const Color(0xFF00d4aa); // Cyan/Teal
    }
  }

  /// Builds the Depth Bonus indicator (Phase 7.6 Rule 15).
  /// Shows current tier availability and star upgrade chance.
  Widget _buildDepthBonusIndicator() {
    final depth = widget.currentDepth;
    final maxRarity = SpellTierConfig.getMaxRarityForDepth(depth);
    final starChance = SpellTierConfig.getStarUpgradeChance(depth);

    // Determine display text
    String tierText;
    Color tierColor;

    switch (maxRarity) {
      case SpellRarity.common:
        tierText = 'Tier I';
        tierColor = const Color(0xFF8b949e);
        break;
      case SpellRarity.uncommon:
        tierText = 'Tier II';
        tierColor = const Color(0xFF3fb950);
        break;
      case SpellRarity.rare:
        tierText = starChance > 0 ? 'Tier III+' : 'Tier III';
        tierColor = const Color(0xFF58a6ff);
        break;
      case SpellRarity.signature:
        tierText = 'Tier IV';
        tierColor = const Color(0xFFf0b429);
        break;
      case SpellRarity.legendary:
        tierText = 'Tier V';
        tierColor = const Color(0xFFbc8cff);
        break;
      case SpellRarity.fusion:
        tierText = 'Fusion';
        tierColor = const Color(0xFF00d4aa);
        break;
    }

    return Tooltip(
      message: _getDepthBonusTooltip(depth, maxRarity, starChance),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: tierColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: tierColor.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 14, color: tierColor),
            const SizedBox(width: 6),
            Text(
              tierText,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: tierColor,
              ),
            ),
            if (starChance > 0) ...[
              const SizedBox(width: 4),
              Text(
                '★',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFFf0b429).withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Gets tooltip text for the depth bonus indicator.
  String _getDepthBonusTooltip(
    int depth,
    SpellRarity maxRarity,
    double starChance,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Depth Bonus (Floor $depth)');
    buffer.writeln('');
    buffer.writeln('Max Rarity: ${maxRarity.displayName}');

    if (starChance > 0) {
      final percent = (starChance * 100).toInt();
      buffer.writeln('★★ Upgrade Chance: $percent%');
    }

    if (depth <= 2) {
      buffer.write('Early exploration - basic spells available');
    } else if (depth <= 4) {
      buffer.write('Deeper knowledge unlocked');
    } else if (depth <= 6) {
      buffer.write('Rare arcana accessible');
    } else {
      buffer.write('Ancient power awakens');
    }

    return buffer.toString();
  }

  Widget _buildReplaceScreen() {
    final width = MediaQuery.of(context).size.width;
    final containerWidth = width > 650 ? 600.0 : width * 0.95;

    return Center(
      child: Container(
        width: containerWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF161b22).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade800, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Grimoire Full',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a spell to replace with ${_replacingSpell?.displayName}:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            ...widget.mage.spellLoadout.asMap().entries.map((entry) {
              final index = entry.key;
              final spell = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    if (_replacingSpell != null) {
                      _handleReplace(index, _replacingSpell!);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF30363d)),
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF0d1117),
                    ),
                    child: Row(
                      children: [
                        Text(spell.elementIcon),
                        const SizedBox(width: 12),
                        Text(
                          spell.displayName,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.swap_horiz, color: Colors.orange),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _replacingSpell = null),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getElementColor(game_element.Element element) {
    switch (element.toString().split('.').last) {
      case 'fire':
        return const Color(0xFFf85149);
      case 'water':
        return const Color(0xFF58a6ff);
      case 'earth':
        return const Color(0xFF7c6f4a);
      case 'air':
        return const Color(0xFF79c0ff);
      default:
        return Colors.grey;
    }
  }
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

      paint.color = Colors.cyanAccent.withValues(alpha: 0.6 * opacity);

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
