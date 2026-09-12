// Garment layering and category mapping, shared by every try-on path.
import 'package:banigoba/data/utils/garment_taxonomy.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _product(String category, {String? subcategory}) => {
  'category': category,
  if (subcategory != null) 'subcategory': subcategory,
};

void main() {
  group('fashnCategoryFor', () {
    test('maps bottom-half garments to bottoms', () {
      for (final value in ['bottoms', 'Pants', 'trousers', 'midi skirt']) {
        expect(fashnCategoryFor(value), 'bottoms', reason: value);
      }
    });

    test('maps full-body garments to one-pieces', () {
      for (final value in ['Dress', 'jumpsuit', 'one-piece']) {
        expect(fashnCategoryFor(value), 'one-pieces', reason: value);
      }
    });

    test('maps upper-body garments to tops', () {
      for (final value in ['tops', 'Shirt', 'jacket', 'blazer', 'hoodie']) {
        expect(fashnCategoryFor(value), 'tops', reason: value);
      }
    });

    test('falls back to auto for anything unrecognised', () {
      expect(fashnCategoryFor('sunglasses'), 'auto');
      expect(fashnCategoryFor(''), 'auto');
      expect(fashnCategoryFor(null), 'auto');
    });
  });

  group('garmentGroupOf', () {
    test('classifies each layering group', () {
      expect(garmentGroupOf(_product('Summer dress')), 'dresses');
      expect(garmentGroupOf(_product('Wool coat')), 'outerwear');
      expect(garmentGroupOf(_product('Jeans')), 'bottoms');
      expect(garmentGroupOf(_product('Leather bag')), 'accessories');
      expect(garmentGroupOf(_product('Polo')), 'tops');
      expect(garmentGroupOf(_product('Mystery item')), 'other');
    });

    test('reads the subcategory when the category is vague', () {
      expect(
        garmentGroupOf(_product('apparel', subcategory: 'trousers')),
        'bottoms',
      );
    });

    test('is case insensitive', () {
      expect(garmentGroupOf(_product('JACKET')), 'outerwear');
    });
  });

  group('orderGarmentsForLayering', () {
    test('puts base layers before outer layers', () {
      final ordered = orderGarmentsForLayering([
        _product('Trench coat'),
        _product('Jeans'),
        _product('T-shirt'),
      ]);

      expect(ordered.map((p) => garmentGroupOf(p)), [
        'tops',
        'bottoms',
        'outerwear',
      ]);
    });

    test('puts a dress before outerwear and accessories', () {
      final ordered = orderGarmentsForLayering([
        _product('Handbag'),
        _product('Blazer'),
        _product('Wrap dress'),
      ]);

      expect(garmentGroupOf(ordered.first), 'dresses');
      expect(garmentGroupOf(ordered.last), 'accessories');
    });

    test('does not mutate the caller\'s list', () {
      final original = [_product('Coat'), _product('Shirt')];
      final snapshot = [...original];

      orderGarmentsForLayering(original);

      expect(original, equals(snapshot));
    });

    test('handles an empty list', () {
      expect(orderGarmentsForLayering(const []), isEmpty);
    });
  });

  group('garmentImageUrlOf', () {
    test('prefers the raw image field', () {
      expect(
        garmentImageUrlOf({
          'rawImageUrl': 'https://example.test/raw.jpg',
          'imageUrl': 'https://example.test/other.jpg',
        }),
        'https://example.test/raw.jpg',
      );
    });

    test('falls through the legacy field names', () {
      expect(
        garmentImageUrlOf({'processed_url': 'https://example.test/p.jpg'}),
        'https://example.test/p.jpg',
      );
      expect(
        garmentImageUrlOf({'imageURL': 'https://example.test/u.jpg'}),
        'https://example.test/u.jpg',
      );
    });

    test('trims surrounding whitespace', () {
      expect(
        garmentImageUrlOf({'imageUrl': '  https://example.test/a.jpg  '}),
        'https://example.test/a.jpg',
      );
    });

    test('returns empty when there is no usable image', () {
      expect(garmentImageUrlOf({'name': 'No image'}), isEmpty);
      expect(garmentImageUrlOf({'imageUrl': '   '}), isEmpty);
      expect(garmentImageUrlOf({'imageUrl': 42}), isEmpty);
    });
  });
}
