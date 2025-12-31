import 'package:flutter/material.dart';
import '../../../systems/shop_system.dart';

class ShopOverlay extends StatelessWidget {
  final ShopSystem shop;
  final int currentFragments;
  final Future<void> Function(int index) onPurchase;
  final VoidCallback onLeave;

  const ShopOverlay({
    super.key,
    required this.shop,
    required this.currentFragments,
    required this.onPurchase,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF161b22).withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF30363d), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
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
            Row(
              children: [
                const Icon(
                  Icons.storefront,
                  color: Colors.greenAccent,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Merchant\'s Stall',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Available Fragments: $currentFragments 💎',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: Colors.teal.shade300,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onLeave,
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Items List
            Expanded(
              child: shop.availableItems.isEmpty
                  ? Center(
                      child: Text(
                        'Sold Out',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 20,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: shop.availableItems.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildShopItemCard(
                          shop.availableItems[index],
                          index,
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),
            TextButton(
              onPressed: onLeave,
              child: Text(
                'Leave Shop',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopItemCard(ShopItem item, int index) {
    final canAfford = currentFragments >= item.cost;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1117),
        border: Border.all(
          color: canAfford ? const Color(0xFF30363d) : Colors.red.shade900,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Icon placeholder (could be based on type)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF161b22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _getItemIcon(item.type),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  item.spell?.baseDescription ?? item.type.description,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.cost} 💎',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: canAfford ? Colors.teal.shade300 : Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: canAfford ? () => onPurchase(index) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade800,
                  disabledBackgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text('BUY'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getItemIcon(ShopItemType type) {
    switch (type) {
      case ShopItemType.spellFragments:
        return '💎';
      case ShopItemType.spellCrystal:
        return '✨';
      case ShopItemType.randomSpell:
        return '📜';
      case ShopItemType.heal:
        return '❤️';
      case ShopItemType.tempBuff:
        return '⚡';
    }
  }
}
