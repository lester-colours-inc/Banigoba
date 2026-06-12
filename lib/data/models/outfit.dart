import 'package:cloud_firestore/cloud_firestore.dart';
import 'product.dart';

class Outfit {
  final String id;
  final String name;
  final String imageUrl;
  final List<Product> products;
  final DateTime createdAt;

  Outfit({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.products,
    required this.createdAt,
  });

  factory Outfit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    final rawProducts = data['products'] ?? [];
    final products = rawProducts is Iterable
        ? rawProducts
              .whereType<Map>()
              .map(
                (item) => Product.fromMap(
                  Map<String, dynamic>.from(item),
                  id: item['id']?.toString(),
                ),
              )
              .toList()
        : <Product>[];
    final rawCreatedAt = data['createdAt'];

    return Outfit(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      imageUrl: (data['imageURL'] ?? data['imageUrl'] ?? '').toString(),
      products: products,
      createdAt: rawCreatedAt is Timestamp
          ? rawCreatedAt.toDate()
          : rawCreatedAt is DateTime
          ? rawCreatedAt
          : DateTime.now(),
    );
  }
}
