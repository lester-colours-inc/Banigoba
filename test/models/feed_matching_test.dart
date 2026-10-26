// Verifies which new shop items reach someone's daily feed (D-4, A-6).
import 'package:banigoba/data/models/body_profile.dart';
import 'package:banigoba/data/models/feed_matching.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

const _body = BodyProfile(
  clothingSize: 'M',
  measurements: {BodyMeasurement.waist: 88, BodyMeasurement.chest: 96},
);

ShopperProfile _shopper({
  List<String> styles = const ['Smart'],
  Map<String, int> owned = const {'tops': 6, 'outerwear': 0},
  Set<String> follows = const {'glow'},
  BodyProfile body = _body,
}) => ShopperProfile(
  userId: 'me',
  body: body,
  styles: styles,
  ownedByCategory: owned,
  followedSellerIds: follows,
);

Map<String, dynamic> _item({
  String id = 'p1',
  String seller = 'glow',
  String category = 'tops',
  String style = 'corporate',
  Map<String, int> sizes = const {'M': 2, 'L': 1},
  Object? createdAt,
  Map<String, Map<String, num>>? chart,
}) => {
  'id': id,
  'uploaderId': seller,
  'category': category,
  'styleTag': style,
  if (sizes.isNotEmpty) 'sizeInventory': sizes,
  'sizeChart': ?chart,
  'createdAt': ?createdAt,
};

void main() {
  group('matchProduct', () {
    test('matches a followed shop\'s piece in my size that suits my style', () {
      final match = matchProduct(_item(), _shopper())!;
      expect(match.size, 'M');
      expect(match.reasons, contains('In your size (M)'));
      expect(match.reasons, contains('Suits your Smart style'));
      expect(match.headline, 'In your size (M)');
    });

    test('never from a shop I do not follow, or my own', () {
      expect(matchProduct(_item(seller: 'stranger'), _shopper()), isNull);
      expect(
        matchProduct(_item(seller: 'me'), _shopper(follows: {'me'})),
        isNull,
      );
    });

    test('needs my size in stock', () {
      expect(matchProduct(_item(sizes: {'M': 0, 'XL': 5}), _shopper()), isNull);
      expect(matchProduct(_item(sizes: {'S': 3}), _shopper()), isNull);
    });

    test('offers the fit-check size when my usual size would be tight', () {
      final chart = {
        'M': {'waist': 84.0},
        'L': {'waist': 98.0},
      };
      final match = matchProduct(_item(chart: chart), _shopper())!;
      expect(match.size, 'L');
    });

    test('a one-size item has no size to offer', () {
      final match = matchProduct(
        _item(category: 'accessories', style: 'corporate', sizes: const {}),
        _shopper(),
      )!;
      expect(match.size, isEmpty);
      expect(match.headline, 'Available now');
    });

    test('needs my style or a gap in my wardrobe', () {
      final off = _item(style: 'streetwear');
      expect(matchProduct(off, _shopper()), isNull);

      final gap = _item(category: 'outerwear', style: 'streetwear');
      final match = matchProduct(gap, _shopper())!;
      expect(match.reasons.last, contains("don't have any outerwear"));
      expect(match.score, 5);
    });

    test('a style match and a gap together score highest', () {
      final both = _item(category: 'outerwear');
      expect(matchProduct(both, _shopper())!.score, 7);
    });

    test('with no chosen styles only a gap qualifies', () {
      final shopper = _shopper(styles: const []);
      expect(matchProduct(_item(), shopper), isNull);
      expect(matchProduct(_item(category: 'outerwear'), shopper), isNotNull);
    });

    test('bridges the shop\'s style names to the shopper\'s', () {
      expect(
        matchingStyle({'styleTag': 'afrochic'}, ['Traditional']),
        'Traditional',
      );
      expect(matchingStyle({'styleTag': 'glamour'}, ['Elegant']), 'Elegant');
      expect(matchingStyle({'styleTag': 'corporate'}, ['Casual']), isNull);
    });
  });

  group('pickDailyMatches', () {
    test('takes the best three, newest first among equals', () {
      final products = [
        _item(id: 'old', createdAt: DateTime(2026, 10, 1)),
        _item(id: 'new', createdAt: Timestamp.fromDate(DateTime(2026, 10, 20))),
        _item(id: 'gap', category: 'outerwear'),
        _item(id: 'mid', createdAt: DateTime(2026, 10, 10)),
        _item(id: 'nope', style: 'streetwear'),
      ];
      final picked = pickDailyMatches(products, _shopper());
      expect(picked.map((m) => m.productId), ['gap', 'new', 'mid']);
      expect(picked, hasLength(kDailyFeedCards));
    });

    test('skips anything already shown', () {
      final picked = pickDailyMatches(
        [_item(id: 'a'), _item(id: 'b')],
        _shopper(),
        alreadyShown: {'a'},
      );
      expect(picked.map((m) => m.productId), ['b']);
    });
  });
}
