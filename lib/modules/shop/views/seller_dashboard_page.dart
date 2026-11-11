// The shop screen inside provider mode, for boutique owners.
//
// Boutique owners use this screen to maintain storefront details, manage their
// products, review orders, and open customer conversations. Storefront edits
// intentionally preserve admin verification fields.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/seller_dashboard_controller.dart';
import 'package:banigoba/modules/shop/views/admin_products_page.dart';
import 'package:banigoba/modules/shop/views/seller_orders_page.dart';
import 'package:banigoba/modules/shop/views/shop_chat_page.dart';
import 'package:banigoba/modules/shop/widgets/delivery_settings_card.dart';
import 'package:banigoba/modules/shop/widgets/seller_nav_card.dart';

class SellerDashboardPage extends StatelessWidget {
  const SellerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scoped to this screen: created and disposed with the widget.
    return GetBuilder<SellerDashboardController>(
      init: SellerDashboardController(),
      global: false,
      builder: (controller) => _SellerDashboardView(controller: controller),
    );
  }
}

class _SellerDashboardView extends StatelessWidget {
  const _SellerDashboardView({required this.controller});

  static const _primary = Color(0xFF0D0140);

  final SellerDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shop'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(
        () => controller.loading.value
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Manage Your Boutique',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Update your storefront and manage the products customers can shop.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller.shopName,
                    decoration: const InputDecoration(
                      labelText: 'Shop or boutique name',
                      prefixIcon: Icon(Icons.storefront),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller.description,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Boutique description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller.contact,
                    decoration: const InputDecoration(
                      labelText: 'Customer contact',
                      prefixIcon: Icon(Icons.alternate_email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: controller.saving.value
                        ? null
                        : controller.saveShop,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: Text(
                      controller.saving.value ? 'Saving...' : 'Save Boutique',
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Delivery',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DeliverySettingsCard(
                    initial: controller.delivery.value,
                    onSave: controller.saveDelivery,
                  ),
                  const SizedBox(height: 20),
                  SellerNavCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'Products & Inventory',
                    subtitle:
                        'Add products, update prices and stock, or remove listings.',
                    onTap: () => Get.to<void>(() => const AdminProductsPage()),
                  ),
                  const SizedBox(height: 12),
                  SellerNavCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Orders',
                    subtitle:
                        'Review collection orders and update customer status.',
                    onTap: () => Get.to<void>(() => const SellerOrdersPage()),
                  ),
                  const SizedBox(height: 12),
                  SellerNavCard(
                    icon: Icons.chat_bubble_outline,
                    title: 'Messages',
                    subtitle: 'Answer product questions and help customers.',
                    onTap: () => Get.to<void>(
                      () => const ShopChatInboxPage(sellerOnly: true),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
