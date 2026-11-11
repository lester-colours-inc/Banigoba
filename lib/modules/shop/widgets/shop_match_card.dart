// A piece from a shop or designer you follow that matches your size and
// style, shown in My Daily Dress Up ("New from Glow Boutique, in your size";
// review items D-4 and A-6).
import 'package:flutter/material.dart';

import 'package:banigoba/modules/home/models/feed_matching.dart';
import 'package:banigoba/modules/shop/widgets/safe_product_image.dart';

class ShopMatchCard extends StatelessWidget {
  const ShopMatchCard({
    super.key,
    required this.product,
    required this.match,
    required this.onOpen,
    required this.onDismiss,
  });

  final Map<String, dynamic> product;
  final FeedMatch match;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  static const double width = 190;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = (product['name'] ?? 'New piece').toString();
    final shop = (product['shopName'] ?? '').toString();
    final imageUrl = (product['imageUrl'] ?? product['imageURL'] ?? '')
        .toString();
    final price = (product['price'] as num?)?.toDouble();

    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          key: ValueKey('shop_match_${match.productId}'),
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: colors.surfaceContainerHigh,
                      child: imageUrl.isEmpty
                          ? const Icon(Icons.checkroom_outlined, size: 40)
                          : SafeProductImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton.filledTonal(
                        key: ValueKey('shop_match_dismiss_${match.productId}'),
                        tooltip: 'Not for me',
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        onPressed: onDismiss,
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (shop.isNotEmpty)
                      Text(
                        'New from $shop',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (price != null)
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      match.reasons.join('. '),
                      key: ValueKey('shop_match_reasons_${match.productId}'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.3,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
