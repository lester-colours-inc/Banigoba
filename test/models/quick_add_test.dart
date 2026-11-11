// Verifies the quick-add rules for flea-market traders (K-1).
import 'package:banigoba/modules/shop/models/quick_add.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePrice', () {
    test('reads plain and decorated prices', () {
      expect(parsePrice('12'), 12);
      expect(parsePrice(' 12.5 '), 12.5);
      expect(parsePrice(r'$12,50'), 12.5);
    });

    test('refuses anything that is not a positive number', () {
      expect(parsePrice(''), isNull);
      expect(parsePrice('abc'), isNull);
      expect(parsePrice('0'), isNull);
      expect(parsePrice('-3'), isNull);
    });

    test('rounds to the cent', () {
      expect(parsePrice('1.239'), 1.24);
    });
  });

  group('QuickAddDraft', () {
    const ready = QuickAddDraft(hasPhoto: true, price: 10);

    test('asks for a photo, then a price, then a size', () {
      expect(const QuickAddDraft().problem, 'Add a photo of the piece.');
      expect(const QuickAddDraft(hasPhoto: true).problem, 'Enter a price.');
      expect(ready.problem, 'Pick at least one size.');
      expect(ready.adjustSize('M', 1).problem, isNull);
    });

    test('adding and removing a size', () {
      final two = ready.adjustSize('M', 1).adjustSize('M', 1);
      expect(two.sizes, {'M': 2});
      expect(two.totalStock, 2);
      expect(two.adjustSize('M', -2).sizes, isEmpty);
    });

    test('accessories need a count, not a size', () {
      final scarf = ready.copyWith(kind: QuickKind.accessories);
      expect(scarf.kind.isSized, isFalse);
      expect(scarf.totalStock, 1);
      expect(scarf.problem, isNull);
      expect(scarf.copyWith(quantity: 0).problem, 'Say how many you have.');
    });

    test('changing the kind clears sizes that no longer fit', () {
      final shoes = ready.adjustSize('M', 1).copyWith(kind: QuickKind.shoes);
      expect(shoes.sizes, isEmpty);
      expect(QuickKind.shoes.sizes.first, 'UK 3');
    });

    test('the name falls back to the kind', () {
      expect(ready.displayName, 'Top');
      expect(ready.copyWith(name: ' Blue shirt ').displayName, 'Blue shirt');
    });

    test('a ready draft becomes a product with defaults', () {
      final product = ready
          .copyWith(kind: QuickKind.shoes)
          .adjustSize('UK 6', 2)
          .toProduct(imageUrl: 'https://x/y.jpg', shopName: 'Tari');

      expect(product['name'], 'Shoes');
      expect(product['price'], 10);
      expect(product['stock'], 2);
      expect(product['sizeInventory'], {'UK 6': 2});
      expect(product['category'], 'shoes');
      expect(product['imageUrl'], 'https://x/y.jpg');
      expect(product['shopName'], 'Tari');
    });

    test('an unsized piece carries no size map', () {
      final product = ready
          .copyWith(kind: QuickKind.other, quantity: 3)
          .toProduct(imageUrl: 'u', shopName: 's');

      expect(product.containsKey('sizeInventory'), isFalse);
      expect(product['stock'], 3);
    });
  });

  group('adjustedStock', () {
    test('never goes below zero and keeps the size', () {
      expect(adjustedStock({'M': 1}, 'M', -3), {'M': 0});
      expect(adjustedStock({'M': 1}, 'L', 2), {'M': 1, 'L': 2});
    });
  });
}
