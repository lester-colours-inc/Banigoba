import 'package:banigoba/data/models/shop_link.dart';
import 'package:banigoba/ui/screens/shop/shop_link_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _p(String id, String category, {String name = ''}) => {
  'id': id,
  'name': name.isEmpty ? 'Piece $id' : name,
  'category': category,
  'imageUrl': 'https://img.example/$id.jpg',
};

final _products = [
  _p('a', 'outerwear', name: 'Wool coat'),
  _p('b', 'outerwear'),
  _p('c', 'tops'),
];

Future<void> _pump(
  WidgetTester tester, {
  required Future<void> Function(ShopLink draft) onSubmit,
}) {
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ShopLinkForm(
          ownerId: 'shop1',
          shopName: 'Glow Boutique',
          products: _products,
          onSubmit: onSubmit,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shares all stock by default with a ready title', (tester) async {
    ShopLink? draft;
    await _pump(tester, onSubmit: (link) async => draft = link);

    await tester.tap(find.byKey(const ValueKey('create_link')));
    await tester.pumpAndSettle();

    expect(draft?.scope, ShareScope.all);
    expect(draft?.title, 'All my stock');
    expect(draft?.ownerId, 'shop1');
    expect(draft?.shopName, 'Glow Boutique');
    expect(draft?.audience, ShareAudience.linkOnly);
    expect(draft?.coverImageUrl, 'https://img.example/a.jpg');
  });

  testWidgets('a category share offers the shop\'s own categories', (
    tester,
  ) async {
    ShopLink? draft;
    await _pump(tester, onSubmit: (link) async => draft = link);

    await tester.tap(find.byKey(const ValueKey('scope_category')));
    await tester.pump();
    expect(find.byKey(const ValueKey('category_outerwear')), findsOneWidget);
    expect(find.byKey(const ValueKey('category_tops')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('category_outerwear')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('create_link')));
    await tester.pumpAndSettle();

    expect(draft?.scope, ShareScope.category);
    expect(draft?.category, 'outerwear');
    expect(draft?.title, 'Outerwear');
  });

  testWidgets('picking pieces shares exactly those', (tester) async {
    ShopLink? draft;
    await _pump(tester, onSubmit: (link) async => draft = link);

    await tester.tap(find.byKey(const ValueKey('scope_items')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('pick_c')));
    await tester.tap(find.byKey(const ValueKey('pick_a')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('create_link')));
    await tester.pumpAndSettle();

    expect(draft?.scope, ShareScope.items);
    expect(draft?.productIds, ['c', 'a']);
    expect(draft?.title, '2 pieces');
    expect(draft?.coverImageUrl, 'https://img.example/c.jpg');
  });

  testWidgets('picking no pieces is refused, nothing sent', (tester) async {
    var sent = 0;
    await _pump(tester, onSubmit: (_) async => sent += 1);

    await tester.tap(find.byKey(const ValueKey('scope_items')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('create_link')));
    await tester.pump();

    expect(sent, 0);
    expect(find.text('Choose at least one piece.'), findsOneWidget);
  });

  testWidgets('the audience and own words are kept', (tester) async {
    ShopLink? draft;
    await _pump(tester, onSubmit: (link) async => draft = link);

    await tester.enterText(
      find.byKey(const ValueKey('link_title')),
      'Black Friday',
    );
    await tester.enterText(
      find.byKey(const ValueKey('link_note')),
      'Ends Sunday',
    );
    await tester.tap(find.byKey(const ValueKey('audience_public')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('create_link')));
    await tester.pumpAndSettle();

    expect(draft?.title, 'Black Friday');
    expect(draft?.note, 'Ends Sunday');
    expect(draft?.audience, ShareAudience.public);
  });

  testWidgets('says when creating failed and lets the shop try again', (
    tester,
  ) async {
    await _pump(tester, onSubmit: (_) async => throw Exception('offline'));

    await tester.tap(find.byKey(const ValueKey('create_link')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not create'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('create_link')))
          .onPressed,
      isNotNull,
    );
  });
}
