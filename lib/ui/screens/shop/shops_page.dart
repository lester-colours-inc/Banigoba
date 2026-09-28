// Customer boutique marketplace.
//
// This page lets shoppers browse verified boutiques and products. It filters
// seller profiles by shop.verified so only admin-approved boutiques are visible
// in the public marketplace.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/app_routes.dart';
import '../../../data/services/product_service.dart';
import '../../../data/utils/garment_taxonomy.dart';
import '../../../data/services/shop_chat_service.dart';
import '../../widgets/cart_badge_button.dart';
import '../../widgets/safe_product_image.dart';
import 'product_detail_page.dart';
import 'shop_chat_page.dart';

/// Matches a lower-case search [query] against the product's name, shop,
/// category and garment group, so "bottoms" also finds trousers and skirts.
bool productMatchesQuery(Map<String, dynamic> product, String query) {
  if (query.isEmpty) return true;
  final haystack = [
    product['name'],
    product['shopName'],
    product['category'],
    product['subcategory'],
    garmentGroupOf(product),
  ].map((value) => (value ?? '').toString().toLowerCase()).join(' ');
  return haystack.contains(query);
}

class ShopsPage extends StatefulWidget {
  const ShopsPage({super.key, this.initialTab = 0, this.initialQuery = ''});

  final int initialTab;

  /// Prefills the search, e.g. "shoe" when arriving from "Find pieces".
  final String initialQuery;

  @override
  State<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends State<ShopsPage> {
  static const _primary = Color(0xFF0D0140);
  final _productService = ProductService();
  late final TextEditingController _search = TextEditingController(
    text: widget.initialQuery,
  );
  late int _tab;
  late String _query = widget.initialQuery.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab.clamp(0, 1);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

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
          CartBadgeButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: TextField(
              controller: _search,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
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
            child: Row(
              children: [
                Expanded(child: _tabButton('Boutiques', 0)),
                const SizedBox(width: 10),
                Expanded(child: _tabButton('All Products', 1)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _productService.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Unable to load shops.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final products = snapshot.data!.docs
                    .map((doc) {
                      final data = Map<String, dynamic>.from(
                        doc.data() as Map<String, dynamic>,
                      );
                      data['id'] = doc.id;
                      return data;
                    })
                    .where((product) => productMatchesQuery(product, _query))
                    .toList();

                return _tab == 0
                    ? _buildBoutiques(products)
                    : _buildVerifiedProducts(products);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _tab == index;
    return FilledButton(
      onPressed: () => setState(() => _tab = index),
      style: FilledButton.styleFrom(
        backgroundColor: selected
            ? _primary
            : Theme.of(context).colorScheme.surfaceContainerLow,
        foregroundColor: selected
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      child: Text(label),
    );
  }

  Widget _buildBoutiques(List<Map<String, dynamic>> products) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final product in products) {
      final sellerId = (product['uploaderId'] ?? '').toString();
      if (sellerId.isNotEmpty) {
        grouped.putIfAbsent(sellerId, () => []).add(product);
      }
    }
    if (grouped.isEmpty) {
      return const Center(
        child: Text('No boutiques have listed products yet.'),
      );
    }

    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: _loadSellerProfiles(grouped.keys),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sellers = snapshot.data ?? const <String, Map<String, dynamic>>{};
        final verifiedEntries = grouped.entries.where((entry) {
          final user = sellers[entry.key] ?? const <String, dynamic>{};
          final shop = Map<String, dynamic>.from(
            user['shop'] as Map? ?? const {},
          );
          return shop['verified'] == true;
        }).toList();

        if (verifiedEntries.isEmpty) {
          return const Center(child: Text('No verified boutiques yet.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          itemCount: verifiedEntries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final entry = verifiedEntries[index];
            final user = sellers[entry.key] ?? const <String, dynamic>{};
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
            final imageUrl =
                (user['profileImageURL'] ?? user['profileImageUrl'] ?? '')
                    .toString();

            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => BoutiqueDetailPage(
                      sellerId: entry.key,
                      shopName: shopName,
                      description: description,
                      products: entry.value,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: _primary,
                        backgroundImage: imageUrl.isEmpty
                            ? null
                            : CachedNetworkImageProvider(imageUrl),
                        child: imageUrl.isEmpty
                            ? Text(
                                shopName.isEmpty
                                    ? 'B'
                                    : shopName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shopName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text('${entry.value.length} products'),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, Map<String, dynamic>>> _loadSellerProfiles(
    Iterable<String> sellerIds,
  ) async {
    // Products store uploader IDs, so profile verification has to be checked
    // against the seller user documents before rendering public listings.
    final entries = await Future.wait(
      sellerIds.map((sellerId) async {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(sellerId)
            .get();
        return MapEntry(sellerId, doc.data() ?? const <String, dynamic>{});
      }),
    );
    return Map<String, Map<String, dynamic>>.fromEntries(entries);
  }

  Widget _buildProducts(List<Map<String, dynamic>> products) {
    if (products.isEmpty) {
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
      itemCount: products.length,
      itemBuilder: (context, index) => _ProductShopCard(
        product: products[index],
        onTap: () => _openProduct(products[index]),
      ),
    );
  }

  Widget _buildVerifiedProducts(List<Map<String, dynamic>> products) {
    final sellerIds = products
        .map((product) => (product['uploaderId'] ?? '').toString())
        .where((sellerId) => sellerId.isNotEmpty)
        .toSet();
    if (sellerIds.isEmpty) {
      return const Center(child: Text('No products available.'));
    }

    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: _loadSellerProfiles(sellerIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sellers = snapshot.data ?? const <String, Map<String, dynamic>>{};
        final verifiedProducts = products.where((product) {
          final sellerId = (product['uploaderId'] ?? '').toString();
          final user = sellers[sellerId] ?? const <String, dynamic>{};
          final shop = Map<String, dynamic>.from(
            user['shop'] as Map? ?? const {},
          );
          return shop['verified'] == true;
        }).toList();

        return _buildProducts(verifiedProducts);
      },
    );
  }

  void _openProduct(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailPage(
          productId: product['id']?.toString(),
          productData: product,
        ),
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
    return Scaffold(
      appBar: AppBar(title: Text(shopName)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (description.isNotEmpty) ...[
            Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: () => _messageBoutique(context),
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              childAspectRatio: 0.68,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) => _ProductShopCard(
              product: products[index],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ProductDetailPage(
                    productId: products[index]['id']?.toString(),
                    productData: products[index],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _messageBoutique(BuildContext context) async {
    final customer = FirebaseAuth.instance.currentUser;
    if (customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to send messages.')),
      );
      return;
    }
    if (customer.uid == sellerId) return;
    final chatId = await ShopChatService().ensureConversation(
      sellerId: sellerId,
      customerId: customer.uid,
      shopName: shopName,
    );
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            ShopChatPage(chatId: chatId, title: shopName, asSeller: false),
      ),
    );
  }
}

class _ProductShopCard extends StatelessWidget {
  const _ProductShopCard({required this.product, required this.onTap});

  final Map<String, dynamic> product;
  final VoidCallback onTap;

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
