import 'package:banigoba/modules/shop/services/product_service.dart';
import 'package:flutter/material.dart';

import 'package:banigoba/modules/shop/widgets/safe_product_image.dart';
import 'package:banigoba/modules/shop/views/product_detail_page.dart';

class ShopProductsPage extends StatelessWidget {
  const ShopProductsPage({
    super.key,
    required this.sellerId,
    required this.shopName,
  });

  final String sellerId;
  final String shopName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(shopName.isEmpty ? 'Boutique' : shopName)),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ProductService().getAdminProducts(sellerId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load products.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data!;
          if (products.isEmpty) {
            return const Center(child: Text('No products listed yet.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              childAspectRatio: 0.68,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _ShopProductTile(
                product: product,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ProductDetailPage(
                      productId: product['id'].toString(),
                      productData: product,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ShopProductTile extends StatelessWidget {
  const _ShopProductTile({required this.product, required this.onTap});

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
