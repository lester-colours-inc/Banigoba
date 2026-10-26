// Verifies the "New from shops you follow" cards in My Daily Dress Up.
import 'package:banigoba/data/models/feed_matching.dart';
import 'package:banigoba/data/services/feed_matches_service.dart';
import 'package:banigoba/ui/screens/main/widgets/new_from_shops.dart';
import 'package:banigoba/ui/widgets/shop_match_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFeed implements FeedSource {
  _FakeFeed(this.items);

  final List<FeedItem> items;
  final List<String> dismissed = [];
  int loads = 0;

  @override
  Future<List<FeedItem>> loadToday(String userId) async {
    loads++;
    return items;
  }

  @override
  Future<void> dismiss(String userId, String productId) async =>
      dismissed.add(productId);
}

FeedItem _item(String id, {String shop = 'Glow Boutique', double? price}) =>
    FeedItem(
      product: {
        'id': id,
        'name': 'Linen shirt $id',
        'shopName': shop,
        'price': ?price,
      },
      match: FeedMatch(
        productId: id,
        score: 5,
        reasons: const ['In your size (M)', 'Suits your Smart style'],
        size: 'M',
      ),
    );

Future<void> _pump(WidgetTester tester, FeedSource feed) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: NewFromShops(userId: 'me', service: feed),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows each match with the shop, price and reasons', (
    tester,
  ) async {
    await _pump(tester, _FakeFeed([_item('a', price: 24.5), _item('b')]));

    expect(find.text('New from shops you follow'), findsOneWidget);
    expect(find.byType(ShopMatchCard), findsNWidgets(2));
    expect(find.text('New from Glow Boutique'), findsNWidgets(2));
    expect(find.text('\$24.50'), findsOneWidget);
    expect(
      find.text('In your size (M). Suits your Smart style'),
      findsNWidgets(2),
    );
  });

  testWidgets('shows nothing when nothing matches', (tester) async {
    await _pump(tester, _FakeFeed(const []));

    expect(find.byKey(const ValueKey('new_from_shops')), findsNothing);
    expect(find.text('New from shops you follow'), findsNothing);
  });

  testWidgets('"Not for me" hides the piece and remembers it', (tester) async {
    final feed = _FakeFeed([_item('a'), _item('b')]);
    await _pump(tester, feed);

    await tester.tap(find.byKey(const ValueKey('shop_match_dismiss_a')));
    await tester.pump();

    expect(find.byType(ShopMatchCard), findsOneWidget);
    expect(find.byKey(const ValueKey('shop_match_a')), findsNothing);
    expect(feed.dismissed, ['a']);
  });

  testWidgets('dismissing the last piece removes the whole section', (
    tester,
  ) async {
    await _pump(tester, _FakeFeed([_item('a')]));

    await tester.tap(find.byKey(const ValueKey('shop_match_dismiss_a')));
    await tester.pump();

    expect(find.text('New from shops you follow'), findsNothing);
  });

  testWidgets('loads once, not on every rebuild', (tester) async {
    final feed = _FakeFeed([_item('a')]);
    await _pump(tester, feed);
    await tester.pump();
    await tester.pump();

    expect(feed.loads, 1);
  });

  group('helpers', () {
    test('batchesOf splits followed shops for Firestore\'s whereIn limit', () {
      final batches = batchesOf(List.generate(65, (i) => 'shop$i'));
      expect(batches.map((b) => b.length), [30, 30, 5]);
      expect(batchesOf(const []), isEmpty);
    });

    test('ownedCounts counts wardrobe items by category', () {
      final counts = ownedCounts([
        {'category': 'Tops'},
        {'category': 'tops'},
        {'category': 'outerwear'},
        {'category': ''},
        {'name': 'no category'},
      ]);
      expect(counts, {'tops': 2, 'outerwear': 1});
    });
  });
}
