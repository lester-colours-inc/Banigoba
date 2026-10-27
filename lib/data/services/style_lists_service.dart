// The user's own style lists (October 2026 review, F-1 to F-3):
//   - Fashion Twins: people on Banigoba whose style is like theirs
//   - Fashion Idols: people they admire, on Banigoba or not, by name
//   - Hairstyles I like: pictures of hairstyles to try or show a salon
// Each list lives privately under users/{uid}/{list}/{id}; only the owner
// can read or change it (the users subcollection rule).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum StyleList {
  twins('fashionTwins'),
  idols('fashionIdols'),
  hairstyles('hairInspiration');

  const StyleList(this.collection);

  final String collection;
}

/// One entry: a person (twin or idol) or a hairstyle picture.
@immutable
class StyleListEntry {
  const StyleListEntry({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.username = '',
    this.addedAt,
  });

  final String id;

  /// The person's name, or a note on a hairstyle.
  final String name;
  final String imageUrl;

  /// Twins only: their @username.
  final String username;
  final DateTime? addedAt;

  factory StyleListEntry.fromMap(String id, Map<String, dynamic> data) {
    final added = data['addedAt'];
    return StyleListEntry(
      id: id,
      name: (data['name'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      username: (data['username'] ?? '').toString(),
      addedAt: added is Timestamp ? added.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
    if (username.isNotEmpty) 'username': username,
    'addedAt': FieldValue.serverTimestamp(),
  };
}

/// Newest first; entries still waiting for a server time come first.
List<StyleListEntry> sortNewestFirst(Iterable<StyleListEntry> entries) {
  final far = DateTime(9999);
  return List.unmodifiable(
    entries.toList()
      ..sort((a, b) => (b.addedAt ?? far).compareTo(a.addedAt ?? far)),
  );
}

/// A stable id for an idol typed by name, so adding the same name twice
/// keeps one entry: "Michelle Obama" -> "michelle-obama".
String idolIdFor(String name) => name
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

class StyleListsService {
  StyleListsService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _list(
    String userId,
    StyleList list,
  ) => _db.collection('users').doc(userId).collection(list.collection);

  Stream<List<StyleListEntry>> watch(String userId, StyleList list) {
    if (userId.isEmpty) return Stream.value(const []);
    return _list(userId, list).snapshots().map(
      (snapshot) => sortNewestFirst(
        snapshot.docs.map((doc) => StyleListEntry.fromMap(doc.id, doc.data())),
      ),
    );
  }

  /// Adds [entry] under its own id, or a new id when [entry.id] is empty.
  Future<void> add(String userId, StyleList list, StyleListEntry entry) {
    final collection = _list(userId, list);
    final ref = entry.id.isEmpty ? collection.doc() : collection.doc(entry.id);
    return ref.set(entry.toMap());
  }

  Future<void> remove(String userId, StyleList list, String id) =>
      _list(userId, list).doc(id).delete();
}
