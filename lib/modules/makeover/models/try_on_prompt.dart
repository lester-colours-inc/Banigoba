// What the try-on prompt needs to know about the chosen items: which part of
// the body each is for, which picture to send, and how to describe them.

/// The engine that dresses the avatar. Results are kept per provider.
enum TryOnProvider {
  gemini('Gemini', 'generated_gemini');

  const TryOnProvider(this.label, this.previewType);

  final String label;

  /// Recorded on the saved outfit so it stays clear which engine made it.
  final String previewType;
}

String tryOnProductImageUrl(Map<String, dynamic> product) {
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

String tryOnProductGroup(Map<String, dynamic> product) {
  final value = '${product['category'] ?? ''} ${product['subcategory'] ?? ''}'
      .toLowerCase();
  if (value.contains('dress') ||
      value.contains('jumpsuit') ||
      value.contains('one-piece')) {
    return 'dresses';
  }
  if (value.contains('shoe') ||
      value.contains('sneaker') ||
      value.contains('boot') ||
      value.contains('sandal') ||
      value.contains('heel')) {
    return 'shoes';
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

/// Dresses first, accessories last, so the layers are described in order.
List<Map<String, dynamic>> orderedTryOnProducts(
  List<Map<String, dynamic>> products,
) {
  const order = {
    'dresses': 0,
    'tops': 1,
    'bottoms': 2,
    'outerwear': 3,
    'shoes': 4,
    'accessories': 5,
    'other': 6,
  };
  final sorted = [...products];
  sorted.sort(
    (a, b) => (order[tryOnProductGroup(a)] ?? 4).compareTo(
      order[tryOnProductGroup(b)] ?? 4,
    ),
  );
  return sorted;
}

String _itemDescription(Map<String, dynamic> product) {
  final name = (product['name'] ?? 'item').toString();
  final placement = switch (tryOnProductGroup(product)) {
    'tops' => 'worn on the upper body',
    'bottoms' => 'worn on the lower body',
    'dresses' => 'worn as a one-piece',
    'outerwear' => 'worn as an outer layer over the other clothing',
    'shoes' => 'worn on the feet',
    'accessories' => 'worn or carried the way this accessory normally is',
    _ => 'worn the way this item normally is',
  };
  return '$name ($placement)';
}

/// Describes the whole look in one instruction, in the same order the images
/// are attached.
String geminiTryOnPrompt(
  List<Map<String, dynamic>> products, {
  String fitNote = '',
}) {
  final items = products
      .map((product) => '- ${_itemDescription(product)}')
      .join('\n');

  return 'The first image is a full-body photo of a person. The remaining '
      '${products.length} image(s) are items to put on that person:\n'
      '$items\n\n'
      'Generate one photorealistic full-body image of the same person '
      'wearing every item exactly as shown. Keep each item\'s colour, '
      'pattern, print, texture, length and cut identical to its reference '
      'image. Preserve the person\'s face, skin tone, hair, body shape, pose '
      'and the background from the first image. Replace any existing '
      'clothing that an item covers. Natural lighting, sharp detail, no '
      'text or watermarks.'
      '${fitNote.isEmpty ? '' : ' $fitNote'}';
}
