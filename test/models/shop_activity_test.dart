import 'package:flutter_test/flutter_test.dart';

import 'package:banigoba/core/utils/stock_status.dart';
import 'package:banigoba/modules/shop/models/shop_activity.dart';

void main() {
  final order = {
    'id': 'o1',
    'orderNumber': 'A12',
    'customerName': 'Rudo',
    'total': 40,
    'status': 'accepted',
    'createdAt': '2026-11-12T09:00:00Z',
    'statusHistory': [
      {'status': 'submitted', 'updatedAt': '2026-11-12T09:00:00Z'},
      {'status': 'accepted', 'updatedAt': '2026-11-12T10:00:00Z'},
    ],
  };
  final chat = {
    'id': 'c1',
    'customerName': 'Tino',
    'lastMessage': 'Is the red dress in M?',
    'lastMessageAt': '2026-11-13T08:00:00Z',
    'unreadBySeller': 2,
  };
  final product = {
    'id': 'p1',
    'name': 'Red dress',
    'price': 25,
    'stock': 3,
    'createdAt': '2026-11-11T12:00:00Z',
  };

  group('buildShopTimeline', () {
    test(
      'merges orders, status changes, messages and listings newest first',
      () {
        final events = buildShopTimeline(
          orders: [order],
          chats: [chat],
          products: [product],
        );

        expect(events.map((e) => e.kind), [
          ShopActivityKind.message,
          ShopActivityKind.orderUpdated,
          ShopActivityKind.orderPlaced,
          ShopActivityKind.listed,
        ]);
        expect(events.first.highlight, isTrue);
        expect(events[1].title, 'Order #A12 · Accepted by boutique');
        expect(events[2].title, 'New order from Rudo');
        expect(events[2].detail, 'Order #A12 · \$40.00');
        expect(events[2].highlight, isFalse);
        expect(events[3].detail, '\$25.00 · 3 in stock');
      },
    );

    test('skips the submitted history entry so a new order shows once', () {
      final events = buildShopTimeline(
        orders: [
          {
            ...order,
            'status': 'submitted',
            'statusHistory': [
              {'status': 'submitted', 'updatedAt': '2026-11-12T09:00:00Z'},
            ],
          },
        ],
        chats: const [],
        products: const [],
      );

      expect(events, hasLength(1));
      expect(events.single.highlight, isTrue);
    });

    test('drops rows without a time and empty conversations', () {
      final events = buildShopTimeline(
        orders: [
          {'id': 'o2'},
        ],
        chats: [
          {...chat, 'lastMessage': ''},
        ],
        products: [
          {'id': 'p2', 'name': 'No date'},
        ],
      );

      expect(events, isEmpty);
    });

    test('caps the timeline at the limit', () {
      final many = [
        for (var i = 0; i < 10; i++)
          {
            ...product,
            'id': 'p$i',
            'createdAt': '2026-11-0${i % 9 + 1}T00:00Z',
          },
      ];

      expect(
        buildShopTimeline(
          orders: const [],
          chats: const [],
          products: many,
          limit: 4,
        ),
        hasLength(4),
      );
    });
  });

  test('shopPulse counts new and open orders, unread chats and restocks', () {
    final pulse = shopPulse(
      orders: [
        {'status': 'submitted'},
        {'status': 'accepted'},
        {'status': 'delivered'},
      ],
      chats: [
        chat,
        {...chat, 'unreadBySeller': 0},
      ],
      stock: const StockSummary(total: 5, soldOut: 1, low: 2),
    );

    expect(pulse.newOrders, 1);
    expect(pulse.openOrders, 2);
    expect(pulse.unreadChats, 1);
    expect(pulse.needsRestock, 3);
  });
}
