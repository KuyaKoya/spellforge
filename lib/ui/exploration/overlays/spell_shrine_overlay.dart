import 'package:flutter/material.dart';
import '../../../domain/mage.dart';
import '../../../domain/spell.dart';
import '../../../domain/element.dart' as game_element;

class SpellShrineOverlay extends StatefulWidget {
  final List<Spell> spellChoices;
  final Mage mage;
  final bool isActionCompleted;
  final Function(int choiceIndex) onLearn;
  final Function(int loadoutIndex, Spell newSpell) onReplace;
  final VoidCallback onSkip;

  const SpellShrineOverlay({
    super.key,
    required this.spellChoices,
    required this.mage,
    this.isActionCompleted = false,
    required this.onLearn,
    required this.onReplace,
    required this.onSkip,
  });

  @override
  State<SpellShrineOverlay> createState() => _SpellShrineOverlayState();
}

class _SpellShrineOverlayState extends State<SpellShrineOverlay> {
  // If not null, we are selecting a slot to replace with this spell
  Spell? _replacingSpell;

  @override
  Widget build(BuildContext context) {
    if (_replacingSpell != null) {
      return _buildReplaceScreen();
    }

    return Center(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Row(
              children: [
                Icon(Icons.menu_book, color: Colors.blueAccent, size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spell Shrine',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
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
              ],
            ),
            const SizedBox(height: 24),

            // Choices
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
    );
  }

  Widget _buildSpellChoiceCard(Spell spell, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getElementColor(spell.element)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(spell.elementIcon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spell.displayName,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getElementColor(spell.element),
                      ),
                    ),
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
              ElevatedButton(
                onPressed: widget.isActionCompleted
                    ? null
                    : () {
                        if (widget.mage.isLoadoutFull) {
                          setState(() {
                            _replacingSpell = spell;
                          });
                        } else {
                          widget.onLearn(index);
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

  Widget _buildReplaceScreen() {
    return Center(
      child: Container(
        width: 600,
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
                      widget.onReplace(index, _replacingSpell!);
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
