// A product tile in a two-column grid: picture, name and price.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/shop/models/shop_filters.dart';
import 'package:banigoba/modules/shop/widgets/colour_swatch.dart';
import 'package:banigoba/modules/shop/widgets/safe_product_image.dart';

class ProductGridCard extends StatelessWidget {
  const ProductGridCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Map<String, dynamic> product;
  final VoidCallback onTap;

  static const SliverGridDelegate gridDelegate =
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.68,
      );

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        (product['rawImageUrl'] ??
                product['imageUrl'] ??
                product['imageURL'] ??
                '')
            .toString();
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SafeProductImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    iconSize: 50,
                  ),
                  if (_badge(product) case final badge?)
                    Positioned(top: 8, left: 8, child: badge),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
              child: Text(
                (product['name'] ?? 'Product').toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      price > 0
                          ? '\$${price.toStringAsFixed(2)}'
                          : 'View product',
                      style: const TextStyle(
                        color: Color(0xFF0D0140),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (final colour in productColours(product).take(4))
                    Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: ColourSwatch(name: colour, size: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sold out beats low stock beats new.
  static Widget? _badge(Map<String, dynamic> product) {
    final hasStockInfo =
        product.containsKey('stock') || product['sizeInventory'] is Map;
    final stock = productStock(product);
    if (hasStockInfo && stock <= 0) {
      return const _Badge('Sold out', Color(0xFF6B6B6B));
    }
    if (hasStockInfo && stock <= kLowStockThreshold) {
      return _Badge('Only $stock left', const Color(0xFFC0392B));
    }
    if (isNewArrival(product)) {
      return const _Badge('NEW', Color(0xFF0D0140));
    }
    return null;
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.colour);

  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: colour,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    ),
  );
}
