// Stores completed avatar outfits for the signed-in user.
import 'package:cloud_firestore/cloud_firestore.dart';

class OutfitService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> saveOutfit({
    required String userId,
    required String avatarImageUrl,
    required String resultImageUrl,
    required List<Map<String, dynamic>> products,
    String previewType = 'generated',
  }) async {
    final outfitRef = _db
        .collection('users')
        .doc(userId)
        .collection('outfits')
        .doc();
    await outfitRef.set({
      'userId': userId,
      'name': 'Completed Look',
      'avatarImageUrl': avatarImageUrl,
      'imageUrl': resultImageUrl,
      'products': products.map(_productSnapshot).toList(),
      'previewType': previewType,
      'apiIntegrationStatus': previewType == 'mock_collage'
          ? 'pending_replacement'
          : 'generated',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return outfitRef.id;
  }

  Future<String> saveOutfitToDailyDressUp({
    required String userId,
    required String avatarImageUrl,
    required String resultImageUrl,
    required List<Map<String, dynamic>> products,
    required String previewType,
  }) async {
    final outfitRef = _db
        .collection('users')
        .doc(userId)
        .collection('outfits')
        .doc();
    final postRef = _db.collection('posts').doc();
    final productSnapshots = products.map(_productSnapshot).toList();
    final productIds = productSnapshots
        .map((product) => product['id'].toString())
        .where((id) => id.isNotEmpty)
        .toList();
    final batch = _db.batch();

    batch.set(outfitRef, {
      'userId': userId,
      'name': 'Completed Look',
      'avatarImageUrl': avatarImageUrl,
      'imageUrl': resultImageUrl,
      'products': productSnapshots,
      'previewType': previewType,
      'apiIntegrationStatus': previewType == 'mock_collage'
          ? 'pending_replacement'
          : 'generated',
      'dailyDressUpPostId': postRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(postRef, {
      'authorID': userId,
      'authorId': userId,
      'caption': 'My completed try-on look',
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'imageURL': resultImageUrl,
      'likeCount': 0,
      'likedBy': [],
      'likes': [],
      'outfitId': outfitRef.id,
      'productIds': productIds,
      'products': productSnapshots,
      'previewType': previewType,
      'apiIntegrationStatus': previewType == 'mock_collage'
          ? 'pending_replacement'
          : 'generated',
    });

    await batch.commit();
    return outfitRef.id;
  }

  Future<void> shareOutfitAsPost({
    required String userId,
    required String outfitId,
    required String resultImageUrl,
    required String caption,
    required List<Map<String, dynamic>> products,
  }) async {
    await _db.collection('posts').add({
      'authorID': userId,
      'authorId': userId,
      'caption': caption,
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'imageURL': resultImageUrl,
      'likeCount': 0,
      'likedBy': [],
      'likes': [],
      'outfitId': outfitId,
      'productIds': products
          .map((product) => (product['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList(),
      'products': products.map(_productSnapshot).toList(),
    });
  }

  Map<String, dynamic> _productSnapshot(Map<String, dynamic> product) {
    return {
      'id': (product['id'] ?? '').toString(),
      'name': (product['name'] ?? 'Clothing').toString(),
      'imageUrl': _imageUrl(product),
      'category': (product['category'] ?? '').toString(),
      'subcategory': (product['subcategory'] ?? '').toString(),
      'source': (product['tryOnSource'] ?? 'catalog').toString(),
    };
  }

  String _imageUrl(Map<String, dynamic> product) {
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
}
