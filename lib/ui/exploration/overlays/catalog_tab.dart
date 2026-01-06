import 'package:flutter/material.dart';
import '../../../data/spell_definitions.dart';
import '../../../data/enemy_definitions.dart';
import '../../../data/elite_definitions.dart';
import '../../../data/passive_definitions.dart';
import '../../../domain/spell.dart';
import '../../../domain/elite_enemy.dart';
import '../../../domain/effect.dart';
import '../../../domain/enemy_passive.dart';

class CatalogTab extends StatefulWidget {
  const CatalogTab({super.key});

  @override
  State<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<CatalogTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF161b22),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.grey,
            isScrollable: true,
            tabs: const [
              Tab(text: 'SPELLS'),
              Tab(text: 'ENEMIES'),
              Tab(text: 'STATUS EFFECTS'),
              Tab(text: 'PASSIVES'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSpellsList(),
              _buildEnemiesList(),
              _buildStatusEffectsList(),
              _buildPassivesList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpellsList() {
    final spells = SpellDefinitions.allSpells;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: spells.length,
      itemBuilder: (context, index) {
        final spell = spells[index];
        return Card(
          color: const Color(0xFF0d1117),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade800),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      spell.element.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        spell.name,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${spell.manaCost} MP',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.lightBlueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  spell.baseDescription,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: spell.effects
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            spell.getEffectLine(e),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: [
                    _buildTag(
                      spell.rarity.name.toUpperCase(),
                      _getRarityColor(spell.rarity),
                    ),
                    _buildTag(spell.element.displayName, null),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnemiesList() {
    // Collect all enemies (standard + elites)
    final standardEnemies = EnemyDefinitions.allEnemies
        .map((gen) => gen())
        .toList();

    // Flatten elite encounters
    final Set<String> processedEliteIds = {};
    final List<EliteEnemy> eliteEnemies = [];

    for (final encounterGen in EliteDefinitions.allEliteEncounters) {
      final encounter = encounterGen();
      for (final enemy in encounter) {
        if (!processedEliteIds.contains(enemy.id)) {
          eliteEnemies.add(enemy);
          processedEliteIds.add(enemy.id);
        }
      }
    }

    final allEnemies = [...standardEnemies, ...eliteEnemies];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allEnemies.length,
      itemBuilder: (context, index) {
        final enemy = allEnemies[index];
        final isElite = enemy is EliteEnemy;
        final passives = PassiveDefinitions.getPassivesForEnemy(enemy.id);

        return Card(
          color: const Color(0xFF0d1117),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: isElite ? Colors.amber.shade900 : Colors.grey.shade800,
              width: isElite ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      enemy.element.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        enemy.name,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isElite ? Colors.amber : Colors.white,
                        ),
                      ),
                    ),
                    _buildTag(
                      isElite ? 'ELITE' : 'STANDARD',
                      isElite ? Colors.amber.shade700 : Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      'HP: ${enemy.maxHP}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.flash_on, size: 16, color: Colors.yellow),
                    const SizedBox(width: 4),
                    Text(
                      'DMG: ${enemy.attackDamage}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (passives.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'PASSIVES:',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...passives.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.icon),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  p.description,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTag(String label, Color? color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey.shade700).withValues(alpha: 0.3),
        border: Border.all(color: (color ?? Colors.grey.shade600)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          color: color ?? Colors.grey.shade300,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getRarityColor(SpellRarity rarity) {
    switch (rarity) {
      case SpellRarity.common:
        return Colors.white;
      case SpellRarity.uncommon:
        return Colors.green;
      case SpellRarity.rare:
        return Colors.blue;
      case SpellRarity.signature:
        return Colors.purple;
    }
  }

  Widget _buildStatusEffectsList() {
    // List all effect types that can be status effects
    final statusEffects = [
      {
        'type': EffectType.burn,
        'icon': '🔥',
        'description': 'Deals damage over time each turn',
        'example': 'Burn (5 damage/turn) for 3 turns',
      },
      {
        'type': EffectType.slow,
        'icon': '❄️',
        'description': 'Reduces available actions per turn',
        'example': 'Slow (-1 action) for 2 turns',
      },
      {
        'type': EffectType.weaken,
        'icon': '💔',
        'description': 'Reduces damage output',
        'example': 'Weaken (-30% damage) for 3 turns',
      },
      {
        'type': EffectType.armor,
        'icon': '🛡️',
        'description': 'Absorbs incoming damage',
        'example': 'Armor (5) for 2 turns',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: statusEffects.length,
      itemBuilder: (context, index) {
        final effect = statusEffects[index];
        return Card(
          color: const Color(0xFF0d1117),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade800),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      effect['icon'] as String,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        (effect['type'] as EffectType).displayName,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    _buildTag('STATUS', Colors.purple),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  effect['description'] as String,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade700),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.lightBlueAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          effect['example'] as String,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: Colors.lightBlueAccent,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPassivesList() {
    // Collect all unique passives
    final allPassives = <EnemyPassive>[];
    final processedNames = <String>{};

    // Add all passive definitions
    final passiveSets = [
      PassiveDefinitions.burnwardColossusPassives(),
      PassiveDefinitions.tempestTwinAPassives(),
      PassiveDefinitions.tempestTwinBPassives(),
      PassiveDefinitions.glacialExecutionerPassives(),
      PassiveDefinitions.infernalWarlordPassives(),
      PassiveDefinitions.stoneSentinelPassives(),
      PassiveDefinitions.typhoonHeraldPassives(),
      PassiveDefinitions.gatekeeperPyrePassives(),
      PassiveDefinitions.gatekeeperTidePassives(),
    ];

    for (final passiveSet in passiveSets) {
      for (final passive in passiveSet) {
        if (!processedNames.contains(passive.name)) {
          allPassives.add(passive);
          processedNames.add(passive.name);
        }
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allPassives.length,
      itemBuilder: (context, index) {
        final passive = allPassives[index];
        return Card(
          color: const Color(0xFF0d1117),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.amber.shade900),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(passive.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        passive.name,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    _buildTag('PASSIVE', Colors.amber.shade700),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  passive.description,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
