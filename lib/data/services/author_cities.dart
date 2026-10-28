// The city each post author chose (a public field on their user document),
// loaded once per author and kept, so the feeds can rank and filter by "near
// me" (A-5, P-5). An author with no city is remembered as '' so they are not
// asked for again.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/geo_cell.dart';
import 'feed_matches_service.dart' show batchesOf;

class AuthorCities {
  AuthorCities({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final Map<String, String> _cities = {};
  final Map<String, GeoCell> _cells = {};

  /// Every city known so far, by author id.
  Map<String, String> get known => Map.unmodifiable(_cities);

  /// The coarse area of every author who shares one, by author id.
  Map<String, GeoCell> get knownCells => Map.unmodifiable(_cells);

  /// Loads the cities of authors not seen before. True when something new
  /// was learned, so the caller knows to rebuild.
  Future<bool> ensure(Iterable<String> authorIds) async {
    final missing = {
      for (final id in authorIds)
        if (id.isNotEmpty && !_cities.containsKey(id)) id,
    };
    if (missing.isEmpty) return false;
    for (final id in missing) {
      _cities[id] = '';
    }
    for (final batch in batchesOf(missing)) {
      try {
        final snapshot = await _db
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final doc in snapshot.docs) {
          _cities[doc.id] = (doc.data()['city'] ?? '').toString();
          if (GeoCell.tryParse(doc.data()['areaCell']?.toString())
              case final cell?) {
            _cells[doc.id] = cell;
          }
        }
      } on FirebaseException {
        // Leave them as unknown; the feed still works, just without "near".
      }
    }
    return true;
  }

  /// The signed-in person's own city, '' when none is set.
  Future<String> cityOf(String userId) async {
    try {
      final data = (await _db.collection('users').doc(userId).get()).data();
      final city = (data?['city'] ?? '').toString();
      if (city.isNotEmpty) return city;
      final address = data?['address'];
      return address is Map ? (address['city'] ?? '').toString() : '';
    } on FirebaseException {
      return '';
    }
  }
}
