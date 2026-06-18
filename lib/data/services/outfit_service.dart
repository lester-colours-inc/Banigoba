// Stores completed avatar outfits for the signed-in user.
import 'package:cloud_firestore/cloud_firestore.dart';

class OutfitService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSavedOutfits(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('outfits')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchWearHistory(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('wearHistory')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchEventPlans(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('eventPlans')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPackingLists(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('packingLists')
        .snapshots();
  }

  Future<String> createEventPlan({
    required String userId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final ref = _db
        .collection('users')
        .doc(userId)
        .collection('eventPlans')
        .doc();
    await ref.set({
      'name': name.trim(),
      'startDate': Timestamp.fromDate(
        DateTime(startDate.year, startDate.month, startDate.day),
      ),
      'endDate': Timestamp.fromDate(
        DateTime(endDate.year, endDate.month, endDate.day),
      ),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<String> createPackingList({
    required String userId,
    required String name,
    required List<String> outfitIds,
    required List<String> itemNames,
  }) async {
    final ref = _db
        .collection('users')
        .doc(userId)
        .collection('packingLists')
        .doc();
    await ref.set({
      'name': name.trim(),
      'outfitIds': outfitIds,
      'items': itemNames,
      'checkedItems': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> reuseOutfitOnDate({
    required String userId,
    required String outfitId,
    required DateTime date,
    required Map<String, dynamic> outfit,
    String? eventId,
    String? eventName,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final dateKey =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final wearRef = _db
        .collection('users')
        .doc(userId)
        .collection('wearHistory')
        .doc(dateKey);
    final data = {
      'userId': userId,
      'outfitId': outfitId,
      'wearDate': Timestamp.fromDate(normalizedDate),
      'outfitName': (outfit['name'] ?? 'Completed Look').toString(),
      'imageUrl': (outfit['imageUrl'] ?? '').toString(),
      'avatarImageUrl': (outfit['avatarImageUrl'] ?? '').toString(),
      'products': outfit['products'] is Iterable
          ? List<dynamic>.from(outfit['products'])
          : const [],
      'eventId': ?eventId,
      'eventName': ?eventName,
      'reusedAt': FieldValue.serverTimestamp(),
    };
    final batch = _db.batch();
    batch.set(wearRef, data);
    if (eventId != null) {
      batch.set(
        _db
            .collection('users')
            .doc(userId)
            .collection('eventPlans')
            .doc(eventId)
            .collection('days')
            .doc(dateKey),
        data,
      );
    }
    await batch.commit();
  }

  Future<String> saveOutfitForDate({
    required String userId,
    required String avatarImageUrl,
    required String resultImageUrl,
    required List<Map<String, dynamic>> products,
    required String previewType,
    required DateTime date,
    String? eventId,
    String? eventName,
  }) async {
    final outfitRef = _db
        .collection('users')
        .doc(userId)
        .collection('outfits')
        .doc();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final dateKey =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final wearRef = _db
        .collection('users')
        .doc(userId)
        .collection('wearHistory')
        .doc(dateKey);
    final productSnapshots = products.map(_productSnapshot).toList();
    final batch = _db.batch();

    final outfitData = {
      'userId': userId,
      'name': 'Planned Look',
      'avatarImageUrl': avatarImageUrl,
      'imageUrl': resultImageUrl,
      'products': productSnapshots,
      'previewType': previewType,
      'apiIntegrationStatus': previewType == 'mock_collage'
          ? 'pending_replacement'
          : 'generated',
      'plannedDate': Timestamp.fromDate(normalizedDate),
      'eventId': ?eventId,
      'eventName': ?eventName,
      'createdAt': FieldValue.serverTimestamp(),
    };

    batch.set(outfitRef, outfitData);
    batch.set(wearRef, {
      'userId': userId,
      'outfitId': outfitRef.id,
      'wearDate': Timestamp.fromDate(normalizedDate),
      'outfitName': 'Planned Look',
      'imageUrl': resultImageUrl,
      'avatarImageUrl': avatarImageUrl,
      'products': productSnapshots,
      'planned': true,
      'eventId': ?eventId,
      'eventName': ?eventName,
      'reusedAt': FieldValue.serverTimestamp(),
    });
    if (eventId != null) {
      batch.set(
        _db
            .collection('users')
            .doc(userId)
            .collection('eventPlans')
            .doc(eventId)
            .collection('days')
            .doc(dateKey),
        {
          'outfitId': outfitRef.id,
          'wearDate': Timestamp.fromDate(normalizedDate),
          'outfitName': 'Planned Look',
          'imageUrl': resultImageUrl,
          'products': productSnapshots,
        },
      );
    }

    await batch.commit();
    return outfitRef.id;
  }

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
    String caption = 'My completed try-on look',
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
      'caption': caption.trim().isEmpty
          ? 'My completed try-on look'
          : caption.trim(),
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'imageURL': resultImageUrl,
      'likeCount': 0,
      'likedBy': [],
      'likes': [],
      'isPublic': false,
      'visibility': 'private',
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
      'isPublic': false,
      'visibility': 'private',
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
