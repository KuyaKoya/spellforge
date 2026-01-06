import 'package:flutter/material.dart';
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

class _SpellShrineOverlayState extends State<SpellShrineOverlay> {
  // If not null, we are selecting a slot to replace with this spell
  Spell? _replacingSpell;

  /// Handle learning a spell with audio feedback
  void _handleLearn(int choiceIndex) {
    // Phase 7.6.2: Play shrine sound when actually learning
    AudioManager.instance.playShrineUpgrade();
    widget.onLearn(choiceIndex);
  }

  /// Handle replacing a spell with audio feedback
  void _handleReplace(int loadoutIndex, Spell newSpell) {
    // Phase 7.6.2: Play shrine upgrade sound
    AudioManager.instance.playShrineUpgrade();
    widget.onReplace(loadoutIndex, newSpell);
  }

  @override
  Widget build(BuildContext context) {
    if (_replacingSpell != null) {
      return _buildReplaceScreen();
    }

    // Responsive layout
    final size = MediaQuery.of(context).size;
    final overlayHeight = size.height * 0.8;
    final overlayWidth = size.width > 750 ? 700.0 : size.width * 0.95;

    return SafeArea(
      child: Center(
        child: Container(
          width: overlayWidth,
          height: overlayHeight,
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
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Depth Bonus indicator (Phase 7.6 Rule 15)
              Row(
                children: [
                  const Icon(
                    Icons.menu_book,
                    color: Colors.blueAccent,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Spell Shrine',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Text(
                          'Ancient knowledge inscribed in light.',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
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
              const SizedBox(height: 24),

              // Choices - Expanded to fill fixed height
              Expanded(
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
              const SizedBox(height: 24),

              // Skip
              Center(
                child: TextButton(
                  onPressed: widget.onSkip,
                  child: Text(
                    'Leave Shrine',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpellChoiceCard(Spell spell, int index) {
    final isHighTier =
        spell.rarity == SpellRarity.rare ||
        spell.rarity == SpellRarity.signature;
    final isUpgraded = spell.starLevel >= 2;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighTier
              ? _getRarityColor(spell.rarity)
              : _getElementColor(spell.element),
          width: isHighTier ? 2 : 1,
        ),
        // Subtle glow for rare+ spells
        boxShadow: isHighTier
            ? [
                BoxShadow(
                  color: _getRarityColor(spell.rarity).withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  spell.elementIcon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              spell.displayName,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getElementColor(spell.element),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Phase 7.6: Tier badge (Rule 15)
                    _buildTierBadge(spell.rarity, isUpgraded),
                    const SizedBox(height: 4),
                    Text(
                      spell.element.displayName,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: widget.isActionCompleted
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
                  disabledBackgroundColor: Colors.grey.shade800,
                ),
                child: const Text('LEARN'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            spell.baseDescription,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            spell.effectsDescription,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
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
    switch (element) {
      case game_element.Element.fire:
        return const Color(0xFFf85149);
      case game_element.Element.water:
        return const Color(0xFF58a6ff);
      case game_element.Element.earth:
        return const Color(0xFF7c6f4a);
      case game_element.Element.air:
        return const Color(0xFF79c0ff);
    }
  }
}
