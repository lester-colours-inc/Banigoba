// Opens a shop's shared link (K-9) from a web address, a QR code, a
// notification or the Community strip.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/shared_stock_controller.dart';
import 'package:banigoba/modules/shop/services/shop_link_service.dart';
import 'package:banigoba/modules/shop/views/shared_stock_view.dart';

class SharedStockPage extends StatelessWidget {
  const SharedStockPage({super.key, required this.linkId, this.source});

  final String linkId;
  final ShopLinkSource? source;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: it is built with the link's id from the address.
    return GetBuilder<SharedStockController>(
      init: SharedStockController(linkId: linkId, source: source),
      global: false,
      builder: (controller) => Scaffold(
        appBar: AppBar(title: const Text('Shop')),
        body: Obx(() {
          if (controller.failed.value) {
            return const Center(child: Text('This link could not be opened.'));
          }
          final data = controller.data.value;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SharedStockView(
            link: data.$1,
            pieces: data.$2,
            signedIn: controller.signedIn,
            onTryOn: controller.tryOn,
            onBuy: controller.buy,
            onSignIn: controller.signIn,
          );
        }),
      ),
    );
  }
}
