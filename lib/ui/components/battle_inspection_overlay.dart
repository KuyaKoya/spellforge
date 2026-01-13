import 'package:flutter/material.dart';

import '../../domain/mage.dart';
import '../../domain/enemy.dart';
import '../../domain/elite_enemy.dart';
import '../../domain/boss_enemy.dart';
import '../../domain/effect.dart';
import '../../domain/spell.dart';
import 'passive_inspection_widget.dart';
import '../utils/game_colors.dart';

/// Battle inspection overlay with tabs for Player and Enemy details.
///
/// Shows:
/// - Player tab: HP, Mana, Status effects (debuffs/buffs), Spells
/// - Enemy tab: All living enemies with HP, intent, status, passives
class BattleInspectionOverlay extends StatefulWidget {
  final Mage mage;
  final List<Enemy> enemies;
  final VoidCallback onClose;

  const BattleInspectionOverlay({
    super.key,
    required this.mage,
    required this.enemies,
    required this.onClose,
  });

  @override
  State<BattleInspectionOverlay> createState() =>
      _BattleInspectionOverlayState();
}

class _BattleInspectionOverlayState extends State<BattleInspectionOverlay>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent tap-through
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 320,
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161b22),
                  border: Border.all(color: const Color(0xFF30363d), width: 2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with tabs
                    _buildHeader(),

                    // Tab content
                    Flexible(
                      child: TabBarView(
                        controller: _tabController,
                        children: [_buildPlayerTab(), _buildEnemyTab()],
                      ),
                    ),

                    // Close button
                    _buildCloseButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF21262d),
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF58a6ff),
        unselectedLabelColor: const Color(0xFF8b949e),
        indicatorColor: const Color(0xFF58a6ff),
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: '👤 PLAYER'),
          Tab(text: '👹 ENEMIES'),
        ],
      ),
    );
  }

  Widget _buildPlayerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player name and level
          Row(
            children: [
              Text(
                widget.mage.primaryElement.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.mage.name,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFf0f6fc),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF238636).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Lv.${widget.mage.level}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3fb950),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // HP Bar
          _StatBar(
            label: 'HP',
            current: widget.mage.currentHP,
            max: widget.mage.maxHP,
            color: const Color(0xFF3fb950),
          ),

          const SizedBox(height: 8),

          // Mana Bar
          _StatBar(
            label: 'MP',
            current: widget.mage.mana,
            max: widget.mage.maxMana,
            color: const Color(0xFF58a6ff),
          ),

          const SizedBox(height: 8),

          // Actions
          Row(
            children: [
              const SizedBox(
                width: 40,
                child: Text('⚡', style: TextStyle(fontSize: 14)),
              ),
              Text(
                'Actions: ${widget.mage.actionsRemaining}/${widget.mage.actionsPerTurn}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Color(0xFFe3b341),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status Effects
          _buildStatusEffectsSection(),

          const SizedBox(height: 16),

          // Spells summary
          _buildSpellsSection(),
        ],
      ),
    );
  }

  Widget _buildStatusEffectsSection() {
    final effects = widget.mage.statusEffects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚡ STATUS EFFECTS',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        if (effects.isEmpty)
          Text(
            'No active status effects',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          )
        else
          ...effects.map((effect) => _buildStatusEffectRow(effect)),
      ],
    );
  }

  Widget _buildStatusEffectRow(ActiveStatusEffect effect) {
    final color = _getEffectColor(effect.type);
    final icon = _getEffectIcon(effect.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  effect.type.displayName,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  'Value: ${effect.value} • ${effect.remainingDuration} turns left',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpellsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📖 SPELLS',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.mage.spellLoadout.map((spell) => _buildSpellCard(spell)),
      ],
    );
  }

  Widget _buildSpellCard(Spell spell) {
    final canCast = widget.mage.canCast(spell);
    final elementColor = GameColors.getElementColorFromString(
      spell.element.name,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: canCast
            ? elementColor.withValues(alpha: 0.1)
            : const Color(0xFF21262d),
        border: Border.all(
          color: canCast ? elementColor : const Color(0xFF30363d),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon, Name, Mana, Stars
          Row(
            children: [
              Text(spell.elementIcon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  spell.name,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: canCast
                        ? const Color(0xFFf0f6fc)
                        : Colors.grey.shade600,
                  ),
                ),
              ),
              // Mana cost
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF58a6ff).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${spell.manaCost}💧',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF58a6ff),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Stars
              Text(
                spell.starsDisplay,
                style: const TextStyle(fontSize: 10, color: Color(0xFFe3b341)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Effects row: damage + targeting
          Row(
            children: [
              // Damage
              if (spell.baseDamage > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf85149).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '⚔️ ${spell.baseDamage}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFf85149),
                    ),
                  ),
                ),
              if (spell.baseDamage > 0) const SizedBox(width: 6),
              // Targeting
              Text(
                spell.targetingInfo,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
          // Status effects if any
          if (spell.effects.any((e) => e.isStatusEffect)) ...[
            const SizedBox(height: 4),
            Text(
              spell.compactSummary,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnemyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.enemies
            .map((enemy) => _buildEnemyCard(enemy))
            .toList(),
      ),
    );
  }

  Widget _buildEnemyCard(Enemy enemy) {
    final elementColor = GameColors.getElementColorFromString(
      enemy.element.name,
    );
    final isElite = enemy is EliteEnemy;
    final isBoss = enemy is BossEnemy;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF21262d),
        border: Border.all(
          color: isBoss
              ? const Color(0xFFbc8cff)
              : isElite
              ? const Color(0xFFffd700)
              : elementColor.withValues(alpha: 0.5),
          width: isBoss || isElite ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(enemy.element.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  enemy.name,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFf0f6fc),
                  ),
                ),
              ),
              if (isBoss)
                _buildBadge('BOSS', const Color(0xFFbc8cff))
              else if (isElite)
                _buildBadge('ELITE', const Color(0xFFffd700)),
            ],
          ),

          const SizedBox(height: 8),

          // HP Bar
          _StatBar(
            label: 'HP',
            current: enemy.currentHP,
            max: enemy.maxHP,
            color: const Color(0xFF3fb950),
            compact: true,
          ),

          const SizedBox(height: 8),

          // Stats row
          Row(
            children: [
              _buildStatChip(
                '⚔️',
                '${enemy.getEffectiveDamage()}',
                const Color(0xFFf85149),
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                '🛡️',
                '${enemy.armorGain}',
                const Color(0xFF58a6ff),
              ),
              const Spacer(),
              // Intent
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: elementColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${enemy.intent.vagueIcon} ${enemy.intent.displayName}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: elementColor,
                  ),
                ),
              ),
            ],
          ),

          // Status effects
          if (enemy.statusEffects.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: enemy.statusEffects
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getEffectColor(e.type).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_getEffectIcon(e.type)} ${e.remainingDuration}t',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          color: _getEffectColor(e.type),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          // Passives for elite/boss
          if (isElite) _buildElitePassives(enemy, isBoss),
        ],
      ),
    );
  }

  Widget _buildElitePassives(EliteEnemy eliteEnemy, bool isBoss) {
    if (eliteEnemy.passives.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: PassiveInspectionWidget(
        passives: eliteEnemy.passives,
        alwaysVisible: isBoss,
        accentColor: isBoss ? const Color(0xFFbc8cff) : const Color(0xFFffd700),
        passiveState: eliteEnemy.passiveState,
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatChip(String icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: GestureDetector(
        onTap: widget.onClose,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF21262d),
            border: Border.all(color: const Color(0xFF30363d)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Center(
            child: Text(
              'CLOSE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8b949e),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getEffectColor(EffectType type) {
    switch (type) {
      case EffectType.burn:
        return const Color(0xFFf85149);
      case EffectType.slow:
        return const Color(0xFF58a6ff);
      case EffectType.weaken:
        return const Color(0xFFbc8cff);
      case EffectType.armor:
        return const Color(0xFF58a6ff);
      default:
        return const Color(0xFF8b949e);
    }
  }

  String _getEffectIcon(EffectType type) {
    switch (type) {
      case EffectType.burn:
        return '🔥';
      case EffectType.slow:
        return '🐌';
      case EffectType.weaken:
        return '💀';
      case EffectType.armor:
        return '🛡️';
      case EffectType.actionGain:
        return '⚡';
      case EffectType.delay:
        return '⏸️';
      default:
        return '•';
    }
  }
}

/// Compact stat bar widget.
class _StatBar extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final Color color;
  final bool compact;

  const _StatBar({
    required this.label,
    required this.current,
    required this.max,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final percent = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: compact ? 30 : 40,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: compact ? 9 : 10,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: compact ? 6 : 8,
            decoration: BoxDecoration(
              color: const Color(0xFF21262d),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$current/$max',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: compact ? 9 : 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
