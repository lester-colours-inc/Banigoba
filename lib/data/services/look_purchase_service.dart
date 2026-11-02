// Loads what "Get this look" needs for one person (K-4, A-7): their
// wardrobe, size, chosen styles, and stock from verified shops, then runs the
// matching in models/look_purchase.dart.
import '../../core/supabase/supabase_config.dart';

import '../models/body_profile.dart';
import '../models/feed_matching.dart';
import '../models/look_purchase.dart';
import '../models/look_request.dart';
import 'body_profile_service.dart';
import 'feed_matches_service.dart';
import 'product_service.dart' show productMap;

/// What the sheet needs; the real one reads the database, tests use a fake.
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
  LookPurchaseService({Future<BodyProfile> Function()? loadBody})
    : _loadBody = loadBody ?? BodyProfileService().loadForCurrentUser;

  final Future<BodyProfile> Function() _loadBody;

  Future<Set<String>> _verifiedSellers(Set<String> sellerIds) async {
    final verified = <String>{};
    for (final batch in batchesOf(sellerIds)) {
      final rows = await supabase
          .from('profiles')
          .select('id')
          .eq('shop_verified', true)
          .inFilter('id', batch);
      for (final row in rows) {
        verified.add(row['id'].toString());
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

    final profile = await supabase
        .from('profiles')
        .select('style_preferences')
        .eq('id', userId)
        .maybeSingle();
    final rawStyles = profile?['style_preferences'];
    final styles = rawStyles is Iterable
        ? rawStyles.map((style) => style.toString()).toList()
        : const <String>[];
    final wardrobe = [
      for (final row in await supabase
          .from('user_products')
          .select()
          .eq('user_id', userId))
        productMap(row),
    ];
    final body = await _loadBody();

    final categories = categoriesToScan(wanted).toList();
    final stock = <Map<String, dynamic>>[];
    for (final batch in batchesOf(categories, 10)) {
      final rows = await supabase
          .from('products')
          .select()
          .inFilter('category', batch)
          .limit(kStockScan);
      for (final row in rows) {
        stock.add(productMap(row));
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
          wardrobe: wardrobe,
          stock: fromVerified,
          body: body,
          styles: styles,
        ),
    ];
  }
}
