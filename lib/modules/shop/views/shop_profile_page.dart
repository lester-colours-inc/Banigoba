// The shop's profile: storefront details and delivery, opened from the shop
// dashboard's header. Edits keep the admin verification fields intact.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/seller_dashboard_controller.dart';
import 'package:banigoba/modules/shop/widgets/delivery_settings_card.dart';

class ShopProfilePage extends StatelessWidget {
  const ShopProfilePage({super.key, required this.controller});

  static const _primary = Color(0xFF0D0140);

  final SellerDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop profile'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(
        () => controller.loading.value
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  Text(
                    'How customers see you',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your name, story and contact on the storefront.',
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 32),
                  Text(
                    'Delivery',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DeliverySettingsCard(
                    initial: controller.delivery.value,
                    onSave: controller.saveDelivery,
                  ),
                ],
              ),
      ),
    );
  }
}
