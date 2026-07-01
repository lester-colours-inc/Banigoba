import 'package:banigoba/data/utils/size_inventory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('size inventory helpers', () {
    test('normalizes labels from customer and seller input', () {
      expect(normalizeSizeLabel(' uk 10 '), 'UK 10');
      expect(normalizeSizeLabel('xxs'), 'XXS');
      expect(normalizeSizeLabel(null), '');
    });

    test('parses Firestore size inventory into uppercase integer buckets', () {
      final inventory = parseSizeInventory({
        'sizeInventory': {
          ' uk 8 ': '2',
          'm': 4,
          'XXL': 1.9,
          '': 10,
          'bad': 'not-a-number',
        },
      });

      expect(inventory, {'UK 8': 2, 'M': 4, 'XXL': 1, 'BAD': 0});
    });

    test('returns an empty map when a product has no size inventory', () {
      expect(parseSizeInventory({'stock': 5}), isEmpty);
      expect(parseSizeInventory({'sizeInventory': 'M: 5'}), isEmpty);
    });

    test('totals all available size buckets', () {
      expect(totalSizeInventory({'XXS': 1, 'UK 10': 3, 'L': 0}), 4);
    });

    test('builds stable cart ids for one product in multiple sizes', () {
      expect(cartItemIdForSize('product123', ''), 'product123');
      expect(
        cartItemIdForSize('product123', ' uk 10 '),
        'product123_size_uk 10',
      );
      expect(cartItemIdForSize('product123', 'M/L'), 'product123_size_m-l');
    });
  });
}
