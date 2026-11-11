import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/seller_orders_controller.dart';
import 'package:banigoba/modules/shop/widgets/seller_order_card.dart';

class SellerOrdersPage extends StatelessWidget {
  const SellerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scoped to this screen: created and disposed with the widget.
    return GetBuilder<SellerOrdersController>(
      init: SellerOrdersController(),
      global: false,
      builder: (controller) => _SellerOrdersView(controller: controller),
    );
  }
}

class _SellerOrdersView extends StatelessWidget {
  const _SellerOrdersView({required this.controller});

  static const _primary = Color(0xFF0D0140);

  final SellerOrdersController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: controller.sellerId.isEmpty
          ? const Center(child: Text('Sign in to view orders.'))
          : Obx(() {
              if (controller.failed.value) {
                return const Center(child: Text('Unable to load orders.'));
              }
              if (!controller.loaded.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final orders = controller.orders;
              if (orders.isEmpty) {
                return const Center(child: Text('No orders yet.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Obx(
                    () => SellerOrderCard(
                      controller: controller,
                      orderId: order['id'].toString(),
                      order: order,
                    ),
                  );
                },
              );
            }),
    );
  }
}
