import 'package:flutter/material.dart';
import '../domain/spell.dart';
import 'utils/game_colors.dart';

/// Screen for selecting a starting spell before the run begins.
class SpellSelectionScreen extends StatefulWidget {
  final List<Spell> spellChoices;
  final void Function(Spell selectedSpell) onSpellSelected;

  const SpellSelectionScreen({
    super.key,
    required this.spellChoices,
    required this.onSpellSelected,
  });

  @override
  State<SpellSelectionScreen> createState() => _SpellSelectionScreenState();
}

class _SpellSelectionScreenState extends State<SpellSelectionScreen> {
  Spell? _selectedSpell;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0d1117),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              const SizedBox(height: 40),
              const Text(
                'Choose Your Starting Spell',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFc9d1d9),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This spell will define your build',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 40),

              // Spell choices
              Expanded(
                child: ListView.builder(
                  itemCount: widget.spellChoices.length,
                  itemBuilder: (context, index) {
                    final spell = widget.spellChoices[index];
                    final isSelected = _selectedSpell == spell;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildSpellCard(spell, isSelected),
                    );
                  },
                ),
              ),

              // Confirm button
              if (_selectedSpell != null)
                ElevatedButton(
                  onPressed: () => widget.onSpellSelected(_selectedSpell!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF238636),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Begin Your Journey',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpellCard(Spell spell, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedSpell = spell),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161b22),
          border: Border.all(
            color: isSelected
                ? GameColors.getElementColor(spell.element)
                : const Color(0xFF30363d),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Spell name and element
            Row(
              children: [
                Text(spell.elementIcon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
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
                          color: GameColors.getElementColor(spell.element),
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
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF238636),
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Spell stats
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildStat(
                  'Mana',
                  '${spell.manaCost}',
                  const Color(0xFF58a6ff),
                ),
                if (spell.baseDamage > 0)
                  _buildStat(
                    'Damage',
                    '${spell.baseDamage}',
                    const Color(0xFFf85149),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Spell description
            Text(
              spell.baseDescription,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey.shade400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),

            // Effects
            Text(
              spell.effectsDescription,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.grey.shade500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
