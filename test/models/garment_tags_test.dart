// Verifies the AI answer is cut down to what the app knows.
import 'package:banigoba/modules/wardrobe/models/garment_tags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a clean answer is kept', () {
    final tags = GarmentTags.fromJson({
      'name': 'Navy linen shirt',
      'category': 'tops',
      'subcategory': 'shirts',
      'styleTag': 'corporate',
      'gender': 'male',
      'colours': ['blue', 'white'],
      'weatherTags': ['hot', 'mild'],
      'functionalTags': ['breathable'],
    });

    expect(tags.name, 'Navy linen shirt');
    expect(tags.category, 'tops');
    expect(tags.subcategory, 'shirts');
    expect(tags.styleTag, 'corporate');
    expect(tags.colours, ['blue', 'white']);
    expect(tags.weatherTags, ['hot', 'mild']);
    expect(tags.functionalTags, ['breathable']);
  });

  test('words the app does not know are dropped', () {
    final tags = GarmentTags.fromJson({
      'category': 'fancy-hats',
      'styleTag': 'cyberpunk',
      'gender': 'robot',
      'colours': ['teal', 'blue'],
      'weatherTags': ['monsoon'],
    });

    expect(tags.category, isNull);
    expect(tags.styleTag, isNull);
    expect(tags.gender, isNull);
    expect(tags.colours, ['blue']);
    expect(tags.weatherTags, isEmpty);
  });

  test('a subcategory must belong to the category', () {
    final wrong = GarmentTags.fromJson({
      'category': 'shoes',
      'subcategory': 'shirts',
    });
    expect(wrong.category, 'shoes');
    expect(wrong.subcategory, isNull);

    final right = GarmentTags.fromJson({
      'category': 'shoes',
      'subcategory': 'sneakers',
    });
    expect(right.subcategory, 'sneakers');
  });

  test('matching ignores case and spaces, and repeats', () {
    final tags = GarmentTags.fromJson({
      'category': ' Tops ',
      'colours': ['Blue', 'blue', 'RED'],
    });

    expect(tags.category, 'tops');
    expect(tags.colours, ['blue', 'red']);
  });

  test('at most three colours', () {
    final tags = GarmentTags.fromJson({
      'colours': ['black', 'white', 'grey', 'blue', 'red'],
    });
    expect(tags.colours, hasLength(kMaxTaggedColours));
  });

  test('a long name is shortened and nothing known is empty', () {
    final long = GarmentTags.fromJson({'name': 'x' * 80});
    expect(long.name.length, lessThanOrEqualTo(40));
    expect(GarmentTags.fromJson({'name': ''}).isEmpty, isTrue);
  });
}
