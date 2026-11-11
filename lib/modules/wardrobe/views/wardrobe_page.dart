// Manages the signed-in user's wardrobe, uploads, filters, and product actions.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/services/product_service.dart';
import 'package:banigoba/modules/wardrobe/controllers/wardrobe_controller.dart';
import 'package:banigoba/modules/wardrobe/widgets/saved_looks_grid.dart';
import 'package:banigoba/modules/wardrobe/widgets/upload_item_sheet.dart';
import 'package:banigoba/modules/wardrobe/widgets/wardrobe_chrome.dart';
import 'package:banigoba/modules/wardrobe/widgets/wardrobe_clothes_tab.dart';
import 'package:banigoba/modules/wardrobe/widgets/wardrobe_connections.dart';
import 'package:banigoba/shared/widgets/menu_or_back_button.dart';

export 'package:banigoba/modules/wardrobe/controllers/wardrobe_controller.dart'
    show WardrobeTab;

/// My Smart Wardrobe: the user's clothes, the looks they saved, and the
/// shops and designers the wardrobe draws on (October 2026 review, W-1).
class WardrobePage extends StatelessWidget {
  const WardrobePage({super.key, this.initialTab = WardrobeTab.clothes});

  final WardrobeTab initialTab;

  static Color primaryColor = wardrobePrimary;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: built from its parameters, disposed with it.
    return GetBuilder<WardrobeController>(
      init: WardrobeController(
        initialTab: initialTab,
        productService: ProductService(),
      ),
      global: false,
      builder: (controller) => _WardrobeView(controller: controller),
    );
  }
}

class _WardrobeView extends StatelessWidget {
  const _WardrobeView({required this.controller});

  final WardrobeController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: const MenuOrBackButton(),
        actions: [
          WardrobeCartAction(controller: controller),
          WardrobeNotificationsAction(controller: controller),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page heading (G-1). Back/menu lives in the app bar.
                Text(
                  'My Smart Wardrobe',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 25),
                WardrobeTabBar(controller: controller),
                const SizedBox(height: 25),
                Expanded(
                  child: Obx(() {
                    return switch (controller.selectedTab.value) {
                      1 => SavedLooksGrid(userId: controller.userId),
                      2 => WardrobeConnections(userId: controller.userId),
                      _ => WardrobeClothesTab(controller: controller),
                    };
                  }),
                ),
              ],
            ),
          ),
          // Floating Action Button for adding new items (visible in "Mine" tab)
          Obx(
            () => controller.selectedTab.value == 0
                ? Positioned(
                    bottom: 30,
                    right: 25,
                    child: AddItemButton(
                      onTap: () =>
                          showUploadItemSheet(userId: controller.userId),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
