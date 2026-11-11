// Which wardrobe group (accessories, dresses, …) a product belongs to.

/// Groups a product by its category and subcategory text.
String tryOnGroup(Map<String, dynamic> product) {
  final category = (product['category'] ?? '').toString().toLowerCase();
  final subcategory = (product['subcategory'] ?? '').toString().toLowerCase();
  final value = '$category $subcategory';

  if (value.contains('accessor') ||
      value.contains('hat') ||
      value.contains('cap') ||
      value.contains('glass') ||
      value.contains('bag') ||
      value.contains('jewel') ||
      value.contains('watch')) {
    return 'accessories';
  }
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
      value.contains('trouser') ||
      value.contains('pants') ||
      value.contains('jean') ||
      value.contains('short') ||
      value.contains('skirt') ||
      value.contains('legging') ||
      value.contains('jogger')) {
    return 'bottoms';
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
