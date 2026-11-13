// Customer boutique marketplace.
//
// This page lets shoppers browse verified boutiques and products. It filters
// seller profiles by shop.verified so only admin-approved boutiques are visible
// in the public marketplace. Search, quick category chips, a full filter
// sheet and sort menus narrow both tabs.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/utils/garment_taxonomy.dart';
import 'package:banigoba/modules/shop/controllers/boutique_detail_controller.dart';
import 'package:banigoba/modules/shop/controllers/shops_controller.dart';
import 'package:banigoba/modules/shop/models/shop_filters.dart';
import 'package:banigoba/modules/shop/widgets/boutique_card.dart';
import 'package:banigoba/modules/shop/widgets/cart_badge_button.dart';
import 'package:banigoba/modules/shop/widgets/product_grid_card.dart';
import 'package:banigoba/modules/shop/widgets/shop_filter_bar.dart';

export 'package:banigoba/modules/shop/controllers/shops_controller.dart'
    show productMatchesQuery;

class ShopsPage extends StatelessWidget {
  const ShopsPage({super.key, this.initialTab = 0, this.initialQuery = ''});

  final int initialTab;

  /// Prefills the search, e.g. "shoe" when arriving from "Find pieces".
  final String initialQuery;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: it can be opened with a tab and a search.
    return GetBuilder<ShopsController>(
      init: ShopsController(initialTab: initialTab, initialQuery: initialQuery),
      global: false,
      builder: (controller) => _ShopsView(controller: controller),
    );
  }
}

/// A verified boutique with the products that survive search and filters.
class _BoutiqueEntry {
  const _BoutiqueEntry({
    required this.sellerId,
    required this.shopName,
    required this.description,
    required this.imageUrl,
    required this.products,
  });

  final String sellerId;
  final String shopName;
  final String description;
  final String imageUrl;
  final List<Map<String, dynamic>> products;

  DateTime get latest => products
      .map((p) => productCreatedAt(p) ?? DateTime(0))
      .fold(DateTime(0), (a, b) => b.isAfter(a) ? b : a);

  double? get fromPrice {
    final prices = products.map(productPrice).where((p) => p > 0);
    return prices.isEmpty ? null : prices.reduce((a, b) => a < b ? a : b);
  }
}

class _ShopsView extends StatelessWidget {
  const _ShopsView({required this.controller});

  static const _primary = Color(0xFF0D0140);

  /// How close to the end of the grid (in pixels) the next page is asked for.
  static const double _loadMoreExtent = 800;

  final ShopsController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text(
          'Shops & Boutiques',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.surface,
        actions: [
          CartBadgeButton(onPressed: controller.openCart),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: TextField(
              controller: controller.search,
              onChanged: controller.onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search boutiques or products',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(
                  () => controller.query.value.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            controller.search.clear();
                            controller.onSearchChanged('');
                          },
                        ),
                ),
                filled: true,
                fillColor: colors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(
              () => Row(
                children: [
                  Expanded(child: _tabButton(context, 'Boutiques', 0)),
                  const SizedBox(width: 10),
                  Expanded(child: _tabButton(context, 'All Products', 1)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ShopFilterBar(controller: controller),
          Expanded(
            child: Obx(
              () => controller.tab.value == 0
                  ? _boutiquesTab(context)
                  : _productsTab(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Boutiques group every product by seller, so they use the whole catalogue.
  Widget _boutiquesTab(BuildContext context) {
    if (controller.failed.value) {
      return const Center(child: Text('Unable to load shops.'));
    }
    if (!controller.loaded.value) {
      return const Center(child: CircularProgressIndicator());
    }
    // Read reactive values up front so Obx always subscribes.
    final filters = controller.filters.value;
    final sort = controller.boutiqueSort.value;
    final matching = controller.matching;
    if (!controller.sellersReady(matching)) {
      return const Center(child: CircularProgressIndicator());
    }
    final products = applyShopFilters(
      matching,
      filters,
      viewerGender: controller.viewerGender.value,
    );
    return _buildBoutiques(context, products, sort);
  }

  /// All Products: the database searches, filters and sorts; the grid shows
  /// what has arrived and asks for the next page near its end.
  Widget _productsTab(BuildContext context) {
    if (controller.pageFailed.value && !controller.pageLoaded.value) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Unable to load products.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: controller.reloadPage,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (!controller.pageLoaded.value) {
      return const Center(child: CircularProgressIndicator());
    }
    // Read reactive values up front so Obx always subscribes.
    final products = controller.pageProducts.toList();
    final total = controller.pageTotal.value;
    final refreshing = controller.pageLoading.value;
    final loadingMore = controller.pageLoadingMore.value;
    final moreFailed = controller.pageMoreFailed.value;
    if (products.isEmpty) {
      return _empty(context, 'No products available.');
    }
    return Column(
      children: [
        _summary('$total product${total == 1 ? '' : 's'}'),
        if (refreshing) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.reloadPage,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.extentAfter < _loadMoreExtent) {
                  controller.loadMorePage();
                }
                return false;
              },
              child: CustomScrollView(
                // Pull-to-refresh and the end-of-list trigger need a scroll
                // even when the first page is short.
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    sliver: SliverGrid.builder(
                      gridDelegate: ProductGridCard.gridDelegate,
                      itemCount: products.length,
                      itemBuilder: (context, index) => ProductGridCard(
                        product: products[index],
                        onTap: () => controller.openProduct(products[index]),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _pageFooter(loadingMore, moreFailed),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pageFooter(bool loadingMore, bool moreFailed) {
    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (moreFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: TextButton(
            onPressed: controller.retryMore,
            child: const Text('Could not load more. Tap to retry'),
          ),
        ),
      );
    }
    return const SizedBox(height: 30);
  }

  bool get _isNarrowed =>
      !controller.filters.value.isEmpty || controller.query.value.isNotEmpty;

  Widget _tabButton(BuildContext context, String label, int index) {
    final selected = controller.tab.value == index;
    final colors = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: () => controller.selectTab(index),
      style: FilledButton.styleFrom(
        backgroundColor: selected ? _primary : colors.surfaceContainerLow,
        foregroundColor: selected ? Colors.white : colors.onSurface,
        elevation: 0,
      ),
      child: Text(label),
    );
  }

  Widget _summary(String label) => ShopResultSummary(
    label: label,
    canClear: _isNarrowed,
    onClear: controller.clearAll,
  );

  Widget _empty(BuildContext context, String message) {
    final narrowed = _isNarrowed;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              narrowed ? Icons.filter_alt_off_outlined : Icons.storefront,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              narrowed ? 'Nothing matches those filters.' : message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (narrowed) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: controller.clearAll,
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<_BoutiqueEntry> _boutiques(
    List<Map<String, dynamic>> products,
    BoutiqueSort sort,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final product in products) {
      final sellerId = ShopsController.sellerOf(product);
      if (sellerId.isNotEmpty && controller.isVerified(sellerId)) {
        grouped.putIfAbsent(sellerId, () => []).add(product);
      }
    }
    final entries = [
      for (final entry in grouped.entries) _entryFor(entry.key, entry.value),
    ];
    switch (sort) {
      case BoutiqueSort.mostProducts:
        entries.sort((a, b) => b.products.length.compareTo(a.products.length));
      case BoutiqueSort.newestArrivals:
        entries.sort((a, b) => b.latest.compareTo(a.latest));
      case BoutiqueSort.nameAZ:
        entries.sort(
          (a, b) =>
              a.shopName.toLowerCase().compareTo(b.shopName.toLowerCase()),
        );
    }
    return entries;
  }

  _BoutiqueEntry _entryFor(
    String sellerId,
    List<Map<String, dynamic>> products,
  ) {
    final user = controller.sellers[sellerId] ?? const {};
    final shop = Map<String, dynamic>.from(user['shop'] as Map? ?? const {});
    return _BoutiqueEntry(
      sellerId: sellerId,
      shopName:
          (shop['name'] ??
                  products.first['shopName'] ??
                  user['displayName'] ??
                  'Boutique')
              .toString(),
      description: (shop['description'] ?? '').toString(),
      imageUrl: (user['profileImageUrl'] ?? '').toString(),
      products: products,
    );
  }

  Widget _buildBoutiques(
    BuildContext context,
    List<Map<String, dynamic>> products,
    BoutiqueSort sort,
  ) {
    final entries = _boutiques(products, sort);
    if (entries.isEmpty) {
      return _empty(context, 'No verified boutiques yet.');
    }
    return Column(
      children: [
        _summary('${entries.length} boutique${entries.length == 1 ? '' : 's'}'),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return BoutiqueCard(
                shopName: entry.shopName,
                description: entry.description,
                imageUrl: entry.imageUrl,
                productCount: entry.products.length,
                fromPrice: entry.fromPrice,
                newCount: entry.products.where(isNewArrival).length,
                previewImageUrls: [
                  for (final p in entry.products)
                    if (garmentImageUrlOf(p).isNotEmpty) garmentImageUrlOf(p),
                ].take(4).toList(),
                onTap: () => controller.openBoutique(
                  sellerId: entry.sellerId,
                  shopName: entry.shopName,
                  description: entry.description,
                  products: entry.products,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class BoutiqueDetailPage extends StatelessWidget {
  const BoutiqueDetailPage({
    super.key,
    required this.sellerId,
    required this.shopName,
    required this.description,
    required this.products,
  });

  final String sellerId;
  final String shopName;
  final String description;
  final List<Map<String, dynamic>> products;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BoutiqueDetailController>(
      init: BoutiqueDetailController(sellerId: sellerId, shopName: shopName),
      global: false,
      builder: (controller) => Scaffold(
        appBar: AppBar(title: Text(shopName)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (description.isNotEmpty) ...[
              Text(description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: controller.messageBoutique,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Message Boutique'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D0140),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: ProductGridCard.gridDelegate,
              itemCount: products.length,
              itemBuilder: (context, index) => ProductGridCard(
                product: products[index],
                onTap: () => controller.openProduct(products[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
