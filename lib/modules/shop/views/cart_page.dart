// Cart screen for boutique purchases.
//
// Responsibilities:
// - show the signed-in user's cart in real time,
// - display the selected size for sized boutique products,
// - let the user change quantities or remove lines,
// - collect the final collection details before creating an order.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/cart_controller.dart';
import 'package:banigoba/modules/shop/widgets/cart_line_tile.dart';
import 'package:banigoba/modules/shop/widgets/checkout_sheet.dart';

class CartPage extends GetView<CartController> {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: controller.userId == null
          ? const Center(child: Text('Sign in to use your cart.'))
          : Obx(() {
              if (!controller.loaded.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = controller.items;
              if (items.isEmpty) {
                return const Center(child: Text('Your cart is empty.'));
              }
              final total = controller.total;
              return Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final line = items[index];
                        return CartLineTile(
                          line: line,
                          price: controller.priceFor(line),
                          onQuantity: (quantity) => controller.setQuantity(
                            line['id'].toString(),
                            quantity,
                          ),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Items: \$${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          FilledButton(
                            onPressed: () => showCheckoutSheet(
                              context,
                              userId: controller.userId!,
                              total: total,
                              sellerId: controller.sellerId,
                            ),
                            child: const Text('Checkout'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
    );
  }
}
