// Stores completed avatar outfits for the signed-in user, and the plans built
// from them (wear history, event plans, packing lists).
//
// Outfits are rows in `outfits`; the rest are private documents in
// `user_documents`, keyed by kind. Screens read them as plain maps with an
// `id` and camelCase fields, dates as ISO strings (see asDateTime).
import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/core/supabase/storage_files.dart' show randomFileName;

const String _wearHistory = 'wearHistory';
const String _eventPlans = 'eventPlans';
const String _packingLists = 'packingLists';
const String _eventDays = 'eventDays';

class OutfitService {
  /// An `outfits` row as the screens read it.
  static Map<String, dynamic> outfitMap(Map<String, dynamic> row) {
    final data = camelizeRow(row);
    final extra = data['data'];
    return {
      if (extra is Map) ...Map<String, dynamic>.from(extra),
      ...data,
      'imageUrl': data['imageUrl'],
    };
  }

  /// A private document as the screens read it.
  static Map<String, dynamic> documentMap(Map<String, dynamic> row) {
    final data = row['data'];
    return {
      if (data is Map) ...Map<String, dynamic>.from(data),
      'id': row['id'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    };
  }

  Stream<List<Map<String, dynamic>>> watchSavedOutfits(String userId) {
    return supabase
        .from('outfits')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) => [for (final row in rows) outfitMap(row)]);
  }

  Stream<List<Map<String, dynamic>>> _watchDocuments(
    String userId,
    String kind,
  ) {
    return supabase
        .from('user_documents')
        .stream(primaryKey: ['user_id', 'kind', 'id'])
        .eq('user_id', userId)
        .map(
          (rows) => [
            for (final row in rows)
              if (row['kind'] == kind) documentMap(row),
          ],
        );
  }

  Stream<List<Map<String, dynamic>>> watchWearHistory(String userId) =>
      _watchDocuments(userId, _wearHistory);

  Stream<List<Map<String, dynamic>>> watchEventPlans(String userId) =>
      _watchDocuments(userId, _eventPlans);

  Stream<List<Map<String, dynamic>>> watchPackingLists(String userId) =>
      _watchDocuments(userId, _packingLists);

  Future<void> _saveDocument(
    String userId,
    String kind,
    String id,
    Map<String, dynamic> data,
  ) async {
    await supabase.from('user_documents').upsert({
      'user_id': userId,
      'kind': kind,
      'id': id,
      'data': data,
    });
  }

  Future<Map<String, dynamic>> _readDocument(
    String userId,
    String kind,
    String id,
  ) async {
    final row = await supabase
        .from('user_documents')
        .select('data')
        .eq('user_id', userId)
        .eq('kind', kind)
        .eq('id', id)
        .maybeSingle();
    final data = row?['data'];
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  static String _dayString(DateTime date) =>
      DateTime(date.year, date.month, date.day).toIso8601String();

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _newId() => randomFileName('x').split('.').first;

  Future<String> createEventPlan({
    required String userId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final id = _newId();
    await _saveDocument(userId, _eventPlans, id, {
      'name': name.trim(),
      'startDate': _dayString(startDate),
      'endDate': _dayString(endDate),
    });
    return id;
  }

  Future<String> createPackingList({
    required String userId,
    required String name,
    required List<String> outfitIds,
    required List<String> itemNames,
  }) async {
    final id = _newId();
    await _saveDocument(userId, _packingLists, id, {
      'name': name.trim(),
      'outfitIds': outfitIds,
      'items': itemNames
          .map((item) => {'name': item.trim(), 'packed': false})
          .where((item) => (item['name'] as String).isNotEmpty)
          .toList(),
      'checkedItems': <String>[],
    });
    return id;
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
    final existing = await _readDocument(userId, _packingLists, packingListId);
    await _saveDocument(userId, _packingLists, packingListId, {
      ...existing,
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
    });
  }

  Future<void> _addPlannedOutfit(
    String userId,
    String eventId,
    String outfitId,
  ) async {
    final plan = await _readDocument(userId, _eventPlans, eventId);
    final planned = {
      ...((plan['plannedOutfitIds'] as List?)?.map((e) => e.toString()) ??
          const <String>[]),
      outfitId,
    }.toList();
    await _saveDocument(userId, _eventPlans, eventId, {
      ...plan,
      'plannedOutfitIds': planned,
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
    final dateKey = _dateKey(date);
    final data = {
      'userId': userId,
      'outfitId': outfitId,
      'wearDate': _dayString(date),
      'outfitName': (outfit['name'] ?? 'Completed Look').toString(),
      'imageUrl': (outfit['imageUrl'] ?? '').toString(),
      'avatarImageUrl': (outfit['avatarImageUrl'] ?? '').toString(),
      'products': outfit['products'] is Iterable
          ? List<dynamic>.from(outfit['products'])
          : const [],
      'eventId': ?eventId,
      'eventName': ?eventName,
      'reusedAt': DateTime.now().toUtc().toIso8601String(),
    };
    await _saveDocument(userId, _wearHistory, dateKey, data);
    if (eventId != null) {
      await _saveDocument(userId, _eventDays, '$eventId/$dateKey', data);
      await _addPlannedOutfit(userId, eventId, outfitId);
    }
  }

  /// Keeps the turned-around angles with a saved look ("Turn me around").
  Future<void> saveTurnViews({
    required String userId,
    required String outfitId,
    required Map<String, String> views,
  }) async {
    await supabase
        .from('outfits')
        .update({'turn_views': views})
        .eq('id', outfitId)
        .eq('user_id', userId);
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
    final dateKey = _dateKey(date);
    final productSnapshots = products.map(_productSnapshot).toList();
    final row = await supabase
        .from('outfits')
        .insert({
          'user_id': userId,
          'name': 'Planned Look',
          'avatar_image_url': avatarImageUrl,
          'image_url': resultImageUrl,
          'products': productSnapshots,
          'preview_type': previewType,
          'planned_date': dateKey,
          'event_id': eventId,
          'event_name': eventName,
          if (turnViews.isNotEmpty) 'turn_views': turnViews,
          'data': {'apiIntegrationStatus': _integrationStatus(previewType)},
        })
        .select('id')
        .single();
    final outfitId = row['id'].toString();

    await _saveDocument(userId, _wearHistory, dateKey, {
      'userId': userId,
      'outfitId': outfitId,
      'wearDate': _dayString(date),
      'outfitName': 'Planned Look',
      'imageUrl': resultImageUrl,
      'avatarImageUrl': avatarImageUrl,
      'products': productSnapshots,
      'planned': true,
      'eventId': ?eventId,
      'eventName': ?eventName,
      'reusedAt': DateTime.now().toUtc().toIso8601String(),
    });
    if (eventId != null) {
      await _saveDocument(userId, _eventDays, '$eventId/$dateKey', {
        'outfitId': outfitId,
        'wearDate': _dayString(date),
        'outfitName': 'Planned Look',
        'imageUrl': resultImageUrl,
        'products': productSnapshots,
      });
      await _addPlannedOutfit(userId, eventId, outfitId);
    }
    return outfitId;
  }

  static String _integrationStatus(String previewType) =>
      previewType == 'mock_collage' ? 'pending_replacement' : 'generated';

  Future<String> saveOutfit({
    required String userId,
    required String avatarImageUrl,
    required String resultImageUrl,
    required List<Map<String, dynamic>> products,
    String previewType = 'generated',
  }) async {
    final row = await supabase
        .from('outfits')
        .insert({
          'user_id': userId,
          'name': 'Completed Look',
          'avatar_image_url': avatarImageUrl,
          'image_url': resultImageUrl,
          'products': products.map(_productSnapshot).toList(),
          'preview_type': previewType,
          'data': {'apiIntegrationStatus': _integrationStatus(previewType)},
        })
        .select('id')
        .single();
    return row['id'].toString();
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
    final productSnapshots = products.map(_productSnapshot).toList();
    final productIds = productSnapshots
        .map((product) => product['id'].toString())
        .where((id) => id.isNotEmpty)
        .toList();

    final outfit = await supabase
        .from('outfits')
        .insert({
          'user_id': userId,
          'name': 'Completed Look',
          'avatar_image_url': avatarImageUrl,
          'image_url': resultImageUrl,
          'products': productSnapshots,
          'preview_type': previewType,
          if (turnViews.isNotEmpty) 'turn_views': turnViews,
          'data': {'apiIntegrationStatus': _integrationStatus(previewType)},
        })
        .select('id')
        .single();
    final outfitId = outfit['id'].toString();

    final post = await supabase
        .from('posts')
        .insert({
          'author_id': userId,
          'caption': caption.trim().isEmpty
              ? 'My completed try-on look'
              : caption.trim(),
          'image_url': resultImageUrl,
          'visibility': 'private',
          'outfit_id': outfitId,
          'product_ids': productIds,
          'products': productSnapshots,
        })
        .select('id')
        .single();
    await supabase
        .from('outfits')
        .update({'daily_dress_up_post_id': post['id']})
        .eq('id', outfitId);
    return outfitId;
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
    await supabase.from('outfits').upsert({
      'user_id': userId,
      'source_post_id': postId,
      'name': name,
      'avatar_image_url': imageUrl,
      'image_url': imageUrl,
      'products': products.map(_productSnapshot).toList(),
      'preview_type': 'saved_post',
      'data': {'apiIntegrationStatus': 'generated'},
    }, onConflict: 'user_id,source_post_id');
  }

  /// Ids of the feed posts this user has saved to their Smart Wardrobe.
  Stream<Set<String>> watchSavedPostIds(String userId) {
    return supabase
        .from('outfits')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map(
          (rows) => {
            for (final row in rows)
              if (row['preview_type'] == 'saved_post' &&
                  row['source_post_id'] != null)
                row['source_post_id'].toString(),
          },
        );
  }

  /// Files a saved feed look under [category] in Smart Wardrobe › Saved
  /// Looks. An empty category clears it.
  Future<void> setSavedLookCategory({
    required String userId,
    required String postId,
    required String category,
  }) async {
    await supabase
        .from('outfits')
        .update({'category': category.trim()})
        .eq('user_id', userId)
        .eq('source_post_id', postId);
  }

  /// Moves any saved look (from a feed post or a makeover) to [category]; an
  /// empty one clears it.
  Future<void> setOutfitCategory({
    required String userId,
    required String outfitId,
    required String category,
  }) async {
    await supabase
        .from('outfits')
        .update({'category': category.trim()})
        .eq('id', outfitId)
        .eq('user_id', userId);
  }

  /// The categories the user has already filed saved looks under, A to Z.
  Future<List<String>> savedLookCategories(String userId) async {
    final rows = await supabase
        .from('outfits')
        .select('category')
        .eq('user_id', userId);
    final names = {
      for (final row in rows)
        if ((row['category'] ?? '').toString().trim() case final String name
            when name.isNotEmpty)
          name,
    }.toList()..sort();
    return List.unmodifiable(names);
  }

  Future<void> removeLookFromWardrobe({
    required String userId,
    required String postId,
  }) async {
    await supabase
        .from('outfits')
        .delete()
        .eq('user_id', userId)
        .eq('source_post_id', postId);
  }

  Future<void> shareOutfitAsPost({
    required String userId,
    required String outfitId,
    required String resultImageUrl,
    required String caption,
    required List<Map<String, dynamic>> products,
  }) async {
    await supabase.from('posts').insert({
      'author_id': userId,
      'caption': caption,
      'image_url': resultImageUrl,
      'visibility': 'private',
      'outfit_id': outfitId,
      'product_ids': products
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
