import 'package:banigoba/data/models/body_profile.dart';
import 'package:banigoba/data/models/look_purchase.dart';
import 'package:banigoba/data/models/look_request.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _product(
  String id, {
  String category = 'tops',
  String name = 'Shirt',
  String seller = 'shop1',
  String style = '',
  num stock = 5,
  num price = 20,
  Map<String, dynamic>? sizes,
}) => {
  'id': id,
  'name': name,
  'category': category,
  'uploaderId': seller,
  'styleTag': style,
  'stock': stock,
  'price': price,
  'sizeInventory': ?sizes,
};

Map<String, dynamic> _owned(String category, {String name = 'My item'}) => {
  'category': category,
  'name': name,
};

const _me = 'me';

void main() {
  group('itemSuitsPart', () {
    test('maps clothes to every garment category', () {
      for (final category in ['tops', 'bottoms', 'dresses', 'outerwear']) {
        expect(
          itemSuitsPart(_product('a', category: category), LookPart.outfit),
          isTrue,
          reason: category,
        );
      }
      expect(
        itemSuitsPart(_product('a', category: 'accessories'), LookPart.outfit),
        isFalse,
      );
    });

    test('a top is a top or outerwear, a bottom is a bottom', () {
      expect(itemSuitsPart(_product('a'), LookPart.top), isTrue);
      expect(
        itemSuitsPart(_product('a', category: 'outerwear'), LookPart.top),
        isTrue,
      );
      expect(itemSuitsPart(_product('a'), LookPart.bottom), isFalse);
      expect(
        itemSuitsPart(_product('a', category: 'bottoms'), LookPart.bottom),
        isTrue,
      );
    });

    test('shoes are found by name, and are not accessories', () {
      final shoe = _product('s', category: 'other', name: 'White Sneakers');
      expect(itemSuitsPart(shoe, LookPart.shoes), isTrue);
      expect(itemSuitsPart(shoe, LookPart.accessories), isFalse);
      expect(
        itemSuitsPart(_product('b', category: 'other'), LookPart.shoes),
        isFalse,
      );
    });

    test('accessories are the accessories category', () {
      expect(
        itemSuitsPart(
          _product('a', category: 'accessories', name: 'Hat'),
          LookPart.accessories,
        ),
        isTrue,
      );
    });

    test('hair has no items to buy', () {
      expect(itemSuitsPart(_product('a'), LookPart.hair), isFalse);
    });
  });

  group('adviceFor', () {
    test('says what the person already owns for the part', () {
      final advice = adviceFor(
        LookPart.top,
        userId: _me,
        wardrobe: [_owned('tops'), _owned('tops'), _owned('bottoms')],
        stock: const [],
        body: const BodyProfile(),
        styles: const [],
      );

      expect(advice.owned, hasLength(2));
      expect(advice.hasIt, isTrue);
    });

    test('suggests pieces of the right kind', () {
      final advice = adviceFor(
        LookPart.bottom,
        userId: _me,
        wardrobe: const [],
        stock: [
          _product('top1'),
          _product('trousers', category: 'bottoms', name: 'Chinos'),
        ],
        body: const BodyProfile(),
        styles: const [],
      );

      expect(advice.picks.map((p) => p.product['id']), ['trousers']);
    });

    test('never suggests the person\'s own stock', () {
      final advice = adviceFor(
        LookPart.top,
        userId: _me,
        wardrobe: const [],
        stock: [_product('mine', seller: _me)],
        body: const BodyProfile(),
        styles: const [],
      );

      expect(advice.picks, isEmpty);
    });

    test('skips sold-out pieces', () {
      final advice = adviceFor(
        LookPart.top,
        userId: _me,
        wardrobe: const [],
        stock: [_product('gone', stock: 0)],
        body: const BodyProfile(),
        styles: const [],
      );

      expect(advice.picks, isEmpty);
    });

    test('offers the size that fits and leaves out pieces with none', () {
      final advice = adviceFor(
        LookPart.top,
        userId: _me,
        wardrobe: const [],
        stock: [
          _product('fits', sizes: {'M': 3, 'L': 2}),
          _product('wrong', sizes: {'XS': 3}),
        ],
        body: const BodyProfile(clothingSize: 'M'),
        styles: const [],
      );

      expect(advice.picks.map((p) => p.product['id']), ['fits']);
      expect(advice.picks.single.size, 'M');
      expect(advice.picks.single.reasons.first, 'In your size (M)');
    });

    test('ranks pieces that suit the person\'s style first', () {
      final advice = adviceFor(
        LookPart.top,
        userId: _me,
        wardrobe: const [],
        stock: [
          _product('plain', style: 'casual', price: 5),
          _product('smart', style: 'corporate', price: 50),
        ],
        body: const BodyProfile(),
        styles: const ['Smart'],
      );

      expect(advice.picks.first.product['id'], 'smart');
      expect(advice.picks.first.reasons, contains('Suits your Smart style'));
    });

    test('at the same score the cheaper piece comes first', () {
      final advice = adviceFor(
        LookPart.top,
        userId: _me,
        wardrobe: const [],
        stock: [_product('dear', price: 50), _product('cheap', price: 10)],
        body: const BodyProfile(),
        styles: const [],
      );

      expect(advice.picks.map((p) => p.product['id']), ['cheap', 'dear']);
    });

    test('offers at most three pieces', () {
      final advice = adviceFor(
        LookPart.top,
        userId: _me,
        wardrobe: const [],
        stock: [for (var i = 0; i < 6; i += 1) _product('p$i', price: i)],
        body: const BodyProfile(),
        styles: const [],
      );

      expect(advice.picks, hasLength(3));
    });

    test('notes when the person has none of this kind yet', () {
      final advice = adviceFor(
        LookPart.top,
        userId: _me,
        wardrobe: [_owned('bottoms')],
        stock: [_product('a')],
        body: const BodyProfile(),
        styles: const [],
      );

      expect(advice.picks.single.reasons, contains("You don't have any yet"));
    });
  });
}
