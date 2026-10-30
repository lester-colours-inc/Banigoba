import 'package:banigoba/data/models/shop_link.dart';
import 'package:banigoba/ui/widgets/shop_drops_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _drop = ShopLink(
  id: 'L1',
  ownerId: 'shop1',
  shopName: 'Glow Boutique',
  title: 'Winter coats',
  scope: ShareScope.all,
  audience: ShareAudience.public,
);

Future<void> _pump(
  WidgetTester tester,
  Future<List<ShopLink>> Function() load, {
  ValueChanged<ShopLink>? onOpen,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ShopDropsStrip(load: load, onOpen: onOpen),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows public shop links with the shop and title', (
    tester,
  ) async {
    await _pump(tester, () async => [_drop]);

    expect(find.text('From the shops'), findsOneWidget);
    expect(find.text('Glow Boutique'), findsOneWidget);
    expect(find.text('Winter coats'), findsOneWidget);
  });

  testWidgets('opens the link that is tapped', (tester) async {
    ShopLink? opened;
    await _pump(tester, () async => [_drop], onOpen: (link) => opened = link);

    await tester.tap(find.byKey(const ValueKey('drop_L1')));

    expect(opened?.id, 'L1');
  });

  testWidgets('is hidden when there are none, or they cannot load', (
    tester,
  ) async {
    await _pump(tester, () async => const []);
    expect(find.byKey(const ValueKey('shop_drops')), findsNothing);

    await _pump(tester, () async => throw Exception('offline'));
    expect(find.byKey(const ValueKey('shop_drops')), findsNothing);
  });
}
