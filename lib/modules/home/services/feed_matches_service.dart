// Finds today's "new from shops you follow" pieces for one person (review
// items D-4 and A-6). It reads their follows, measurements, chosen styles
// and wardrobe counts, fetches recent stock from the shops and designers
// they follow, and runs the matching rules in models/feed_matching.dart.
//
// Runs on the phone for now. A server job could do the same when a shop adds
// stock, so the cards are ready before the app opens.
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/core/supabase/rows.dart';

import 'package:banigoba/modules/profile_details/models/body_profile.dart';
import 'package:banigoba/modules/home/models/feed_matching.dart';
import 'package:banigoba/modules/profile_details/services/body_profile_service.dart';
import 'package:banigoba/modules/social/services/friend_service.dart';

/// One piece to show, with the product data the card and product page need.
class FeedItem {
  const FeedItem({required this.product, required this.match});

  final Map<String, dynamic> product;
  final FeedMatch match;
}

/// The most values sent in one `in` filter.
const int kWhereInLimit = 30;

/// Pieces fetched per group of followed shops.
const int kStockPerBatch = 60;

/// Splits [ids] into groups small enough for one `in` filter.
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

/// A server-written card counts for this long.
const Duration kServerCardLife = Duration(hours: 24);

/// Today's cards the server wrote (the matchNewStock function), best first and
/// at most [kDailyFeedCards]. Older, malformed or product-less cards are
/// skipped.
List<FeedItem> cardsFromServer(
  Iterable<Map<String, dynamic>> docs,
  DateTime now,
) {
  final cards = <(FeedItem, DateTime)>[];
  for (final doc in docs) {
    final id = (doc['productId'] ?? '').toString();
    final product = doc['product'];
    if (id.isEmpty || product is! Map) continue;
    // A card whose timestamp has not landed yet was written just now.
    final created = asDateTime(doc['createdAt']) ?? now;
    if (now.difference(created) > kServerCardLife) continue;
    final reasons = [
      for (final reason in (doc['reasons'] as List? ?? const []))
        reason.toString(),
    ];
    cards.add((
      FeedItem(
        product: {...Map<String, dynamic>.from(product), 'id': id},
        match: FeedMatch(
          productId: id,
          score: (doc['score'] as num?)?.toInt() ?? 0,
          reasons: reasons.isEmpty ? const ['Available now'] : reasons,
          size: (doc['size'] ?? '').toString(),
        ),
      ),
      created,
    ));
  }
  cards.sort((a, b) {
    final byScore = b.$1.match.score.compareTo(a.$1.match.score);
    return byScore != 0 ? byScore : b.$2.compareTo(a.$2);
  });
  return List.unmodifiable(cards.take(kDailyFeedCards).map((card) => card.$1));
}

/// What the feed strip needs; the real one reads the database, tests use a fake.
abstract interface class FeedSource {
  Future<List<FeedItem>> loadToday(String userId);
  Future<void> dismiss(String userId, String productId);
}

class FeedMatchesService implements FeedSource {
  FeedMatchesService({
    FriendService? friends,
    Future<BodyProfile> Function()? loadBody,
  }) : _friends = friends ?? FriendService(),
       _loadBody = loadBody ?? BodyProfileService().loadForCurrentUser;

  final FriendService _friends;
  final Future<BodyProfile> Function() _loadBody;

  /// The cards the server prepared when a followed shop added stock. Empty
  /// when there are none (or they cannot be read), and the phone works it out
  /// itself instead.
  Future<List<FeedItem>> _serverCards(String userId) async {
    try {
      final rows = await supabase
          .from('feed_cards')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);
      return cardsFromServer([
        for (final row in rows)
          {
            ...Map<String, dynamic>.from(row['data'] as Map? ?? const {}),
            'productId': row['id'],
            'createdAt': row['created_at'],
          },
      ], DateTime.now());
    } on PostgrestException {
      return const [];
    }
  }

  /// Today's pieces for [userId], best first (at most [kDailyFeedCards]).
  @override
  Future<List<FeedItem>> loadToday(String userId) async {
    if (userId.isEmpty) return const [];
    final fromServer = await _serverCards(userId);
    if (fromServer.isNotEmpty) return fromServer;
    final followed = (await _friends.getFollowingIds().first).toSet();
    if (followed.isEmpty) return const [];

    final profile = await supabase
        .from('profiles')
        .select('style_preferences')
        .eq('id', userId)
        .maybeSingle();
    final rawStyles = profile?['style_preferences'];
    final styles = rawStyles is Iterable
        ? rawStyles.map((style) => style.toString()).toList()
        : const <String>[];

    final wardrobe = await supabase
        .from('user_products')
        .select('category')
        .eq('user_id', userId);
    final dismissed = await supabase
        .from('feed_dismissed')
        .select('card_id')
        .eq('user_id', userId);
    final body = await _loadBody();

    final stock = <Map<String, dynamic>>[];
    for (final batch in batchesOf(followed)) {
      final rows = await supabase
          .from('products')
          .select()
          .inFilter('user_id', batch)
          .limit(kStockPerBatch);
      for (final row in rows) {
        stock.add({...camelizeRow(row), 'uploaderId': row['user_id']});
      }
    }

    final shopper = ShopperProfile(
      userId: userId,
      body: body,
      styles: styles,
      ownedByCategory: ownedCounts(wardrobe),
      followedSellerIds: followed,
    );
    final matches = pickDailyMatches(
      stock,
      shopper,
      alreadyShown: {for (final row in dismissed) row['card_id'].toString()},
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
  Future<void> dismiss(String userId, String productId) async {
    await supabase.from('feed_dismissed').upsert({
      'user_id': userId,
      'card_id': productId,
    });
    await supabase
        .from('feed_cards')
        .delete()
        .eq('user_id', userId)
        .eq('id', productId);
  }
}
