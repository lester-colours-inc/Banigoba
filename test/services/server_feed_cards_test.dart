import 'package:banigoba/data/services/feed_matches_service.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _card(
  String id, {
  int score = 5,
  DateTime? at,
  String size = 'M',
  List<String> reasons = const ['In your size (M)'],
}) => {
  'productId': id,
  'score': score,
  'size': size,
  'reasons': reasons,
  'createdAt': at ?? DateTime(2026, 10, 28, 9),
  'product': {'id': id, 'name': 'Piece $id', 'uploaderId': 'shop1'},
};

final _now = DateTime(2026, 10, 28, 12);

void main() {
  group('cardsFromServer', () {
    test('turns a stored card into a feed item with its reasons', () {
      final items = cardsFromServer([
        _card(
          'p1',
          reasons: const ['In your size (M)', 'Suits your Smart style'],
        ),
      ], _now);

      expect(items, hasLength(1));
      expect(items.single.product['name'], 'Piece p1');
      expect(items.single.match.productId, 'p1');
      expect(items.single.match.size, 'M');
      expect(items.single.match.headline, 'In your size (M)');
      expect(items.single.match.reasons, hasLength(2));
    });

    test('keeps the best three, newest first among equals', () {
      final items = cardsFromServer([
        _card('low', score: 3),
        _card('old5', score: 5, at: DateTime(2026, 10, 28, 7)),
        _card('new5', score: 5, at: DateTime(2026, 10, 28, 10)),
        _card('top', score: 7),
      ], _now);

      expect(items.map((item) => item.match.productId), [
        'top',
        'new5',
        'old5',
      ]);
    });

    test('drops cards older than a day', () {
      final items = cardsFromServer([
        _card('fresh', at: DateTime(2026, 10, 28, 8)),
        _card('stale', at: DateTime(2026, 10, 26, 8)),
      ], _now);

      expect(items.map((item) => item.match.productId), ['fresh']);
    });

    test('skips a card with no product data or no id', () {
      final items = cardsFromServer([
        {'productId': 'x', 'score': 5, 'createdAt': DateTime(2026, 10, 28, 9)},
        _card(''),
        _card('ok'),
      ], _now);

      expect(items.map((item) => item.match.productId), ['ok']);
    });

    test('an empty list gives nothing', () {
      expect(cardsFromServer(const [], _now), isEmpty);
    });
  });
}
