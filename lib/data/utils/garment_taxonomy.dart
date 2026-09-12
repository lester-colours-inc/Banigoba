// Garment classification helpers shared by every try-on path.
//
// Maps loose catalogue category strings onto the FASHN try-on categories and
// onto a layering order, so garments are applied in a physically sensible
// sequence (base layers before outerwear).
library;

/// Layering groups, ordered base-first.
const List<String> kGarmentLayerOrder = [
  'dresses',
  'tops',
  'bottoms',
  'outerwear',
  'accessories',
  'other',
];

/// FASHN try-on category for a catalogue category string.
String fashnCategoryFor(String? value) {
  final category = value?.toLowerCase() ?? '';
  if (category.contains('bottom') ||
      category.contains('pants') ||
      category.contains('trouser') ||
      category.contains('skirt')) {
    return 'bottoms';
  }
  if (category.contains('dress') ||
      category.contains('jumpsuit') ||
      category.contains('one-piece')) {
    return 'one-pieces';
  }
  if (category.contains('top') ||
      category.contains('shirt') ||
      category.contains('jacket') ||
      category.contains('outerwear') ||
      category.contains('blazer') ||
      category.contains('coat') ||
      category.contains('hoodie')) {
    return 'tops';
  }
  return 'auto';
}

/// Layering group for a product map.
String garmentGroupOf(Map<String, dynamic> product) {
  final value = '${product['category'] ?? ''} ${product['subcategory'] ?? ''}'
      .toLowerCase();
  if (value.contains('dress') ||
      value.contains('jumpsuit') ||
      value.contains('one-piece')) {
    return 'dresses';
  }
  if (value.contains('outerwear') ||
      value.contains('jacket') ||
      value.contains('blazer') ||
      value.contains('coat') ||
      value.contains('hoodie') ||
      value.contains('cardigan')) {
    return 'outerwear';
  }
  if (value.contains('bottom') ||
      value.contains('pants') ||
      value.contains('trouser') ||
      value.contains('jean') ||
      value.contains('short') ||
      value.contains('skirt')) {
    return 'bottoms';
  }
  if (value.contains('accessor') ||
      value.contains('bag') ||
      value.contains('hat') ||
      value.contains('watch') ||
      value.contains('jewel')) {
    return 'accessories';
  }
  if (value.contains('top') ||
      value.contains('shirt') ||
      value.contains('tee') ||
      value.contains('tank') ||
      value.contains('blouse') ||
      value.contains('polo') ||
      value.contains('sweatshirt')) {
    return 'tops';
  }
  return 'other';
}

/// Products sorted base-layer first. Does not mutate the input.
List<Map<String, dynamic>> orderGarmentsForLayering(
  List<Map<String, dynamic>> products,
) {
  const fallbackIndex = 4;
  final sorted = [...products];
  sorted.sort((a, b) {
    final left = kGarmentLayerOrder.indexOf(garmentGroupOf(a));
    final right = kGarmentLayerOrder.indexOf(garmentGroupOf(b));
    return (left < 0 ? fallbackIndex : left).compareTo(
      right < 0 ? fallbackIndex : right,
    );
  });
  return sorted;
}

/// First usable image URL on a product map, across the several field names
/// the catalogue has used over time.
String garmentImageUrlOf(Map<String, dynamic> product) {
  const fields = [
    'rawImageUrl',
    'imageUrl',
    'imageURL',
    'processedImageUrl',
    'processed_url',
    'raw_url',
  ];
  for (final field in fields) {
    final value = product[field];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return '';
}
