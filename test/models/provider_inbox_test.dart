import 'package:banigoba/modules/provider/models/provider_inbox.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t1 = DateTime(2026, 10, 1);
  final t2 = DateTime(2026, 10, 2);
  final t3 = DateTime(2026, 10, 3);

  group('InboxItem.fromOrder', () {
    test('summarises the order and its total', () {
      final item = InboxItem.fromOrder('abc123', {
        'orderNumber': '1042',
        'customerName': 'Zoe',
        'status': 'submitted',
        'total': 45.5,
        'items': [
          {'quantity': 2},
          {'quantity': 1},
        ],
      }, createdAt: t1);

      expect(item.kind, InboxKind.order);
      expect(item.title, 'Order #1042');
      expect(item.detail, '3 items · \$45.50');
      expect(item.customerName, 'Zoe');
      expect(item.needsAction, isTrue);
    });

    test('falls back to the start of the id for the order number', () {
      final item = InboxItem.fromOrder('abcdef999', {}, createdAt: t1);

      expect(item.title, 'Order #abcdef');
      expect(item.customerName, 'Customer');
    });

    test('says "1 item" for a single piece', () {
      final item = InboxItem.fromOrder('a', {
        'items': [
          {'quantity': 1},
        ],
        'total': 10,
      }, createdAt: t1);

      expect(item.detail, '1 item · \$10.00');
    });
  });

  group('delivery orders', () {
    test('mark an order that is to be delivered', () {
      final item = InboxItem.fromOrder('abc123', {
        'orderNumber': '1042',
        'status': 'submitted',
        'total': 43,
        'fulfilment': 'delivery',
        'deliveryArea': 'Avondale',
        'items': [
          {'quantity': 1},
        ],
      }, createdAt: t1);

      expect(item.detail, '1 item · \$43.00 · Delivery to Avondale');
    });

    test('a delivery with no area says just Delivery', () {
      final item = InboxItem.fromOrder('a', {
        'fulfilment': 'delivery',
        'total': 10,
        'items': [
          {'quantity': 1},
        ],
      }, createdAt: t1);

      expect(item.detail, '1 item · \$10.00 · Delivery');
    });

    test(
      'an order with no fulfilment is a collection and says nothing extra',
      () {
        final item = InboxItem.fromOrder('a', {
          'total': 10,
          'items': [
            {'quantity': 1},
          ],
        }, createdAt: t1);

        expect(item.detail, '1 item · \$10.00');
      },
    );

    test('the delivery steps read in plain words', () {
      String label(String status) => InboxItem.fromOrder('x', {
        'status': status,
      }, createdAt: t1).statusLabel;

      expect(label('out_for_delivery'), 'Out for delivery');
      expect(label('delivered'), 'Delivered');
    });
  });

  group('requests', () {
    test('a design request shows the occasion, budget and deadline', () {
      final item = InboxItem.fromDesignRequest('d1', {
        'customerName': 'Zoe',
        'occasion': 'Wedding',
        'budget': '\$200',
        'deadline': '12 Dec',
        'status': 'pending',
      }, createdAt: t1);

      expect(item.kind, InboxKind.design);
      expect(item.title, 'Wedding');
      expect(item.detail, 'Budget \$200 · by 12 Dec');
      expect(item.needsAction, isTrue);
    });

    test('a design request with no details still has a title', () {
      final item = InboxItem.fromDesignRequest('d1', {}, createdAt: t1);

      expect(item.title, 'Custom design');
      expect(item.detail, '');
    });

    test('a hair request shows the service, date and budget', () {
      final item = InboxItem.fromAgentRequest('a1', {
        'service': 'Knotless braids',
        'preferredDate': 'Sat 7 Nov',
        'budget': '\$40',
        'status': 'accepted',
      }, createdAt: t1);

      expect(item.kind, InboxKind.hair);
      expect(item.title, 'Knotless braids');
      expect(item.detail, 'Sat 7 Nov · Budget \$40');
      expect(item.needsAction, isFalse);
    });
  });

  group('status labels', () {
    test('use plain words', () {
      String label(String status) => InboxItem.fromDesignRequest('x', {
        'status': status,
      }, createdAt: t1).statusLabel;

      expect(label('pending'), 'New');
      expect(label('accepted'), 'Accepted');
      expect(label('declined'), 'Declined');
      expect(label('completed'), 'Completed');
      expect(label('ready_for_collection'), 'Ready for collection');
    });
  });

  group('mergeInbox', () {
    InboxItem item(String id, DateTime? at, String status) =>
        InboxItem.fromDesignRequest(id, {'status': status}, createdAt: at);

    test('puts items that need an answer first, then newest first', () {
      final merged = mergeInbox([
        [item('old-open', t1, 'pending'), item('done', t3, 'completed')],
        [item('new-open', t2, 'pending')],
      ]);

      expect(merged.map((i) => i.id), ['new-open', 'old-open', 'done']);
    });

    test('keeps only one kind when asked', () {
      final merged = mergeInbox([
        [item('d', t1, 'pending')],
        [InboxItem.fromAgentRequest('a', {}, createdAt: t2)],
      ], only: InboxKind.hair);

      expect(merged.map((i) => i.id), ['a']);
    });

    test('puts items with no date last', () {
      final merged = mergeInbox([
        [item('undated', null, 'completed'), item('dated', t1, 'completed')],
      ]);

      expect(merged.map((i) => i.id), ['dated', 'undated']);
    });
  });

  test('openCount counts what needs an answer', () {
    final items = [
      InboxItem.fromDesignRequest('a', {'status': 'pending'}, createdAt: t1),
      InboxItem.fromDesignRequest('b', {'status': 'accepted'}, createdAt: t1),
      InboxItem.fromOrder('c', {'status': 'submitted'}, createdAt: t1),
    ];

    expect(openCount(items), 2);
  });
}
