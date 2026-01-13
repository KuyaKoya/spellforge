import 'package:flutter/material.dart';
import '../../../domain/spell.dart';
import '../../../systems/reward_resolver.dart';
import '../../utils/game_colors.dart';

/// Stylish overlay displayed after defeating an elite enemy.
///
/// Phase 7.9.5: Uses RewardResult for guaranteed rewards:
/// - HP heal indicator
/// - Fragment reward
/// - Spell choices (learn new spell)
class EliteRewardOverlay extends StatefulWidget {
  final RewardResult? rewardResult;
  final int currentHP;
  final int maxHP;
  final Function(Spell? selectedSpell)? onComplete;

  // Legacy API support
  final List<dynamic>? rewards;
  final Function(int index)? onSelect;

  const EliteRewardOverlay({
    super.key,
    this.rewardResult,
    this.currentHP = 0,
    this.maxHP = 100,
    this.onComplete,
    // Legacy parameters
    this.rewards,
    this.onSelect,
  });

  /// Legacy constructor for backward compatibility
  factory EliteRewardOverlay.legacy({
    Key? key,
    required List<dynamic> rewards,
    required Function(int index) onSelect,
  }) {
    return EliteRewardOverlay(key: key, rewards: rewards, onSelect: onSelect);
  }

  @override
  State<EliteRewardOverlay> createState() => _EliteRewardOverlayState();
}

class _EliteRewardOverlayState extends State<EliteRewardOverlay>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  int? _selectedSpellIndex;
  bool _showingRewards = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _entranceController.forward();

    // Show rewards after entrance animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showingRewards = true);
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
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
    );
  }

  Widget _buildContent() {
    // Legacy mode: use old rewards/onSelect API
    if (widget.rewards != null && widget.onSelect != null) {
      return _buildLegacyContent();
    }

    // New mode: use RewardResult
    final result = widget.rewardResult;
    if (result == null) {
      return const Center(child: Text('No reward data'));
    }

    final healAmount = RewardResolver.calculateHealAmount(
      widget.maxHP,
      result.healPercent,
    );

    return Center(
      child: Container(
        width: 420,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2d1b4e).withValues(alpha: 0.98),
              const Color(0xFF1a0f2e).withValues(alpha: 0.98),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.4),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Victory Banner
              _buildVictoryBanner(),

              const SizedBox(height: 24),

              // Guaranteed Rewards Section
              if (_showingRewards) ...[
                _buildRewardSection(
                  icon: Icons.favorite,
                  iconColor: Colors.redAccent,
                  title: 'HP Restored',
                  value: '+$healAmount HP',
                  subtitle: '${(result.healPercent * 100).round()}% of max HP',
                ),

                const SizedBox(height: 12),

                _buildRewardSection(
                  icon: Icons.diamond,
                  iconColor: Colors.tealAccent,
                  title: 'Fragments',
                  value: '+${result.fragments}',
                  subtitle: 'For upgrades and purchases',
                ),

                const SizedBox(height: 20),

                // Spell Choices
                if (result.spellChoices.isNotEmpty) ...[
                  _buildSectionHeader('Choose a Spell to Learn'),
                  const SizedBox(height: 12),
                  ...result.spellChoices.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildSpellCard(entry.value, entry.key),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Complete Button
                _buildCompleteButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Legacy content builder for backward compatibility
  Widget _buildLegacyContent() {
    return Center(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2d1b2e).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.3),
              blurRadius: 30,
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
            ...widget.rewards!.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildLegacyRewardCard(entry.value, entry.key),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLegacyRewardCard(dynamic rewardData, int index) {
    final map = rewardData as Map<String, dynamic>;
    final type = map['type'] as String;
    final name = map['name'] as String;

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
        icon = Icons.hexagon;
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
        onTap: () => widget.onSelect!(index),
        borderRadius: BorderRadius.circular(8),
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

  Widget _buildVictoryBanner() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = 0.9 + (_pulseController.value * 0.1);
        return Transform.scale(
          scale: pulseValue,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.amber.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.military_tech,
                  color: Colors.amber,
                  size: 56,
                ),
              ),
              const SizedBox(height: 12),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.amber, Colors.orange.shade300],
                ).createShader(bounds),
                child: const Text(
                  'ELITE DEFEATED',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRewardSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.grey.shade500,
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
            color: Colors.purple.shade300,
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
    final rarityColor = GameColors.getRarityColor(spell.rarity);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedSpellIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? rarityColor.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? rarityColor : Colors.grey.shade700,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Element Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: GameColors.getElementColorDynamic(
                    spell.element,
                  ).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    spell.element.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Spell Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          spell.name,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: rarityColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            spell.rarity.displayName,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              color: rarityColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spell.baseDescription,
                      maxLines: 1,
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
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? rarityColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? rarityColor : Colors.grey.shade600,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteButton() {
    final result = widget.rewardResult;
    if (result == null) return const SizedBox.shrink();

    final hasSpellSelection = result.spellChoices.isNotEmpty;
    final canComplete = !hasSpellSelection || _selectedSpellIndex != null;

    return ElevatedButton(
      onPressed: canComplete ? _handleComplete : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade800,
        disabledForegroundColor: Colors.grey.shade500,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasSpellSelection
                ? (_selectedSpellIndex != null
                      ? 'CLAIM REWARDS'
                      : 'SELECT A SPELL')
                : 'CLAIM REWARDS',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          if (canComplete) ...[
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20),
          ],
        ],
      ),
    );
  }

  void _handleComplete() {
    final result = widget.rewardResult;
    if (result == null || widget.onComplete == null) return;

    Spell? selectedSpell;
    if (_selectedSpellIndex != null &&
        _selectedSpellIndex! < result.spellChoices.length) {
      selectedSpell = result.spellChoices[_selectedSpellIndex!];
    }
    widget.onComplete!(selectedSpell);
  }
}
