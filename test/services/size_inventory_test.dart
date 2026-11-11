// Protects the shared size-inventory rules used by product detail, cart, and
// checkout. These helpers are pure Dart so they should stay quick and stable.
import 'package:banigoba/core/utils/size_inventory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('size inventory helpers', () {
    test(
      'normalizes valid and blank labels from customer and seller input',
      () {
        expect(normalizeSizeLabel(' uk 10 '), 'UK 10');
        expect(normalizeSizeLabel('xxs'), 'XXS');
        expect(normalizeSizeLabel(null), '');
        expect(normalizeSizeLabel('   '), '');
      },
    );

    test('parses valid Firestore size inventory into integer buckets', () {
      final inventory = parseSizeInventory({
        'sizeInventory': {' uk 8 ': '2', 'm': 4, 'XXL': 1.9},
      });

      expect(inventory, {'UK 8': 2, 'M': 4, 'XXL': 1});
    });

    test(
      'parses invalid inventory values as empty labels or zero quantities',
      () {
        final inventory = parseSizeInventory({
          'sizeInventory': {'': 10, 'bad': 'not-a-number', 'xs': null},
        });

        expect(inventory, {'BAD': 0, 'XS': 0});
      },
    );

    test('returns an empty map for missing or invalid size inventory maps', () {
      expect(parseSizeInventory({'stock': 5}), isEmpty);
      expect(parseSizeInventory({'sizeInventory': 'M: 5'}), isEmpty);
    });

    test('totals valid available size buckets', () {
      expect(totalSizeInventory({'XXS': 1, 'UK 10': 3, 'L': 0}), 4);
    });

    test('totals invalid negative stock values exactly as stored', () {
      expect(totalSizeInventory({'XXS': 1, 'UK 10': -3}), -2);
    });

    test('builds stable cart ids for valid and blank size values', () {
      expect(cartItemIdForSize('product123', ''), 'product123');
      expect(
        cartItemIdForSize('product123', ' uk 10 '),
        'product123_size_uk 10',
      );
      expect(cartItemIdForSize('product123', 'M/L'), 'product123_size_m-l');
    });
  });
}
