import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/shop_products_controller.dart';
import 'package:banigoba/modules/shop/widgets/product_grid_card.dart';

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
    return GetBuilder<ShopProductsController>(
      init: ShopProductsController(sellerId: sellerId),
      global: false,
      builder: (controller) => Scaffold(
        appBar: AppBar(title: Text(shopName.isEmpty ? 'Boutique' : shopName)),
        body: Obx(() {
          if (controller.failed.value) {
            return const Center(child: Text('Unable to load products.'));
          }
          if (!controller.loaded.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = controller.products;
          if (products.isEmpty) {
            return const Center(child: Text('No products listed yet.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: ProductGridCard.gridDelegate,
            itemCount: products.length,
            itemBuilder: (context, index) => ProductGridCard(
              product: products[index],
              onTap: () => controller.openProduct(products[index]),
            ),
          );
        }),
      ),
    );
  }
}
