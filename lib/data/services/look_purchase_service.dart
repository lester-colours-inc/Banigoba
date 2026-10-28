// Loads what "Get this look" needs for one person (K-4, A-7): their
// wardrobe, size, chosen styles, and stock from verified shops, then runs the
// matching in models/look_purchase.dart.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/body_profile.dart';
import '../models/feed_matching.dart';
import '../models/look_purchase.dart';
import '../models/look_request.dart';
import 'body_profile_service.dart';
import 'feed_matches_service.dart';

/// What the sheet needs; the real one reads Firestore, tests use a fake.
abstract interface class LookPurchaseSource {
  Future<List<PieceAdvice>> load(String userId, List<LookPart> parts);
}

/// Pieces fetched across all shops before the verified ones are kept.
const int kStockScan = 100;

/// The product categories to scan for [parts]. Older shoe listings sit under
/// "other" or "accessories".
Set<String> categoriesToScan(Iterable<LookPart> parts) => {
  for (final part in parts)
    ...switch (part) {
      LookPart.hair => const <String>{},
      LookPart.outfit => const {'tops', 'bottoms', 'dresses', 'outerwear'},
      LookPart.top => const {'tops', 'outerwear'},
      LookPart.bottom => const {'bottoms'},
      LookPart.shoes => const {'shoes', 'other', 'accessories'},
      LookPart.accessories => const {'accessories'},
    },
};

class LookPurchaseService implements LookPurchaseSource {
  LookPurchaseService({
    FirebaseFirestore? db,
    Future<BodyProfile> Function()? loadBody,
  }) : _db = db ?? FirebaseFirestore.instance,
       _loadBody = loadBody ?? BodyProfileService().loadForCurrentUser;

  final FirebaseFirestore _db;
  final Future<BodyProfile> Function() _loadBody;

  Future<Set<String>> _verifiedSellers(Set<String> sellerIds) async {
    final verified = <String>{};
    for (final batch in batchesOf(sellerIds)) {
      final snapshot = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final doc in snapshot.docs) {
        final shop = doc.data()['shop'];
        if (shop is Map && shop['verified'] == true) verified.add(doc.id);
      }
    }
    return verified;
  }

  @override
  Future<List<PieceAdvice>> load(String userId, List<LookPart> parts) async {
    final wanted = [
      for (final part in parts)
        if (part != LookPart.hair) part,
    ];
    if (userId.isEmpty || wanted.isEmpty) return const [];

    final userDoc = await _db.collection('users').doc(userId).get();
    final rawStyles = userDoc.data()?['stylePreferences'];
    final styles = rawStyles is Iterable
        ? rawStyles.map((style) => style.toString()).toList()
        : const <String>[];
    final wardrobe = await _db
        .collection('user_products')
        .where('userId', isEqualTo: userId)
        .get();
    final body = await _loadBody();

    final categories = categoriesToScan(wanted).toList();
    final stock = <Map<String, dynamic>>[];
    for (final batch in batchesOf(categories, 10)) {
      final snapshot = await _db
          .collection('products')
          .where('category', whereIn: batch)
          .limit(kStockScan)
          .get();
      for (final doc in snapshot.docs) {
        stock.add({...doc.data(), 'id': doc.id});
      }
    }
    final verified = await _verifiedSellers(
      {for (final product in stock) sellerOf(product)}..remove(''),
    );
    final fromVerified = [
      for (final product in stock)
        if (verified.contains(sellerOf(product))) product,
    ];

    return [
      for (final part in wanted)
        adviceFor(
          part,
          userId: userId,
          wardrobe: wardrobe.docs.map((doc) => doc.data()),
          stock: fromVerified,
          body: body,
          styles: styles,
        ),
    ];
  }
}
