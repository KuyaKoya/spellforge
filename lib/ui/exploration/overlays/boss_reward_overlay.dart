import 'dart:math';
import 'package:flutter/material.dart';
import '../../../domain/spell.dart';
import '../../../systems/reward_resolver.dart';

/// Celebratory overlay displayed after defeating a boss.
///
/// Phase 7.9.5: Features:
/// - Large HP heal indicator
/// - Fragment + Crystal rewards
/// - Legendary spell unlock celebration (first clear)
/// - High-tier spell choices
class BossRewardOverlay extends StatefulWidget {
  final RewardResult rewardResult;
  final int currentHP;
  final int maxHP;
  final String bossName;
  final Function(Spell? selectedSpell) onComplete;

  const BossRewardOverlay({
    super.key,
    required this.rewardResult,
    required this.currentHP,
    required this.maxHP,
    required this.bossName,
    required this.onComplete,
  });

  @override
  State<BossRewardOverlay> createState() => _BossRewardOverlayState();
}

class _BossRewardOverlayState extends State<BossRewardOverlay>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _legendaryController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  int? _selectedSpellIndex;
  bool _showingRewards = false;
  bool _showingLegendary = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _legendaryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _entranceController.forward();

    // Show legendary unlock first if applicable
    if (widget.rewardResult.isFirstClear &&
        widget.rewardResult.legendaryUnlock != null) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() => _showingLegendary = true);
          _legendaryController.forward();
        }
      });

      // Then show rewards
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (mounted) setState(() => _showingRewards = true);
      });
    } else {
      // Just show rewards
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _showingRewards = true);
      });
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _legendaryController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Particle background
        CustomPaint(
          painter: _ParticlePainter(_particleController),
          size: Size.infinite,
        ),

        // Main content
        AnimatedBuilder(
          animation: _entranceController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: _buildContent(),
              ),
            );
          },
        ),

        // Legendary unlock overlay
        if (_showingLegendary && widget.rewardResult.legendaryUnlock != null)
          _buildLegendaryUnlockOverlay(),
      ],
    );
  }

  Widget _buildContent() {
    final healAmount = RewardResolver.calculateHealAmount(
      widget.maxHP,
      widget.rewardResult.healPercent,
    );

    return Center(
      child: Container(
        width: 460,
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1a0a2e).withValues(alpha: 0.98),
              const Color(0xFF0d0518).withValues(alpha: 0.98),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(width: 3, color: Colors.amber.shade400),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.4),
              blurRadius: 50,
              spreadRadius: 10,
            ),
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.3),
              blurRadius: 80,
              spreadRadius: 20,
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Victory Banner
              _buildVictoryBanner(),

              const SizedBox(height: 28),

              if (_showingRewards) ...[
                // Rewards Grid
                _buildRewardsGrid(healAmount),

                const SizedBox(height: 24),

                // Spell Choices
                if (widget.rewardResult.spellChoices.isNotEmpty) ...[
                  _buildSectionHeader('Choose Your Reward'),
                  const SizedBox(height: 12),
                  ...widget.rewardResult.spellChoices.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildSpellCard(entry.value, entry.key),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Complete Button
                _buildCompleteButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVictoryBanner() {
    return Column(
      children: [
        // Trophy with glow
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.amber.withValues(alpha: 0.4),
                Colors.amber.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
          child: const Icon(Icons.emoji_events, color: Colors.amber, size: 72),
        ),
        const SizedBox(height: 16),

        // Victory Title
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.amber, Colors.orange, Colors.amber],
          ).createShader(bounds),
          child: const Text(
            '🏆 BOSS DEFEATED 🏆',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          widget.bossName,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            color: Colors.grey.shade300,
            fontStyle: FontStyle.italic,
          ),
        ),

        if (widget.rewardResult.isFirstClear) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade700, Colors.purple.shade900],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 18),
                SizedBox(width: 6),
                Text(
                  'FIRST CLEAR BONUS',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.star, color: Colors.amber, size: 18),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRewardsGrid(int healAmount) {
    return Row(
      children: [
        Expanded(
          child: _buildRewardCard(
            icon: Icons.favorite,
            iconColor: Colors.redAccent,
            value: '+$healAmount',
            label: 'HP',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRewardCard(
            icon: Icons.diamond,
            iconColor: Colors.tealAccent,
            value: '+${widget.rewardResult.fragments}',
            label: 'Fragments',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRewardCard(
            icon: Icons.auto_awesome,
            iconColor: Colors.purpleAccent,
            value: '+${widget.rewardResult.crystals}',
            label: 'Crystals',
          ),
        ),
      ],
    );
  }

  Widget _buildRewardCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSpellCard(Spell spell, int index) {
    final isSelected = _selectedSpellIndex == index;
    final isLegendary = spell.rarity == SpellRarity.legendary;
    final rarityColor = _getRarityColor(spell.rarity);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedSpellIndex = index),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isLegendary
                ? LinearGradient(
                    colors: [
                      const Color(
                        0xFF3d1a5c,
                      ).withValues(alpha: isSelected ? 0.8 : 0.4),
                      const Color(
                        0xFF1a0a2e,
                      ).withValues(alpha: isSelected ? 0.8 : 0.4),
                    ],
                  )
                : null,
            color: isLegendary
                ? null
                : (isSelected
                      ? rarityColor.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? rarityColor : Colors.grey.shade600,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isLegendary
                ? [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.3),
                      blurRadius: 15,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Element Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getElementColor(spell.element).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: isLegendary
                      ? Border.all(color: Colors.purple.withValues(alpha: 0.5))
                      : null,
                ),
                child: Center(
                  child: Text(
                    spell.element.icon,
                    style: const TextStyle(fontSize: 26),
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
                        if (isLegendary)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.auto_awesome,
                              color: Colors.purple.shade300,
                              size: 16,
                            ),
                          ),
                        Flexible(
                          child: Text(
                            spell.name,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isLegendary
                                  ? Colors.purple.shade200
                                  : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: rarityColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            spell.rarity.displayName.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              color: rarityColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spell.baseDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),

              // Selection Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? rarityColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? rarityColor : Colors.grey.shade500,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendaryUnlockOverlay() {
    final spell = widget.rewardResult.legendaryUnlock!;

    return AnimatedBuilder(
      animation: _legendaryController,
      builder: (context, child) {
        final value = _legendaryController.value;
        return Opacity(
          opacity: value < 0.8 ? value * 1.25 : 1.0 - ((value - 0.8) * 5),
          child: Center(
            child: Transform.scale(
              scale: 0.5 + (value * 0.5),
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.purple.shade900,
                      Colors.purple.shade900.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                    radius: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.purple,
                      size: 80,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '🟣 LEGENDARY UNLOCKED 🟣',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      spell.name,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      spell.baseDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompleteButton() {
    final hasSpellSelection = widget.rewardResult.spellChoices.isNotEmpty;
    final canComplete = !hasSpellSelection || _selectedSpellIndex != null;

    return ElevatedButton(
      onPressed: canComplete ? _handleComplete : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.black,
        disabledBackgroundColor: Colors.grey.shade800,
        disabledForegroundColor: Colors.grey.shade500,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 8,
        shadowColor: Colors.amber.withValues(alpha: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasSpellSelection
                ? (_selectedSpellIndex != null
                      ? 'CLAIM VICTORY'
                      : 'SELECT A SPELL')
                : 'CLAIM VICTORY',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          if (canComplete) ...[
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward, size: 22),
          ],
        ],
      ),
    );
  }

  void _handleComplete() {
    Spell? selectedSpell;
    if (_selectedSpellIndex != null &&
        _selectedSpellIndex! < widget.rewardResult.spellChoices.length) {
      selectedSpell = widget.rewardResult.spellChoices[_selectedSpellIndex!];
    }
    widget.onComplete(selectedSpell);
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
        return const Color(0xFFbc8cff);
      case SpellRarity.fusion:
        return const Color(0xFF00d4aa);
    }
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
}

/// Particle effect painter for boss victory celebration
class _ParticlePainter extends CustomPainter {
  final Animation<double> animation;
  final Random _random = Random(42);
  final List<_Particle> _particles = [];

  _ParticlePainter(this.animation) : super(repaint: animation) {
    // Generate particles
    for (int i = 0; i < 50; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: 2 + _random.nextDouble() * 4,
          speed: 0.2 + _random.nextDouble() * 0.5,
          phase: _random.nextDouble(),
        ),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in _particles) {
      final t = (animation.value + particle.phase) % 1.0;
      final y = (particle.y - t * particle.speed) % 1.0;
      final opacity = (sin(t * 2 * pi) + 1) / 2 * 0.6;

      paint.color = Colors.amber.withValues(alpha: opacity);

      canvas.drawCircle(
        Offset(particle.x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
  });
}
