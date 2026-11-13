// One boutique: banner and logo, a Message button, then its pieces with the
// same filters, sort and category chips as the marketplace.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/utils/garment_taxonomy.dart';
import 'package:banigoba/modules/shop/controllers/boutique_detail_controller.dart';
import 'package:banigoba/modules/shop/models/shop_filters.dart';
import 'package:banigoba/modules/shop/widgets/product_grid_card.dart';
import 'package:banigoba/modules/shop/widgets/shop_filter_bar.dart';
import 'package:banigoba/modules/shop/widgets/shop_filter_sheet.dart';

const Color _primary = Color(0xFF0D0140);

class BoutiqueDetailPage extends StatelessWidget {
  const BoutiqueDetailPage({
    super.key,
    required this.sellerId,
    required this.shopName,
    required this.description,
    required this.products,
    this.imageUrl = '',
  });

  final String sellerId;
  final String shopName;
  final String description;
  final String imageUrl;
  final List<Map<String, dynamic>> products;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BoutiqueDetailController>(
      init: BoutiqueDetailController(
        sellerId: sellerId,
        shopName: shopName,
        products: products,
      ),
      global: false,
      builder: (c) => Scaffold(
        appBar: AppBar(title: Text(shopName)),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(context, c)),
            SliverToBoxAdapter(child: _filterStrip(context, c)),
            Obx(() {
              final items = c.visible;
              final filters = c.filters.value;
              if (items.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _empty(context, c),
                );
              }
              return SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: _summary(context, c, items.length, filters),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                    sliver: SliverGrid.builder(
                      gridDelegate: ProductGridCard.gridDelegate,
                      itemCount: items.length,
                      itemBuilder: (context, index) => ProductGridCard(
                        product: items[index],
                        onTap: () => c.openProduct(items[index]),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  /// A collage banner of up to four pieces, the logo overlapping its edge.
  Widget _header(BuildContext context, BoutiqueDetailController c) {
    final pictures = [
      for (final p in products)
        if (garmentImageUrlOf(p).isNotEmpty) garmentImageUrlOf(p),
    ].take(4).toList();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final fill = Theme.of(context).colorScheme.surfaceContainerLow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: 150,
              child: Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: ColoredBox(
                        color: fill,
                        child: SizedBox.expand(
                          child: i < pictures.length
                              ? CachedNetworkImage(
                                  imageUrl: pictures[i],
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) =>
                                      const SizedBox.shrink(),
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              bottom: -36,
              child: CircleAvatar(
                radius: 42,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: _primary,
                  backgroundImage: imageUrl.isEmpty
                      ? null
                      : CachedNetworkImageProvider(imageUrl),
                  child: imageUrl.isEmpty
                      ? Text(
                          shopName.isEmpty ? 'B' : shopName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 46, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shopName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${products.length} product${products.length == 1 ? '' : 's'}',
                style: TextStyle(color: muted, fontWeight: FontWeight.w600),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(fontSize: 15)),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: c.messageBoutique,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Message Boutique'),
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterStrip(BuildContext context, BoutiqueDetailController c) {
    return Obx(() {
      final filters = c.filters.value;
      return ShopFilterStrip(
        filters: filters,
        categories: c.options.categories,
        onToggleCategory: c.toggleCategory,
        onClearCategories: c.clearCategories,
        sort: ShopSortMenu(selected: filters.sort, onSelected: c.setSort),
        onOpenSheet: () async {
          final result = await showShopFilterSheet(
            context,
            initial: c.filters.value,
            options: c.options,
            products: c.products,
          );
          if (result != null) c.setFilters(result);
        },
      );
    });
  }

  Widget _summary(
    BuildContext context,
    BoutiqueDetailController c,
    int count,
    ShopFilters filters,
  ) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 12, 2),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$count product${count == 1 ? '' : 's'}',
                style: TextStyle(color: muted, fontWeight: FontWeight.w600),
              ),
            ),
            if (!filters.isEmpty)
              TextButton.icon(
                onPressed: c.clearFilters,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Clear all'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, BoutiqueDetailController c) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_alt_off_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            c.products.isEmpty
                ? 'No products yet.'
                : 'Nothing matches those filters.',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (c.products.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: c.clearFilters,
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    ),
  );
}
