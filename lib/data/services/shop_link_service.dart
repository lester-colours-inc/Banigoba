import '../../core/supabase/supabase_config.dart';
import '../models/shop_link.dart';
import '../supabase/rows.dart';
import 'feed_matches_service.dart' show batchesOf;
import 'product_service.dart' show productMap;

/// What the shared-stock screens need; the real one reads the database.
abstract interface class ShopLinkSource {
  Future<ShopLink?> load(String id);

  /// The pieces [link] shows, in the order the shop chose for picked links.
  Future<List<Map<String, dynamic>>> pieces(ShopLink link);
}

/// Pieces shown for an "all stock" or category link.
const int kPiecesPerLink = 60;

class ShopLinkService implements ShopLinkSource {
  ShopLink _read(Map<String, dynamic> row) {
    final data = camelizeRow(row);
    data['createdAt'] = asDateTime(data['createdAt']);
    return ShopLink.fromMap(row['id'].toString(), data);
  }

  Map<String, dynamic> _write(ShopLink link) {
    final map = link.toMap();
    return {
      'owner_id': map['ownerId'],
      'shop_name': map['shopName'],
      'title': map['title'],
      'note': map['note'],
      'scope': map['scope'],
      'category': map['category'] ?? '',
      'product_ids': map['productIds'] ?? <String>[],
      'audience': map['audience'],
      'cover_image_url': map['coverImageUrl'],
      'active': map['active'],
    };
  }

  /// Saves a new link and returns its id. The server then tells the chosen
  /// audience.
  Future<String> create(ShopLink link) async {
    final row = await supabase
        .from('shop_links')
        .insert(_write(link))
        .select('id')
        .single();
    return row['id'].toString();
  }

  /// Opens a link by its id. Works for people who are not signed in: the id
  /// itself is the key.
  @override
  Future<ShopLink?> load(String id) async {
    final row = await supabase.rpc('get_shop_link', params: {'p_id': id});
    if (row is Map<String, dynamic> && row['id'] != null) return _read(row);
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> pieces(ShopLink link) async {
    if (link.scope == ShareScope.items) {
      final found = <String, Map<String, dynamic>>{};
      for (final batch in batchesOf(link.productIds)) {
        final rows = await supabase
            .from('products')
            .select()
            .inFilter('id', batch);
        for (final row in rows) {
          found[row['id'].toString()] = productMap(row);
        }
      }
      return [for (final id in link.productIds) ?found[id]];
    }
    var query = supabase
        .from('products')
        .select()
        .eq('user_id', link.ownerId);
    if (link.scope == ShareScope.category) {
      query = query.eq('category', link.category);
    }
    final rows = await query.limit(kPiecesPerLink);
    return [for (final row in rows) productMap(row)];
  }

  /// The shop's own links, newest first.
  Future<List<ShopLink>> mine(String ownerId) async {
    final rows = await supabase
        .from('shop_links')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return [for (final row in rows) _read(row)];
  }

  /// Public links that are switched on, newest first, for Community.
  Future<List<ShopLink>> publicLinks({int limit = 10}) async {
    final rows = await supabase
        .from('shop_links')
        .select()
        .eq('audience', ShareAudience.public.value)
        .eq('active', true)
        .order('created_at', ascending: false)
        .limit(limit);
    return [for (final row in rows) _read(row)];
  }

  Future<void> setActive(ShopLink link, {required bool active}) async {
    await supabase
        .from('shop_links')
        .update({'active': active})
        .eq('id', link.id);
  }
}
