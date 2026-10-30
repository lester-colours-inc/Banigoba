// Saves and reads shared stock links (K-9) and the pieces a link shows.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/shop_link.dart';
import 'feed_matches_service.dart' show batchesOf;

/// What the shared-stock screens need; the real one reads Firestore.
abstract interface class ShopLinkSource {
  Future<ShopLink?> load(String id);

  /// The pieces [link] shows, in the order the shop chose for picked links.
  Future<List<Map<String, dynamic>>> pieces(ShopLink link);
}

/// Pieces shown for an "all stock" or category link.
const int kPiecesPerLink = 60;

class ShopLinkService implements ShopLinkSource {
  ShopLinkService({FirebaseFirestore? db}) : _injected = db;

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _db => _injected ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _links =>
      _db.collection('shop_links');

  ShopLink _read(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = {...?doc.data()};
    if (data['createdAt'] case final Timestamp stamp) {
      data['createdAt'] = stamp.toDate();
    }
    return ShopLink.fromMap(doc.id, data);
  }

  /// Saves a new link and returns its id. The server then tells the chosen
  /// audience.
  Future<String> create(ShopLink link) async {
    final ref = _links.doc();
    await ref.set({...link.toMap(), 'createdAt': FieldValue.serverTimestamp()});
    return ref.id;
  }

  @override
  Future<ShopLink?> load(String id) async {
    final doc = await _links.doc(id).get();
    return doc.exists ? _read(doc) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> pieces(ShopLink link) async {
    final products = _db.collection('products');
    if (link.scope == ShareScope.items) {
      final found = <String, Map<String, dynamic>>{};
      for (final batch in batchesOf(link.productIds)) {
        final snapshot = await products
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final doc in snapshot.docs) {
          found[doc.id] = {...doc.data(), 'id': doc.id};
        }
      }
      return [for (final id in link.productIds) ?found[id]];
    }
    var query = products.where('uploaderId', isEqualTo: link.ownerId);
    if (link.scope == ShareScope.category) {
      query = query.where('category', isEqualTo: link.category);
    }
    final snapshot = await query.limit(kPiecesPerLink).get();
    return [
      for (final doc in snapshot.docs) {...doc.data(), 'id': doc.id},
    ];
  }

  /// The shop's own links, newest first.
  Future<List<ShopLink>> mine(String ownerId) async {
    final snapshot = await _links.where('ownerId', isEqualTo: ownerId).get();
    final links = snapshot.docs.map(_read).toList()
      ..sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
    return links;
  }

  /// Public links that are switched on, newest first, for Community.
  Future<List<ShopLink>> publicLinks({int limit = 10}) async {
    final snapshot = await _links
        .where('audience', isEqualTo: ShareAudience.public.value)
        .limit(40)
        .get();
    final links = snapshot.docs.map(_read).where((link) => link.active).toList()
      ..sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
    return links.take(limit).toList();
  }

  Future<void> setActive(ShopLink link, {required bool active}) =>
      _links.doc(link.id).update({'active': active});
}
