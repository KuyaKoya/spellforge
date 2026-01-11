import 'package:flutter/material.dart';
import '../../../data/item_definitions.dart';
import '../../../systems/progression_system.dart';
import '../../../systems/shop_rotation.dart';

class HomeShopOverlay extends StatefulWidget {
  final ProgressionSystem progressionSystem;

  const HomeShopOverlay({super.key, required this.progressionSystem});

  @override
  State<HomeShopOverlay> createState() => _HomeShopOverlayState();
}

class _HomeShopOverlayState extends State<HomeShopOverlay> {
  late List<ConsumableItem> _consumables;
  late List<RelicItem> _dailyRelics;

  @override
  void initState() {
    super.initState();
    _consumables = ItemRegistry.consumables;
    // Get daily rotating relics (excludes already owned for next run)
    _dailyRelics = ShopRotation.getDailyRelics(
      DateTime.now(),
      widget.progressionSystem.nextRunRelics,
    );
  }

  void _purchaseConsumable(ConsumableItem item) async {
    // Consumables use fragments
    if (widget.progressionSystem.spellFragments < item.baseCost) {
      _showError('Not enough fragments!');
      return;
    }

    await widget.progressionSystem.spendFragments(item.baseCost);
    await widget.progressionSystem.purchaseNextRunItem(item.id, item.type);

    setState(() {});
    _showSuccess('Purchased ${item.name}!');
  }

  void _purchaseRelic(RelicItem item) async {
    // Relics use crystals
    final cost = ShopRotation.getRelicCost(item);
    if (widget.progressionSystem.spellCrystals < cost) {
      _showError('Not enough crystals!');
      return;
    }

    // Check if already owned
    if (widget.progressionSystem.nextRunRelics.contains(item.id)) {
      return;
    }

    await widget.progressionSystem.spendCrystals(cost);
    await widget.progressionSystem.purchaseNextRunItem(item.id, item.type);

    setState(() {
      // Refresh daily relics to exclude newly purchased
      _dailyRelics = ShopRotation.getDailyRelics(
        DateTime.now(),
        widget.progressionSystem.nextRunRelics,
      );
    });
    _showSuccess('Purchased ${item.name}!');
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'monospace')),
        backgroundColor: Colors.red,
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'monospace')),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0d1117,
      ).withOpacity(0.95), // Match main menu bg
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('CONSUMABLES (One-time use per run)'),
                    _buildConsumableGrid(_consumables),
                    const SizedBox(height: 24),
                    _buildSectionHeader("TODAY'S RELICS (Rotates Daily)"),
                    if (_dailyRelics.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'All available relics already owned!',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      _buildRelicGrid(_dailyRelics),
                  ],
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
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF161b22),
        border: Border(bottom: BorderSide(color: Color(0xFF30363d))),
      ),
      child: Row(
        children: [
          const Text(
            'PREPARATION SHOP',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Fragments (for consumables)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0d1117),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Text('🔮', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  '${widget.progressionSystem.spellFragments}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Crystals (for relics)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0d1117),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  '${widget.progressionSystem.spellCrystals}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8b949e),
        ),
      ),
    );
  }

  Widget _buildConsumableGrid(List<ConsumableItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildConsumableCard(items[index]);
      },
    );
  }

  Widget _buildRelicGrid(List<RelicItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75, // Taller for more info
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildRelicCard(items[index]);
      },
    );
  }

  Widget _buildConsumableCard(ConsumableItem item) {
    final canAfford = widget.progressionSystem.spellFragments >= item.baseCost;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        border: Border.all(color: const Color(0xFF30363d)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canAfford ? () => _purchaseConsumable(item) : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🧪', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    item.description,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF8b949e),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: (canAfford ? const Color(0xFF1f6feb) : Colors.grey)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: canAfford ? const Color(0xFF1f6feb) : Colors.grey,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${item.baseCost} 🔮',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: canAfford ? const Color(0xFF58a6ff) : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRelicCard(RelicItem item) {
    final cost = ShopRotation.getRelicCost(item);
    final canAfford = widget.progressionSystem.spellCrystals >= cost;
    final rarityColor = _getRarityColor(item.rarity);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        border: Border.all(color: rarityColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canAfford ? () => _purchaseRelic(item) : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.element.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const Spacer(),
                    Text(
                      _getRarityLabel(item.rarity),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: rarityColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: rarityColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    item.description,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF8b949e),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: (canAfford ? Colors.amber : Colors.grey).withOpacity(
                      0.1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: canAfford ? Colors.amber : Colors.grey,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$cost ✨',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: canAfford ? Colors.amber : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRarityColor(int rarity) {
    switch (rarity) {
      case 1:
        return Colors.grey.shade400;
      case 2:
        return Colors.greenAccent;
      case 3:
        return Colors.amber;
      default:
        return Colors.white;
    }
  }

  String _getRarityLabel(int rarity) {
    switch (rarity) {
      case 1:
        return 'COMMON';
      case 2:
        return 'UNCOMMON';
      case 3:
        return 'RARE';
      default:
        return '';
    }
  }
}
