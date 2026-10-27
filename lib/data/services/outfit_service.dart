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
      'items': itemNames
          .map((item) => {'name': item.trim(), 'packed': false})
          .where((item) => (item['name'] as String).isNotEmpty)
          .toList(),
      'checkedItems': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updatePackingItemPacked({
    required String userId,
    required String packingListId,
    required List<Map<String, dynamic>> items,
  }) async {
    final checkedItems = items
        .where((item) => item['packed'] == true)
        .map((item) => (item['name'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toList();
    await _db
        .collection('users')
        .doc(userId)
        .collection('packingLists')
        .doc(packingListId)
        .update({
          'items': items
              .map(
                (item) => {
                  'name': (item['name'] ?? '').toString(),
                  'packed': item['packed'] == true,
                },
              )
              .where((item) => (item['name'] as String).isNotEmpty)
              .toList(),
          'checkedItems': checkedItems,
          'updatedAt': FieldValue.serverTimestamp(),
        });
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
      batch.set(
        _db
            .collection('users')
            .doc(userId)
            .collection('eventPlans')
            .doc(eventId),
        {
          'plannedOutfitIds': FieldValue.arrayUnion([outfitId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  /// Keeps the turned-around angles with a saved look ("Turn me around").
  Future<void> saveTurnViews({
    required String userId,
    required String outfitId,
    required Map<String, String> views,
  }) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('outfits')
        .doc(outfitId)
        .update({'turnViews': views});
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
    Map<String, String> turnViews = const {},
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
      if (turnViews.isNotEmpty) 'turnViews': turnViews,
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
      final eventRef = _db
          .collection('users')
          .doc(userId)
          .collection('eventPlans')
          .doc(eventId);
      batch.set(eventRef.collection('days').doc(dateKey), {
        'outfitId': outfitRef.id,
        'wearDate': Timestamp.fromDate(normalizedDate),
        'outfitName': 'Planned Look',
        'imageUrl': resultImageUrl,
        'products': productSnapshots,
      });
      batch.set(eventRef, {
        'plannedOutfitIds': FieldValue.arrayUnion([outfitRef.id]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
    Map<String, String> turnViews = const {},
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
      if (turnViews.isNotEmpty) 'turnViews': turnViews,
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

  /// Saves a feed look into the user's Smart Wardrobe (their saved outfits).
  /// Keyed by the post, so saving the same look twice keeps one copy.
  Future<void> saveLookToWardrobe({
    required String userId,
    required String postId,
    required String imageUrl,
    String name = 'Saved Look',
    List<Map<String, dynamic>> products = const [],
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('outfits')
        .doc('post_$postId')
        .set({
          'userId': userId,
          'name': name,
          'avatarImageUrl': imageUrl,
          'imageUrl': imageUrl,
          'products': products.map(_productSnapshot).toList(),
          'previewType': 'saved_post',
          'apiIntegrationStatus': 'generated',
          'sourcePostId': postId,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  /// Ids of the feed posts this user has saved to their Smart Wardrobe.
  Stream<Set<String>> watchSavedPostIds(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('outfits')
        .where('previewType', isEqualTo: 'saved_post')
        .snapshots()
        .map(
          (snapshot) => {
            for (final doc in snapshot.docs)
              if (doc.data()['sourcePostId'] case final String id) id,
          },
        );
  }

  /// Files a saved feed look under [category] in Smart Wardrobe › Saved
  /// Looks. An empty category clears it.
  Future<void> setSavedLookCategory({
    required String userId,
    required String postId,
    required String category,
  }) => setOutfitCategory(
    userId: userId,
    outfitId: 'post_$postId',
    category: category,
  );

  /// Moves any saved look (from a feed post or a makeover) to [category]; an
  /// empty one clears it.
  Future<void> setOutfitCategory({
    required String userId,
    required String outfitId,
    required String category,
  }) {
    final name = category.trim();
    return _db
        .collection('users')
        .doc(userId)
        .collection('outfits')
        .doc(outfitId)
        .update({'category': name.isEmpty ? FieldValue.delete() : name});
  }

  /// The categories the user has already filed saved looks under, A to Z.
  Future<List<String>> savedLookCategories(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('outfits')
        .get();
    final names = {
      for (final doc in snapshot.docs)
        if ((doc.data()['category'] ?? '').toString().trim()
            case final String name when name.isNotEmpty)
          name,
    }.toList()..sort();
    return List.unmodifiable(names);
  }

  Future<void> removeLookFromWardrobe({
    required String userId,
    required String postId,
  }) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('outfits')
        .doc('post_$postId')
        .delete();
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
