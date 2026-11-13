// The top of the shop's Home tab: three numbers that say what needs doing,
// and the pieces that need restocking.
import 'package:flutter/material.dart';

import 'package:banigoba/core/utils/stock_status.dart';
import 'package:banigoba/modules/shop/models/shop_activity.dart';
import 'package:banigoba/modules/shop/widgets/safe_product_image.dart';

const Color _navy = Color(0xFF0D0140);

/// New orders (the lead tile), unread chats and pieces to restock.
class ShopPulseStrip extends StatelessWidget {
  const ShopPulseStrip({
    super.key,
    required this.pulse,
    required this.onOrders,
    required this.onMessages,
    required this.onStock,
  });

  final ShopPulse pulse;
  final VoidCallback onOrders;
  final VoidCallback onMessages;
  final VoidCallback onStock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: _PulseTile(
              key: const ValueKey('pulse_orders'),
              value: pulse.newOrders,
              label: pulse.newOrders == 1 ? 'new order' : 'new orders',
              footnote: '${pulse.openOrders} open',
              icon: Icons.shopping_bag_outlined,
              lead: true,
              onTap: onOrders,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: _PulseTile(
              key: const ValueKey('pulse_messages'),
              value: pulse.unreadChats,
              label: 'unread',
              footnote: 'Reply',
              icon: Icons.chat_bubble_outline,
              onTap: onMessages,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: _PulseTile(
              key: const ValueKey('pulse_stock'),
              value: pulse.needsRestock,
              label: 'to restock',
              footnote: 'Stock',
              icon: Icons.inventory_2_outlined,
              warn: pulse.needsRestock > 0,
              onTap: onStock,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseTile extends StatelessWidget {
  const _PulseTile({
    super.key,
    required this.value,
    required this.label,
    required this.footnote,
    required this.icon,
    required this.onTap,
    this.lead = false,
    this.warn = false,
  });

  final int value;
  final String label;
  final String footnote;
  final IconData icon;
  final VoidCallback onTap;
  final bool lead;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = lead ? Colors.white : scheme.onSurface;
    final soft = lead ? Colors.white70 : scheme.onSurfaceVariant;
    return Material(
      color: lead ? _navy : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: soft),
                  const Spacer(),
                  if (warn)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: lead ? 34 : 28,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: fg,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700, color: fg),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      footnote,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: soft),
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 14, color: soft),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A sideways row of the pieces that are low or sold out.
class RestockRow extends StatelessWidget {
  const RestockRow({super.key, required this.products, required this.onTap});

  final List<Map<String, dynamic>> products;
  final ValueChanged<StockLevel> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) =>
            _RestockChip(product: products[index], onTap: onTap),
      ),
    );
  }
}

class _RestockChip extends StatelessWidget {
  const _RestockChip({required this.product, required this.onTap});

  final Map<String, dynamic> product;
  final ValueChanged<StockLevel> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final level = stockLevelOf(product);
    final soldOut = level == StockLevel.soldOut;
    final badge = soldOut ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final image =
        (product['rawImageUrl'] ??
                product['imageUrl'] ??
                product['imageURL'] ??
                '')
            .toString();
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap(level),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SafeProductImage(
                  imageUrl: image,
                  width: 48,
                  height: 48,
                  iconSize: 20,
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (product['name'] ?? 'Piece').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      soldOut ? 'Sold out' : '${totalStock(product)} left',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: badge,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}
