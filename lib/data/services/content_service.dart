// Reads the fashion stories and events the content engine stored in
// `content_items` (written only by the refreshFashionContent function).
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/content_item.dart';

/// What the screens need; the real one reads Firestore, tests use a fake.
abstract interface class ContentSource {
  Future<List<ContentItem>> latest({int limit});
}

class ContentService implements ContentSource {
  ContentService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// The newest stories first. Empty when none exist or they cannot be read:
  /// the sections simply stay hidden then.
  @override
  Future<List<ContentItem>> latest({int limit = 60}) async {
    try {
      final snapshot = await _db
          .collection('content_items')
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();
      return [
        for (final doc in snapshot.docs)
          if (ContentItem.fromMap(doc.id, doc.data()) case final item
              when item.title.isNotEmpty && item.opensSafely)
            item,
      ];
    } on FirebaseException {
      return const [];
    }
  }
}
