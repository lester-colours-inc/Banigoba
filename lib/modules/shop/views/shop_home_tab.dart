// The shop dashboard's Home tab: what needs doing now, then everything that
// happened in the shop, newest first.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/utils/stock_status.dart';
import 'package:banigoba/modules/shop/controllers/admin_products_controller.dart';
import 'package:banigoba/modules/shop/controllers/seller_orders_controller.dart';
import 'package:banigoba/modules/shop/controllers/shop_chat_inbox_controller.dart';
import 'package:banigoba/modules/shop/models/shop_activity.dart';
import 'package:banigoba/modules/shop/widgets/shop_pulse_strip.dart';
import 'package:banigoba/modules/shop/widgets/shop_timeline.dart';

/// How many restock chips the Home tab shows.
const int _restockShown = 12;

class ShopHomeTab extends StatelessWidget {
  const ShopHomeTab({
    super.key,
    required this.stock,
    required this.orders,
    required this.inbox,
    required this.onOpenOrders,
    required this.onOpenStock,
    required this.onOpenMessages,
  });

  final AdminProductsController stock;
  final SellerOrdersController orders;
  final ShopChatInboxController inbox;
  final VoidCallback onOpenOrders;
  final ValueChanged<StockLevel?> onOpenStock;
  final VoidCallback onOpenMessages;

  static String _greeting(DateTime now) => switch (now.hour) {
    < 12 => 'Good morning',
    < 17 => 'Good afternoon',
    _ => 'Good evening',
  };

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final products = stock.products.toList();
      final orderRows = orders.orders.toList();
      final chats = inbox.chats.toList();
      final pulse = shopPulse(
        orders: orderRows,
        chats: chats,
        stock: summarizeStock(products),
      );
      final restock = [
        ...filterByStock(products, StockLevel.soldOut),
        ...filterByStock(products, StockLevel.low),
      ].take(_restockShown).toList();
      final events = buildShopTimeline(
        orders: orderRows,
        chats: chats,
        products: products,
      );
      final now = DateTime.now();
      return ListView(
        padding: const EdgeInsets.only(top: 20, bottom: 40),
        children: [
          _Intro(greeting: _greeting(now), pulse: pulse),
          const SizedBox(height: 16),
          ShopPulseStrip(
            pulse: pulse,
            onOrders: onOpenOrders,
            onMessages: onOpenMessages,
            onStock: () => onOpenStock(null),
          ),
          if (restock.isNotEmpty) ...[
            const _SectionTitle(title: 'Needs restocking'),
            RestockRow(products: restock, onTap: onOpenStock),
          ],
          _SectionTitle(
            title: 'Activity',
            action: TextButton(
              onPressed: onOpenOrders,
              child: const Text('All orders'),
            ),
          ),
          if (!stock.loaded.value && !orders.loaded.value)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (events.isEmpty)
            const _EmptyTimeline()
          else
            ..._timeline(events, now),
        ],
      );
    });
  }

  List<Widget> _timeline(List<ShopActivity> events, DateTime now) {
    final widgets = <Widget>[];
    DateTime? day;
    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      final eventDay = activityDay(event.at);
      if (eventDay != day) {
        day = eventDay;
        widgets.add(TimelineDayHeader(label: dayLabel(eventDay, now)));
      }
      final next = i + 1 < events.length ? events[i + 1] : null;
      widgets.add(
        TimelineTile(
          key: ValueKey('activity_${event.kind.name}_${event.refId}_$i'),
          activity: event,
          isLast: next == null || activityDay(next.at) != eventDay,
          onTap: () => _open(event),
        ),
      );
    }
    return widgets;
  }

  void _open(ShopActivity event) {
    switch (event.kind) {
      case ShopActivityKind.orderPlaced:
      case ShopActivityKind.orderUpdated:
        onOpenOrders();
      case ShopActivityKind.message:
        inbox.open(chatId: event.refId, title: event.title, asSeller: true);
      case ShopActivityKind.listed:
        onOpenStock(null);
    }
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.greeting, required this.pulse});

  final String greeting;
  final ShopPulse pulse;

  String get _summary {
    if (pulse.newOrders > 0) {
      return '${pulse.newOrders} ${pulse.newOrders == 1 ? 'order is' : 'orders are'}'
          ' waiting for you to accept.';
    }
    if (pulse.unreadChats > 0) return 'Customers are waiting on a reply.';
    if (pulse.needsRestock > 0) return 'A few pieces are running out.';
    return 'All caught up. Here is how your shop is doing.';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            _summary,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, action == null ? 20 : 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Column(
        children: [
          Icon(Icons.timeline, size: 48, color: scheme.outline),
          const SizedBox(height: 12),
          const Text(
            'Your shop story starts here',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'New orders, customer messages and pieces you list '
            'will show up here as they happen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
