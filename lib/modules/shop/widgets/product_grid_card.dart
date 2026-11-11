// A product tile in a two-column grid: picture, name and price.
import 'package:flutter/material.dart';

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
              child: SafeProductImage(
                imageUrl: imageUrl,
                width: double.infinity,
                fit: BoxFit.contain,
                iconSize: 50,
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
              child: Text(
                price > 0 ? '\$${price.toStringAsFixed(2)}' : 'View product',
                style: const TextStyle(
                  color: Color(0xFF0D0140),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
