// A saved outfit as the trip packer sees it: a name, a picture, garment names.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'packing_outfit.freezed.dart';

@freezed
abstract class PackingOutfit with _$PackingOutfit {
  const PackingOutfit._();

  const factory PackingOutfit(String id, Map<String, dynamic> data) =
      _PackingOutfit;

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
