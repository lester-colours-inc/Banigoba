// Finds today's "new from shops you follow" pieces for one person (review
// items D-4 and A-6). It reads their follows, measurements, chosen styles
// and wardrobe counts, fetches recent stock from the shops and designers
// they follow, and runs the matching rules in models/feed_matching.dart.
//
// Runs on the phone for now. A server job could do the same when a shop adds
// stock, so the cards are ready before the app opens.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/body_profile.dart';
import '../models/feed_matching.dart';
import 'body_profile_service.dart';
import 'friend_service.dart';

/// One piece to show, with the product data the card and product page need.
class FeedItem {
  const FeedItem({required this.product, required this.match});

  final Map<String, dynamic> product;
  final FeedMatch match;
}

/// Firestore's `whereIn` takes at most this many values.
const int kWhereInLimit = 30;

/// Pieces fetched per group of followed shops.
const int kStockPerBatch = 60;

/// Splits [ids] into groups Firestore will accept in one `whereIn`.
List<List<String>> batchesOf(Iterable<String> ids, [int size = kWhereInLimit]) {
  final list = ids.toList();
  return [
    for (var i = 0; i < list.length; i += size)
      list.sublist(i, i + size > list.length ? list.length : i + size),
  ];
}

/// How many wardrobe items the person owns, by lower-case category.
Map<String, int> ownedCounts(Iterable<Map<String, dynamic>> wardrobe) {
  final counts = <String, int>{};
  for (final item in wardrobe) {
    final category = (item['category'] ?? '').toString().trim().toLowerCase();
    if (category.isNotEmpty) counts[category] = (counts[category] ?? 0) + 1;
  }
  return Map.unmodifiable(counts);
}

/// What the feed strip needs; the real one reads Firestore, tests use a fake.
abstract interface class FeedSource {
  Future<List<FeedItem>> loadToday(String userId);
  Future<void> dismiss(String userId, String productId);
}

class FeedMatchesService implements FeedSource {
  FeedMatchesService({
    FirebaseFirestore? db,
    FriendService? friends,
    Future<BodyProfile> Function()? loadBody,
  }) : _db = db ?? FirebaseFirestore.instance,
       _friends = friends ?? FriendService(),
       _loadBody = loadBody ?? BodyProfileService().loadForCurrentUser;

  final FirebaseFirestore _db;
  final FriendService _friends;
  final Future<BodyProfile> Function() _loadBody;

  CollectionReference<Map<String, dynamic>> _dismissed(String userId) =>
      _db.collection('users').doc(userId).collection('feedDismissed');

  /// Today's pieces for [userId], best first (at most [kDailyFeedCards]).
  @override
  Future<List<FeedItem>> loadToday(String userId) async {
    if (userId.isEmpty) return const [];
    final followed = (await _friends.getFollowingIds().first).toSet();
    if (followed.isEmpty) return const [];

    final userDoc = await _db.collection('users').doc(userId).get();
    final rawStyles = userDoc.data()?['stylePreferences'];
    final styles = rawStyles is Iterable
        ? rawStyles.map((style) => style.toString()).toList()
        : const <String>[];

    final wardrobe = await _db
        .collection('user_products')
        .where('userId', isEqualTo: userId)
        .get();
    final dismissed = await _dismissed(userId).get();
    final body = await _loadBody();

    final stock = <Map<String, dynamic>>[];
    for (final batch in batchesOf(followed)) {
      final snapshot = await _db
          .collection('products')
          .where('uploaderId', whereIn: batch)
          .limit(kStockPerBatch)
          .get();
      for (final doc in snapshot.docs) {
        stock.add({...doc.data(), 'id': doc.id});
      }
    }

    final shopper = ShopperProfile(
      userId: userId,
      body: body,
      styles: styles,
      ownedByCategory: ownedCounts(wardrobe.docs.map((doc) => doc.data())),
      followedSellerIds: followed,
    );
    final matches = pickDailyMatches(
      stock,
      shopper,
      alreadyShown: {for (final doc in dismissed.docs) doc.id},
    );
    final byId = {
      for (final product in stock) product['id'] as String: product,
    };
    return [
      for (final match in matches)
        FeedItem(product: byId[match.productId]!, match: match),
    ];
  }

  /// "Not for me": this piece will not come back.
  @override
  Future<void> dismiss(String userId, String productId) => _dismissed(
    userId,
  ).doc(productId).set({'dismissedAt': FieldValue.serverTimestamp()});
}
