// A saved outfit as the trip packer sees it: a name, a picture, garment names.
class PackingOutfit {
  const PackingOutfit(this.id, this.data);

  final String id;
  final Map<String, dynamic> data;

  String get name => (data['name'] ?? 'Saved Outfit').toString();
  String get imageUrl =>
      (data['imageUrl'] ?? data['avatarImageUrl'] ?? '').toString();
  List<String> get itemNames {
    final products = data['products'];
    if (products is! Iterable) return const [];
    return products
        .whereType<Map>()
        .map((product) => (product['name'] ?? '').toString().trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }
}
