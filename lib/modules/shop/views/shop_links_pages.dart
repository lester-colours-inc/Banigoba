// The shop's side of "Share my stock" (K-9): its links, making a new one,
// and sending one.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/create_shop_link_controller.dart';
import 'package:banigoba/modules/shop/controllers/share_shop_link_controller.dart';
import 'package:banigoba/modules/shop/controllers/shop_links_controller.dart';
import 'package:banigoba/modules/shop/models/shop_link.dart';
import 'package:banigoba/modules/shop/views/share_shop_link_panel.dart';
import 'package:banigoba/modules/shop/views/shared_stock_page.dart';
import 'package:banigoba/modules/shop/views/shop_link_form.dart';

/// "Share my stock": the shop's links, each can be sent again or switched
/// off, and a button for a new one.
class ShopLinksPage extends StatelessWidget {
  const ShopLinksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ShopLinksController>(
      init: ShopLinksController(),
      global: false,
      builder: (controller) {
        final colors = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(title: const Text('Share my stock')),
          floatingActionButton: FloatingActionButton.extended(
            key: const ValueKey('new_shop_link'),
            onPressed: controller.newLink,
            icon: const Icon(Icons.add_link),
            label: const Text('New link'),
          ),
          body: Obx(() {
            if (controller.failed.value) {
              return const Center(
                child: Text('Your links could not be loaded.'),
              );
            }
            final links = controller.links.value;
            if (links == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (links.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Share all your stock, a category or a few pieces as a link '
                    'or QR code: people can try them on and buy. Tap "New link".',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: links.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final link = links[index];
                return Card(
                  child: ListTile(
                    key: ValueKey('my_link_${link.id}'),
                    title: Text(
                      link.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${link.scopeLabel} · ${link.audience.label}'
                      '${link.active ? '' : ' · switched off'}',
                    ),
                    onTap: () => controller.open(link),
                    trailing: Switch(
                      value: link.active,
                      onChanged: (on) => controller.setActive(link, on: on),
                    ),
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }
}

/// Making a new link from the shop's own pieces.
class CreateShopLinkPage extends StatelessWidget {
  const CreateShopLinkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CreateShopLinkController>(
      init: CreateShopLinkController(),
      global: false,
      builder: (controller) => Scaffold(
        appBar: AppBar(title: const Text('New link')),
        body: Obx(() {
          if (controller.failed.value) {
            return const Center(child: Text('Your stock could not be loaded.'));
          }
          final data = controller.data.value;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.$2.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Add pieces in Products & Inventory first, then share them.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ShopLinkForm(
            ownerId: controller.userId,
            shopName: data.$1,
            products: data.$2,
            onSubmit: controller.create,
          );
        }),
      ),
    );
  }
}

/// Sending a link: QR, WhatsApp, other apps, copy.
class ShareShopLinkPage extends StatelessWidget {
  const ShareShopLinkPage({super.key, required this.link});

  final ShopLink link;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ShareShopLinkController>(
      init: ShareShopLinkController(link),
      global: false,
      builder: (controller) => Scaffold(
        appBar: AppBar(
          title: const Text('Send your link'),
          actions: [
            IconButton(
              tooltip: 'See it as a buyer',
              icon: const Icon(Icons.visibility_outlined),
              onPressed: () =>
                  Get.to<void>(() => SharedStockPage(linkId: link.id)),
            ),
          ],
        ),
        body: ShareShopLinkPanel(
          link: link,
          onWhatsApp: controller.whatsApp,
          onShareMore: controller.more,
          onShareQr: controller.qr,
          onCopy: controller.copy,
        ),
      ),
    );
  }
}
