// Defines the typed product data used by shopping and wardrobe features.
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String imageUrl;
  final String? rawImageUrl;
  final String category;
  final String? subcategory;
  final String styleTag;
  final List<String> colours;
  final String gender;
  final List<String> weatherTags;
  final List<String> functionalTags;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.rawImageUrl,
    required this.category,
    this.subcategory,
    this.styleTag = 'casual',
    required this.colours,
    required this.gender,
    this.weatherTags = const [],
    this.functionalTags = const [],
    this.createdAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product.fromMap(data, id: doc.id);
  }

  factory Product.fromMap(Map<String, dynamic> data, {String? id}) {
    // Handle different naming conventions in database
    final String img = data['imageUrl'] ?? data['imageURL'] ?? '';
    final String? rawImg = data['rawImageUrl'];

    // Handle colours being potentially a single string or a list
    final List<String> colList = [];
    if (data['colours'] is List) {
      colList.addAll(List<String>.from(data['colours']));
    } else if (data['colour'] != null) {
      colList.add(data['colour'].toString());
    }

    return Product(
      id: id ?? (data['id'] ?? '').toString(),
      name: data['name'] ?? '',
      imageUrl: img,
      rawImageUrl: rawImg,
      category: data['category'] ?? '',
      subcategory: data['subcategory'],
      styleTag: data['styleTag'] ?? data['style'] ?? 'casual',
      colours: colList,
      gender: data['gender'] ?? 'unisex',
      weatherTags: List<String>.from(data['weatherTags'] ?? []),
      functionalTags: List<String>.from(data['functionalTags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'rawImageUrl': rawImageUrl,
      'category': category,
      'subcategory': subcategory,
      'styleTag': styleTag,
      'colours': colours,
      'gender': gender,
      'weatherTags': weatherTags,
      'functionalTags': functionalTags,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
