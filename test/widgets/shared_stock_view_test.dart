import 'package:banigoba/modules/shop/models/shop_link.dart';
import 'package:banigoba/modules/shop/views/shared_stock_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _link = ShopLink(
  id: 'L1',
  ownerId: 'shop1',
  shopName: 'Glow Boutique',
  title: 'Winter coats',
  note: 'Sizes S to XL',
  scope: ShareScope.category,
  category: 'outerwear',
  audience: ShareAudience.public,
);

Map<String, dynamic> _piece(String id, {num stock = 3, num price = 40}) => {
  'id': id,
  'name': 'Coat $id',
  'price': price,
  'stock': stock,
  'imageUrl': '',
  'category': 'outerwear',
};

Future<void> _pump(
  WidgetTester tester, {
  ShopLink? link = _link,
  List<Map<String, dynamic>> pieces = const [],
  bool signedIn = true,
  ValueChanged<Map<String, dynamic>>? onTryOn,
  ValueChanged<Map<String, dynamic>>? onBuy,
  VoidCallback? onSignIn,
}) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SharedStockView(
          link: link,
          pieces: pieces,
          signedIn: signedIn,
          onTryOn: onTryOn ?? (_) {},
          onBuy: onBuy ?? (_) {},
          onSignIn: onSignIn ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the shop, the title, the note and the pieces', (
    tester,
  ) async {
    await _pump(tester, pieces: [_piece('a'), _piece('b', price: 55.5)]);

    expect(find.text('Glow Boutique'), findsOneWidget);
    expect(find.text('Winter coats'), findsOneWidget);
    expect(find.text('Sizes S to XL'), findsOneWidget);
    expect(find.text('Coat a'), findsOneWidget);
    expect(find.text('\$55.50'), findsOneWidget);
  });

  testWidgets('each piece can be tried on or bought', (tester) async {
    Map<String, dynamic>? tried;
    Map<String, dynamic>? bought;
    await _pump(
      tester,
      pieces: [_piece('a')],
      onTryOn: (piece) => tried = piece,
      onBuy: (piece) => bought = piece,
    );

    await tester.tap(find.byKey(const ValueKey('try_on_a')));
    await tester.tap(find.byKey(const ValueKey('buy_a')));

    expect(tried?['id'], 'a');
    expect(bought?['id'], 'a');
  });

  testWidgets('a sold-out piece says so and cannot be bought', (tester) async {
    await _pump(tester, pieces: [_piece('a', stock: 0)]);

    expect(find.text('Sold out'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('buy_a')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('signed out, it asks to sign in instead of trying on or buying', (
    tester,
  ) async {
    var asked = 0;
    Map<String, dynamic>? tried;
    await _pump(
      tester,
      pieces: [_piece('a')],
      signedIn: false,
      onSignIn: () => asked += 1,
      onTryOn: (piece) => tried = piece,
    );

    expect(find.byKey(const ValueKey('sign_in_banner')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('try_on_a')));
    await tester.tap(find.byKey(const ValueKey('sign_in_button')));

    expect(asked, 2);
    expect(tried, isNull);
  });

  testWidgets('a missing or switched-off link says it is gone', (tester) async {
    await _pump(tester, link: null);
    expect(find.textContaining('no longer available'), findsOneWidget);

    await _pump(
      tester,
      link: const ShopLink(
        id: 'L2',
        ownerId: 's',
        shopName: 'Glow',
        title: 'Old',
        scope: ShareScope.all,
        audience: ShareAudience.linkOnly,
        active: false,
      ),
      pieces: [_piece('a')],
    );
    expect(find.textContaining('no longer available'), findsOneWidget);
    expect(find.text('Coat a'), findsNothing);
  });

  testWidgets('says so when nothing is in the link any more', (tester) async {
    await _pump(tester, pieces: const []);

    expect(find.textContaining('Nothing here right now'), findsOneWidget);
  });
}
