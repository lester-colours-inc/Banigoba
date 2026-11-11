// The chat's app-bar title: the shop (or designer) name, tappable for buyers.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/shop/controllers/shop_chat_controller.dart';

class ChatTitle extends StatelessWidget {
  const ChatTitle({super.key, required this.controller});

  final ShopChatController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c.asSeller) return Text(c.title);

    final data = c.chat.value;
    final conversationType = (data?['conversationType'] ?? 'shop').toString();
    if (conversationType == 'designer') {
      final designerId = (data?['designerId'] ?? data?['sellerId'] ?? '')
          .toString();
      final designerName = (data?['designerName'] ?? c.title).toString();
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: designerId.isEmpty ? null : () => c.openDesigner(designerId),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(designerName, overflow: TextOverflow.ellipsis),
            ),
            if (designerId.isNotEmpty) ...[
              const SizedBox(width: 6),
              const Icon(Icons.design_services_outlined, size: 18),
            ],
          ],
        ),
      );
    }
    final sellerId = (data?['sellerId'] ?? '').toString();
    final shopName = (data?['shopName'] ?? c.title).toString();
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: sellerId.isEmpty ? null : () => c.openShop(sellerId, shopName),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(shopName, overflow: TextOverflow.ellipsis)),
          if (sellerId.isNotEmpty) ...[
            const SizedBox(width: 6),
            const Icon(Icons.storefront_outlined, size: 18),
          ],
        ],
      ),
    );
  }
}
