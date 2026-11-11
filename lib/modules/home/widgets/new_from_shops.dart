// "New from shops you follow": up to three pieces a day from the shops and
// designers the person follows, in their size and suiting their style (review
// items D-4 and A-6). Shows nothing at all when nothing matches, so the feed
// never fills with filler.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/home/controllers/new_from_shops_controller.dart';
import 'package:banigoba/modules/home/services/feed_matches_service.dart';
import 'package:banigoba/modules/shop/widgets/shop_match_card.dart';

class NewFromShops extends StatelessWidget {
  const NewFromShops({super.key, required this.userId, this.service});

  final String userId;

  /// Injected in tests.
  final FeedSource? service;

  @override
  Widget build(BuildContext context) {
    // Scoped to this widget: created and disposed with it.
    return GetBuilder<NewFromShopsController>(
      init: NewFromShopsController(userId: userId, service: service),
      global: false,
      builder: (controller) => FutureBuilder<List<FeedItem>>(
        future: controller.items,
        builder: (context, snapshot) => Obx(() {
          final hidden = controller.dismissed.toSet();
          final items = [
            for (final item in snapshot.data ?? const <FeedItem>[])
              if (!hidden.contains(item.match.productId)) item,
          ];
          if (items.isEmpty) return const SizedBox.shrink();
          final colors = Theme.of(context).colorScheme;
          return Padding(
            key: const ValueKey('new_from_shops'),
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New from shops you follow',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                Text(
                  'In your size, picked for your style.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 330,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => ShopMatchCard(
                      product: items[index].product,
                      match: items[index].match,
                      onOpen: () => controller.open(items[index]),
                      onDismiss: () => controller.dismiss(items[index]),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
