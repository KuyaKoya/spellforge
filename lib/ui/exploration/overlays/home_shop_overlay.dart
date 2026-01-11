import 'package:flutter/material.dart';
import '../../../data/item_definitions.dart';
import '../../../systems/progression_system.dart';

class HomeShopOverlay extends StatefulWidget {
  final ProgressionSystem progressionSystem;

  const HomeShopOverlay({super.key, required this.progressionSystem});

  @override
  State<HomeShopOverlay> createState() => _HomeShopOverlayState();
}

class _HomeShopOverlayState extends State<HomeShopOverlay> {
  late List<ConsumableItem> _consumables;
  late List<RelicItem> _relics;

  @override
  void initState() {
    super.initState();
    _consumables = ItemRegistry.consumables;
    _relics = ItemRegistry.relics;
  }

  void _purchaseItem(ItemDefinition item) async {
    // Check cost
    if (widget.progressionSystem.spellFragments < item.baseCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Not enough fragments!',
            style: TextStyle(fontFamily: 'monospace'),
          ),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 500),
        ),
      );
      return;
    }

    // Check if relic already owned for next run
    if (item.type == ItemType.relic &&
        widget.progressionSystem.nextRunRelics.contains(item.id)) {
      return;
    }

    // Deduct cost
    await widget.progressionSystem.spendFragments(item.baseCost);

    // Add to next run inventory
    await widget.progressionSystem.purchaseNextRunItem(item.id, item.type);

    setState(() {}); // Refresh UI

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Purchased ${item.name}!',
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 500),
        ),
      );
    }
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
                    _buildGrid(_consumables),
                    const SizedBox(height: 24),
                    _buildSectionHeader('RELICS (Permanent for one run)'),
                    _buildGrid(_relics),
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
          // Currency Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0d1117),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF30363d)),
            ),
            child: Row(
              children: [
                const Text('💎', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  '${widget.progressionSystem.spellFragments}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF79c0ff),
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

  Widget _buildGrid(List<ItemDefinition> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8, // Taller cards
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildItemCard(items[index]);
      },
    );
  }

  Widget _buildItemCard(ItemDefinition item) {
    final isRelic = item.type == ItemType.relic;
    final isOwnedRelic =
        isRelic && widget.progressionSystem.nextRunRelics.contains(item.id);
    final canAfford = widget.progressionSystem.spellFragments >= item.baseCost;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        border: Border.all(
          color: isOwnedRelic
              ? const Color(0xFF238636)
              : const Color(0xFF30363d),
          width: isOwnedRelic ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (isOwnedRelic || !canAfford)
              ? null
              : () => _purchaseItem(item),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isRelic ? '💍' : '🧪',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const Spacer(),
                    if (isOwnedRelic)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF238636),
                        size: 20,
                      ),
                  ],
                ),
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
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isOwnedRelic
                        ? const Color(0xFF238636).withOpacity(0.2)
                        : (canAfford
                              ? const Color(0xFF1f6feb).withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isOwnedRelic
                          ? const Color(0xFF238636)
                          : (canAfford ? const Color(0xFF1f6feb) : Colors.grey),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isOwnedRelic ? 'OWNED' : '${item.baseCost} 💎',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isOwnedRelic
                          ? const Color(0xFF238636)
                          : (canAfford ? const Color(0xFF58a6ff) : Colors.grey),
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
}
