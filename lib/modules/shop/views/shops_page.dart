// Customer boutique marketplace.
//
// This page lets shoppers browse verified boutiques and products. It filters
// seller profiles by shop.verified so only admin-approved boutiques are visible
// in the public marketplace.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/boutique_detail_controller.dart';
import 'package:banigoba/modules/shop/controllers/shops_controller.dart';
import 'package:banigoba/modules/shop/widgets/boutique_card.dart';
import 'package:banigoba/modules/shop/widgets/cart_badge_button.dart';
import 'package:banigoba/modules/shop/widgets/product_grid_card.dart';

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

class _ShopsView extends StatelessWidget {
  const _ShopsView({required this.controller});

  static const _primary = Color(0xFF0D0140);

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
              decoration: InputDecoration(
                hintText: 'Search boutiques or products',
                prefixIcon: const Icon(Icons.search),
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
          const SizedBox(height: 14),
          Expanded(
            child: Obx(() {
              if (controller.failed.value) {
                return const Center(child: Text('Unable to load shops.'));
              }
              if (!controller.loaded.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final products = controller.matching;
              return controller.tab.value == 0
                  ? _buildBoutiques(products)
                  : _buildVerifiedProducts(products);
            }),
          ),
        ],
      ),
    );
  }

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

  Widget _buildBoutiques(List<Map<String, dynamic>> products) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final product in products) {
      final sellerId = ShopsController.sellerOf(product);
      if (sellerId.isNotEmpty) {
        grouped.putIfAbsent(sellerId, () => []).add(product);
      }
    }
    if (grouped.isEmpty) {
      return const Center(
        child: Text('No boutiques have listed products yet.'),
      );
    }
    if (!controller.sellersReady(products)) {
      return const Center(child: CircularProgressIndicator());
    }

    final verifiedEntries = grouped.entries
        .where((entry) => controller.isVerified(entry.key))
        .toList();
    if (verifiedEntries.isEmpty) {
      return const Center(child: Text('No verified boutiques yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
      itemCount: verifiedEntries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final entry = verifiedEntries[index];
        final user = controller.sellers[entry.key] ?? const {};
        final shop = Map<String, dynamic>.from(
          user['shop'] as Map? ?? const {},
        );
        final shopName =
            (shop['name'] ??
                    entry.value.first['shopName'] ??
                    user['displayName'] ??
                    'Boutique')
                .toString();
        final description = (shop['description'] ?? '').toString();
        return BoutiqueCard(
          shopName: shopName,
          description: description,
          imageUrl: (user['profileImageUrl'] ?? '').toString(),
          productCount: entry.value.length,
          onTap: () => controller.openBoutique(
            sellerId: entry.key,
            shopName: shopName,
            description: description,
            products: entry.value,
          ),
        );
      },
    );
  }

  Widget _buildVerifiedProducts(List<Map<String, dynamic>> products) {
    final hasSellers = products.any(
      (product) => ShopsController.sellerOf(product).isNotEmpty,
    );
    if (!hasSellers) {
      return const Center(child: Text('No products available.'));
    }
    if (!controller.sellersReady(products)) {
      return const Center(child: CircularProgressIndicator());
    }
    final verified = products
        .where((p) => controller.isVerified(ShopsController.sellerOf(p)))
        .toList();
    if (verified.isEmpty) {
      return const Center(child: Text('No products available.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.68,
      ),
      itemCount: verified.length,
      itemBuilder: (context, index) => ProductGridCard(
        product: verified[index],
        onTap: () => controller.openProduct(verified[index]),
      ),
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
