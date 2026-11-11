import 'package:banigoba/modules/provider/models/provider_inbox.dart';
import 'package:banigoba/modules/provider/views/provider_inbox_view.dart';
import 'package:banigoba/modules/provider/views/request_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final _day1 = DateTime(2026, 10, 1);
final _day2 = DateTime(2026, 10, 2);

List<InboxItem> _items() => [
  InboxItem.fromOrder('o1', {
    'orderNumber': '7',
    'customerName': 'Zoe',
    'status': 'collected',
    'total': 20,
    'items': [
      {'quantity': 1},
    ],
  }, createdAt: _day2),
  InboxItem.fromDesignRequest('d1', {
    'customerName': 'Rudo',
    'occasion': 'Wedding',
    'status': 'pending',
  }, createdAt: _day1),
  InboxItem.fromAgentRequest('a1', {
    'customerName': 'Farai',
    'service': 'Braids',
    'status': 'accepted',
  }, createdAt: _day2),
];

Future<void> _pumpView(
  WidgetTester tester,
  List<InboxItem> items, {
  ValueChanged<InboxItem>? onOpen,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProviderInboxView(items: items, onOpen: onOpen ?? (_) {}),
      ),
    ),
  );
}

void main() {
  tearDown(Get.reset);

  group('ProviderInboxView', () {
    testWidgets('lists every order and request, new ones first', (
      tester,
    ) async {
      await _pumpView(tester, _items());

      final top = tester.getTopLeft(
        find.byKey(const ValueKey('inbox_design_d1')),
      );
      final other = tester.getTopLeft(
        find.byKey(const ValueKey('inbox_order_o1')),
      );
      expect(top.dy, lessThan(other.dy));
      expect(find.text('Wedding'), findsOneWidget);
      expect(find.text('Braids'), findsOneWidget);
      expect(find.text('Order #7'), findsOneWidget);
    });

    testWidgets('filters to one kind', (tester) async {
      await _pumpView(tester, _items());

      await tester.tap(find.byKey(const ValueKey('filter_Hair')));
      await tester.pump();

      expect(find.text('Braids'), findsOneWidget);
      expect(find.text('Wedding'), findsNothing);
      expect(find.text('Order #7'), findsNothing);
    });

    testWidgets('has no filter row when there is only one kind', (
      tester,
    ) async {
      await _pumpView(tester, [_items().first]);

      expect(find.byKey(const ValueKey('filter_All')), findsNothing);
    });

    testWidgets('explains an empty inbox', (tester) async {
      await _pumpView(tester, const []);

      expect(find.textContaining('Nothing yet'), findsOneWidget);
    });

    testWidgets('opens the tapped item', (tester) async {
      InboxItem? opened;
      await _pumpView(tester, _items(), onOpen: (item) => opened = item);

      await tester.tap(find.text('Wedding'));

      expect(opened?.id, 'd1');
    });
  });

  group('RequestDetailSheet', () {
    Future<void> pumpSheet(
      WidgetTester tester,
      InboxItem item,
      RespondToRequest onRespond,
    ) {
      return tester.pumpWidget(
        // GetMaterialApp: answering closes the sheet with Get.back().
        GetMaterialApp(
          home: Scaffold(
            body: RequestDetailSheet(item: item, onRespond: onRespond),
          ),
        ),
      );
    }

    testWidgets('a new request can be accepted or declined', (tester) async {
      String? answer;
      await pumpSheet(tester, _items()[1], (status) async => answer = status);

      expect(find.byKey(const ValueKey('accept')), findsOneWidget);
      expect(find.byKey(const ValueKey('decline')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('accept')));
      await tester.pump();

      expect(answer, 'accepted');
    });

    testWidgets('an accepted request can be marked completed', (tester) async {
      String? answer;
      await pumpSheet(tester, _items()[2], (status) async => answer = status);

      expect(find.byKey(const ValueKey('accept')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('complete')));
      await tester.pump();

      expect(answer, 'completed');
    });

    testWidgets('a finished request offers no answer', (tester) async {
      final done = InboxItem.fromDesignRequest('d9', {
        'status': 'completed',
      }, createdAt: _day1);
      await pumpSheet(tester, done, (_) async {});

      expect(find.byKey(const ValueKey('accept')), findsNothing);
      expect(find.byKey(const ValueKey('complete')), findsNothing);
    });

    testWidgets('shows what the customer asked for', (tester) async {
      final item = InboxItem.fromDesignRequest('d2', {
        'occasion': 'Gala',
        'budget': '\$300',
        'notes': 'Deep green, no sleeves',
        'status': 'pending',
      }, createdAt: _day1);
      await pumpSheet(tester, item, (_) async {});

      expect(find.text('Deep green, no sleeves'), findsOneWidget);
      expect(find.text('\$300'), findsOneWidget);
    });

    testWidgets('shows the error when saving fails', (tester) async {
      await pumpSheet(
        tester,
        _items()[1],
        (_) async => throw Exception('offline'),
      );

      await tester.tap(find.byKey(const ValueKey('accept')));
      await tester.pump();

      expect(find.textContaining('Could not save'), findsOneWidget);
    });
  });
}
