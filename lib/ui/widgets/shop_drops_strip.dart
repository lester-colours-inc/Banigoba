// "From the shops" on Community (K-9): links shops shared with the public.
// Tapping one opens its pieces, to try on and buy. Hidden when there are none.
import 'package:flutter/material.dart';

import '../../data/models/shop_link.dart';
import '../../data/services/shop_link_service.dart';
import '../screens/shop/shared_stock_page.dart';
import 'safe_product_image.dart';

class ShopDropsStrip extends StatefulWidget {
  const ShopDropsStrip({super.key, this.load, this.onOpen});

  /// The public links; the real one reads the database.
  final Future<List<ShopLink>> Function()? load;
  final ValueChanged<ShopLink>? onOpen;

  @override
  State<ShopDropsStrip> createState() => _ShopDropsStripState();
}

class _ShopDropsStripState extends State<ShopDropsStrip> {
  late final Future<List<ShopLink>> _links = _fetch();

  Future<List<ShopLink>> _fetch() async {
    try {
      return await (widget.load ?? () => ShopLinkService().publicLinks())();
    } on Object {
      return const [];
    }
  }

  void _open(ShopLink link) {
    if (widget.onOpen case final open?) return open(link);
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => SharedStockPage(linkId: link.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<List<ShopLink>>(
      future: _links,
      builder: (context, snapshot) {
        final links = snapshot.data ?? const <ShopLink>[];
        if (links.isEmpty) return const SizedBox.shrink();
        return Column(
          key: const ValueKey('shop_drops'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                'From the shops',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: links.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final link = links[index];
                  return InkWell(
                    key: ValueKey('drop_${link.id}'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _open(link),
                    child: SizedBox(
                      width: 140,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SafeProductImage(
                              imageUrl: link.coverImageUrl,
                              width: 140,
                              height: 130,
                              iconSize: 32,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            link.shopName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            link.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
