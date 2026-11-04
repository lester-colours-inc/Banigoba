// Coordinates catalog and wardrobe product storage, queries, updates, and uploads.
//
// Shop pieces live in `products` (open to read, written by the shop that owns
// them); a person's own pieces and saved catalogue pieces live in
// `user_products`, private unless marked public. Screens read both as plain
// maps with an `id` and camelCase fields.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/supabase/app_auth.dart';
import '../../core/supabase/supabase_config.dart';
import '../models/piece_details.dart';
import '../supabase/rows.dart';
import '../supabase/storage_files.dart';
import 'notification_service.dart';

/// Columns of `products` that fields map onto; anything else is kept in the
/// row's free-form `data`.
const Set<String> _productColumns = {
  'name',
  'description',
  'category',
  'subcategory',
  'price',
  'stock',
  'size_inventory',
  'colours',
  'gender',
  'image_url',
  'raw_image_url',
  'extra_image_urls',
  'style_tag',
  'weather_tags',
  'functional_tags',
  'user_id',
};

/// Columns of `user_products`.
const Set<String> _userProductColumns = {
  'user_id',
  'name',
  'category',
  'subcategory',
  'style_tag',
  'colours',
  'gender',
  'size',
  'weather_tags',
  'functional_tags',
  'image_url',
  'raw_image_url',
  'visibility',
};

const Map<String, String> _imageAliases = {
  'imageURL': 'image_url',
  'imageUrl': 'image_url',
  'rawImageUrl': 'raw_image_url',
  'uploaderId': 'user_id',
  'userId': 'user_id',
};

/// A `products` or `user_products` row as the screens read it.
Map<String, dynamic> productMap(Map<String, dynamic> row) {
  final flat = flattenRow(row);
  return {
    ...flat,
    'id': row['id'].toString(),
    'uploaderId': row['user_id']?.toString(),
    'userId': row['user_id']?.toString(),
    'imageURL': flat['imageUrl'],
  };
}

/// Service handling all product-related operations.
class ProductService {
  final _notificationService = NotificationService();

  static const String _bgRemoverUrl =
      'https://banigoba-image-background-remover.onrender.com/process';

  /// Process image with background remover API
  /// Returns a map with 'raw_url' and 'processed_url'
  Future<Map<String, String>> removeBackground(
    File imageFile, {
    String? customFilename,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(_bgRemoverUrl));

    // Sanitize customFilename and ensure it has an extension
    String filename = imageFile.path.split('/').last;
    if (customFilename != null && customFilename.trim().isNotEmpty) {
      filename =
          "${customFilename.trim().replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_')}.jpg";
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: filename,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      debugPrint("DEBUG: BG Remover API Response Body: ${response.body}");
      final Map<String, dynamic> data = json.decode(response.body);

      // Try multiple possible key names
      final String rawUrl =
          data['rawUrl'] ??
          data['raw_url'] ??
          data['rawImageUrl'] ??
          data['raw'] ??
          data['url_raw'] ??
          '';
      final String processedUrl =
          data['processedUrl'] ??
          data['processed_url'] ??
          data['processedImageUrl'] ??
          data['processed'] ??
          data['url_processed'] ??
          '';

      // Debug API returned URL values
      debugPrint("DEBUG: BG Remover API Raw URL: $rawUrl");
      debugPrint("DEBUG: BG Remover API Processed URL: $processedUrl");

      if (processedUrl.isEmpty) {
        throw Exception('Background remover returned no processed image URL');
      }

      return _storeProductImages(
        sourceImage: imageFile,
        processedImageUrl: processedUrl,
        customFilename: customFilename,
      );
    } else {
      throw Exception(
        'Failed to process image: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Copies raw and processed images into the product-images bucket.
  Future<Map<String, String>> _storeProductImages({
    required File sourceImage,
    required String processedImageUrl,
    String? customFilename,
  }) async {
    final userId = AppAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw Exception('You must be signed in to upload product images');
    }

    final safeName = _safeStorageName(customFilename);
    final directory = '$userId/${DateTime.now().millisecondsSinceEpoch}';

    final rawUrl = await StorageFiles.upload(
      bucket: Buckets.productImages,
      path: '$directory/${safeName}_raw.jpg',
      bytes: await sourceImage.readAsBytes(),
    );

    final processedResponse = await http.get(Uri.parse(processedImageUrl));
    if (processedResponse.statusCode < 200 ||
        processedResponse.statusCode >= 300) {
      throw Exception(
        'Unable to download processed image: ${processedResponse.statusCode}',
      );
    }

    final processedContentType =
        processedResponse.headers['content-type']?.split(';').first ??
        'image/png';
    final processedExtension = processedContentType.contains('jpeg')
        ? 'jpg'
        : 'png';
    final processedUrlStored = await StorageFiles.upload(
      bucket: Buckets.productImages,
      path: '$directory/${safeName}_processed.$processedExtension',
      bytes: processedResponse.bodyBytes,
      contentType: processedContentType,
    );
    debugPrint('Product images stored: $directory');

    return {'raw_url': rawUrl, 'processed_url': processedUrlStored};
  }

  String _safeStorageName(String? value) {
    final normalized = (value ?? 'product')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'product' : normalized;
  }

  /// Every shop piece, live.
  Stream<List<Map<String, dynamic>>> getProducts() {
    return supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .map((rows) => [for (final row in rows) productMap(row)]);
  }

  Future<List<Map<String, dynamic>>> getCatalogProducts() async {
    final rows = await supabase.from('products').select();
    return _forTryOn(rows, 'catalog');
  }

  /// The signed-in user's own wardrobe pieces.
  Future<List<Map<String, dynamic>>> getWardrobeProducts(String userId) async {
    final rows = await supabase
        .from('user_products')
        .select()
        .eq('user_id', userId);
    return _forTryOn(rows, 'wardrobe');
  }

  List<Map<String, dynamic>> _forTryOn(
    List<Map<String, dynamic>> rows,
    String source,
  ) {
    return [
      for (final row in rows) {...productMap(row), 'tryOnSource': source},
    ].where((product) => _tryOnImageUrl(product).isNotEmpty).toList();
  }

  /// Load products that can be selected for avatar try-on.
  ///
  /// Catalog products and the user's wardrobe are queried independently so a
  /// permission or connectivity failure in one source does not empty the picker.
  Future<List<Map<String, dynamic>>> getTryOnProducts(String userId) async {
    Future<List<Map<String, dynamic>>> load(
      Future<List<Map<String, dynamic>>> query,
      String source,
    ) async {
      try {
        final rows = await query;
        return [
          for (final row in rows) {...productMap(row), 'tryOnSource': source},
        ];
      } catch (error) {
        debugPrint('Unable to load $source products for try-on: $error');
        return <Map<String, dynamic>>[];
      }
    }

    final results = await Future.wait([
      load(supabase.from('products').select(), 'catalog'),
      load(
        supabase.from('user_products').select().eq('user_id', userId),
        'wardrobe',
      ),
      load(
        supabase.from('user_products').select().eq('visibility', 'public'),
        'community',
      ),
    ]);

    final products = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final sourceProducts in results) {
      for (final product in sourceProducts) {
        final imageUrl = _tryOnImageUrl(product);
        if (imageUrl.isEmpty) continue;

        final originalId = (product['originalProductId'] ?? '').toString();
        final id = (product['id'] ?? '').toString();
        final key = originalId.isNotEmpty
            ? 'product:$originalId'
            : imageUrl.isNotEmpty
            ? 'image:$imageUrl'
            : 'id:$id';
        if (seen.add(key)) products.add(product);
      }
    }
    return products;
  }

  String _tryOnImageUrl(Map<String, dynamic> product) {
    const imageFields = [
      'rawImageUrl',
      'imageUrl',
      'imageURL',
      'processedImageUrl',
      'processed_url',
      'raw_url',
    ];
    for (final field in imageFields) {
      final value = product[field];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  /// Get products filtered by weather tags
  Stream<List<Map<String, dynamic>>> getRecommendedProducts(List<String> tags) {
    if (tags.isEmpty) return getProducts();
    return getProducts().map(
      (products) => [
        for (final product in products)
          if ((product['weatherTags'] as List? ?? const []).any(
            (tag) => tags.contains(tag),
          ))
            product,
      ],
    );
  }

  /// Get product recommendations that match weather first, then user style.
  Stream<List<Map<String, dynamic>>> getRecommendedProductDocs({
    List<String> weatherTags = const [],
    String? stylePreference,
  }) {
    final normalizedStyle = (stylePreference ?? '').toLowerCase().trim();
    return getRecommendedProducts(weatherTags).map((products) {
      if (normalizedStyle.isEmpty || normalizedStyle == 'all') {
        return products;
      }
      return products.where((data) {
        final productStyle = (data['styleTag'] ?? data['style'] ?? 'casual')
            .toString()
            .toLowerCase()
            .trim();
        return productStyle == normalizedStyle;
      }).toList();
    });
  }

  /// Get stream of products added by a specific admin
  Stream<List<Map<String, dynamic>>> getAdminProducts(String adminId) {
    return supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('user_id', adminId)
        .map((rows) => [for (final row in rows) productMap(row)]);
  }

  /// Add a new product to the main products collection
  Future<void> addProduct(Map<String, dynamic> product) async {
    final userId = AppAuth.instance.currentUser?.uid;
    final row = toStoredRow(
      {'userId': userId, ...product},
      columns: _productColumns,
      aliases: _imageAliases,
    );
    await supabase.from('products').insert(row);
  }

  /// Update an existing catalog product. A field set to [kRemoveField] is
  /// cleared.
  Future<void> updateCatalogProduct(
    String productId,
    Map<String, dynamic> updatedData,
  ) async {
    final removed = {
      for (final entry in updatedData.entries)
        if (identical(entry.value, kRemoveField)) entry.key,
    };
    final row = toStoredRow(
      {
        for (final entry in updatedData.entries)
          if (!removed.contains(entry.key)) entry.key: entry.value,
      },
      columns: _productColumns,
      aliases: _imageAliases,
    )..remove('user_id');
    if (removed.contains('sizeInventory')) row['size_inventory'] = {};
    final extra = row.remove('data');
    final dropped = removed.difference({'sizeInventory'});
    if ((extra is Map && extra.isNotEmpty) || dropped.isNotEmpty) {
      final current = await supabase
          .from('products')
          .select('data')
          .eq('id', productId)
          .maybeSingle();
      final merged = {
        ...Map<String, dynamic>.from(current?['data'] as Map? ?? {}),
        if (extra is Map) ...Map<String, dynamic>.from(extra),
      }..removeWhere((key, _) => dropped.contains(key));
      row['data'] = merged;
    }
    if (row.isEmpty) return;
    await supabase.from('products').update(row).eq('id', productId);
  }

  /// Sets how many of a piece are left, without touching anything else. A
  /// piece with sizes takes a count per size (and its total becomes the
  /// stock); a one-size piece takes a single count.
  Future<void> updateStock(
    String productId, {
    Map<String, int>? sizeInventory,
    int? stock,
  }) async {
    if (sizeInventory == null && stock == null) return;
    final total = sizeInventory == null
        ? stock!
        : sizeInventory.values.fold<int>(0, (sum, count) => sum + count);
    await supabase
        .from('products')
        .update({
          'stock': total < 0 ? 0 : total,
          if (sizeInventory != null) 'size_inventory': sizeInventory,
        })
        .eq('id', productId);
  }

  /// Uploads a catalogue photo from its bytes (quick add) and returns its
  /// public URL.
  Future<String> uploadCatalogProductImageBytes({
    required String userId,
    required Uint8List bytes,
    String? customFilename,
  }) {
    if (userId.isEmpty) {
      throw Exception('You must be signed in to upload product images');
    }
    return StorageFiles.upload(
      bucket: Buckets.productImages,
      path:
          '$userId/${DateTime.now().millisecondsSinceEpoch}_${_safeStorageName(customFilename)}.jpg',
      bytes: bytes,
    );
  }

  /// Delete a product from the main products collection
  Future<void> deleteProduct(String productId) async {
    await supabase.from('products').delete().eq('id', productId);
  }

  /// Upload a user product image
  Future<String> uploadProductImage(String userId, File image) {
    return StorageFiles.upload(
      bucket: Buckets.userImages,
      path: '$userId/user_products/${randomFileName()}',
      bytes: image.readAsBytesSync(),
    );
  }

  /// Upload a seller catalog product image.
  Future<String> uploadCatalogProductImage({
    required String userId,
    required File image,
    String? customFilename,
  }) async {
    if (userId.isEmpty) {
      throw Exception('You must be signed in to upload product images');
    }

    final safeName = _safeStorageName(customFilename);
    final path =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_$safeName.jpg';
    debugPrint('[ProductUpload] Starting catalog image upload: $path');

    try {
      final bytes = await image.readAsBytes();
      final url = await StorageFiles.upload(
        bucket: Buckets.productImages,
        path: path,
        bytes: bytes,
      );
      debugPrint('[ProductUpload] Uploaded ${bytes.length} bytes');
      return url;
    } catch (error, stackTrace) {
      debugPrint('[ProductUpload] Catalog image upload failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Upload a user's own product to their wardrobe (and the community list
  /// when it is public).
  Future<void> uploadUserProduct({
    required String userId,
    required String name,
    required String imageUrl,
    required String visibility,
    String? rawImageUrl,
    String? category,
    String? subcategory,
    String? styleTag,
    String? colour,
    List<String>? colours,
    String? gender,
    List<String>? weatherTags,
    List<String>? functionalTags,
    String size = '',
    PieceDetails details = const PieceDetails(),
  }) async {
    // Flatten colours into a single list
    List<String> finalColours = [];
    if (colours != null) {
      finalColours.addAll(colours.whereType<String>());
    } else if (colour != null) {
      finalColours.add(colour);
    }

    final data = {
      'userId': userId,
      'name': name,
      'imageUrl': imageUrl,
      'rawImageUrl': rawImageUrl,
      'category': category,
      'subcategory': subcategory,
      'styleTag': styleTag ?? 'casual',
      'colours': finalColours,
      'gender': gender,
      'weatherTags': weatherTags ?? [],
      'functionalTags': functionalTags ?? [],
      if (size.trim().isNotEmpty) 'size': size.trim(),
      ...details.toMap(),
      'visibility': visibility,
    };

    await supabase
        .from('user_products')
        .insert(
          toStoredRow(
            data,
            columns: _userProductColumns,
            aliases: _imageAliases,
          ),
        );
    if (visibility == 'public') {
      await _notificationService.notifyFollowersNewPost(name);
    }
  }

  /// Get stream of items uploaded by a specific user
  Stream<List<Map<String, dynamic>>> getUserProducts(String userId) {
    return supabase
        .from('user_products')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) => [for (final row in rows) productMap(row)]);
  }

  /// Records that the owner wore this wardrobe item today (W-7).
  Future<void> markUserProductWorn(String userProductId) async {
    final row = await supabase
        .from('user_products')
        .select('data')
        .eq('id', userProductId)
        .maybeSingle();
    final data = Map<String, dynamic>.from(row?['data'] as Map? ?? {});
    final count = (data['wearCount'] as num?)?.toInt() ?? 0;
    await supabase
        .from('user_products')
        .update({
          'data': {
            ...data,
            'lastWornAt': DateTime.now().toUtc().toIso8601String(),
            'wearCount': count + 1,
          },
        })
        .eq('id', userProductId);
  }

  /// Puts a wardrobe piece in one of the owner's collections ('' takes it
  /// out of any collection).
  Future<void> setCollection(String userProductId, String collection) async {
    final row = await supabase
        .from('user_products')
        .select('data')
        .eq('id', userProductId)
        .maybeSingle();
    final data = Map<String, dynamic>.from(row?['data'] as Map? ?? {});
    final name = collection.trim();
    if (name.isEmpty) {
      data.remove('collection');
    } else {
      data['collection'] = name;
    }
    await supabase
        .from('user_products')
        .update({'data': data})
        .eq('id', userProductId);
  }

  /// Delete a user's uploaded product.
  Future<void> deleteUserProduct(String userId, String userProductId) async {
    await supabase
        .from('user_products')
        .delete()
        .eq('id', userProductId)
        .eq('user_id', userId);
  }

  /// Update an existing user product
  Future<void> updateUserProduct({
    required String userProductId,
    required String userId,
    required Map<String, dynamic> updatedData,
  }) async {
    final row = toStoredRow(
      updatedData,
      columns: _userProductColumns,
      aliases: _imageAliases,
    )..remove('user_id');
    final extra = row.remove('data');
    if (extra is Map && extra.isNotEmpty) {
      final current = await supabase
          .from('user_products')
          .select('data')
          .eq('id', userProductId)
          .maybeSingle();
      row['data'] = {
        ...Map<String, dynamic>.from(current?['data'] as Map? ?? {}),
        ...Map<String, dynamic>.from(extra),
      };
    }
    if (row.isEmpty) return;
    await supabase
        .from('user_products')
        .update(row)
        .eq('id', userProductId)
        .eq('user_id', userId);
  }

  /// Toggle a catalogue piece in the user's wardrobe (save/remove). A saved
  /// piece is a `user_products` row remembering which catalogue piece it came
  /// from.
  Future<void> toggleWardrobeItem({
    required String userId,
    required String productId,
    required Map<String, dynamic> productData,
  }) async {
    final existing = await supabase
        .from('user_products')
        .select('id')
        .eq('user_id', userId)
        .eq('data->>originalProductId', productId);

    if (existing.isNotEmpty) {
      await supabase
          .from('user_products')
          .delete()
          .eq('user_id', userId)
          .eq('data->>originalProductId', productId);
      return;
    }

    // Flatten colour data
    List<String> finalColours = [];
    final dynamic rawColours = productData['colours'];
    final dynamic rawColour = productData['colour'];

    if (rawColours is List) {
      for (var item in rawColours) {
        if (item is String) {
          finalColours.add(item);
        } else if (item is List) {
          finalColours.addAll(item.whereType<String>());
        }
      }
    } else if (rawColours != null) {
      finalColours.add(rawColours.toString());
    } else if (rawColour != null) {
      if (rawColour is List) {
        finalColours.addAll(rawColour.whereType<String>());
      } else {
        finalColours.add(rawColour.toString());
      }
    }

    final data = {
      'userId': userId,
      'originalProductId': productId,
      'originalPosterId': productData['userId'] ?? productData['uploaderId'],
      'name': productData['name'] ?? 'No Name',
      'imageUrl': productData['imageUrl'] ?? productData['imageURL'] ?? '',
      'rawImageUrl':
          productData['rawImageUrl'] ??
          productData['imageUrl'] ??
          productData['imageURL'] ??
          '',
      'category': productData['category'] ?? 'other',
      'subcategory': productData['subcategory'] ?? '',
      'styleTag': productData['styleTag'] ?? productData['style'] ?? 'casual',
      'colours': finalColours,
      'gender': productData['gender'] ?? 'unisex',
      'weatherTags': productData['weatherTags'] ?? [],
      'functionalTags': productData['functionalTags'] ?? [],
      'visibility': 'public',
    };
    await supabase
        .from('user_products')
        .insert(
          toStoredRow(
            data,
            columns: _userProductColumns,
            aliases: _imageAliases,
          ),
        );
  }

  /// Check if a catalogue piece is currently in the user's wardrobe
  Stream<bool> isInWardrobe(String userId, String productId) {
    return supabase
        .from('user_products')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map(
          (rows) => rows.any((row) {
            final data = row['data'];
            return row['id'].toString() == productId ||
                (data is Map && data['originalProductId'] == productId);
          }),
        );
  }

  /// Helper to fetch unique values for a field (e.g. all available categories)
  Future<List<String>> getUniqueValues(String field) async {
    try {
      final rows = await supabase.from('products').select();
      final Set<String> uniqueValues = {'all'};
      for (final row in rows) {
        final data = productMap(row);
        if (data.containsKey(field) && data[field] != null) {
          final dynamic val = data[field];
          if (val is List) {
            for (var item in val) {
              if (item != null) {
                uniqueValues.add(item.toString().toLowerCase().trim());
              }
            }
          } else {
            uniqueValues.add(val.toString().toLowerCase().trim());
          }
        }
      }
      List<String> sortedList = uniqueValues
          .where((s) => s.isNotEmpty)
          .toList();
      sortedList.sort((a, b) {
        if (a == 'all') return -1;
        if (b == 'all') return 1;
        return a.compareTo(b);
      });
      return sortedList;
    } catch (e) {
      debugPrint("Error fetching unique values for $field: $e");
      return ['all'];
    }
  }

  /// General app settings/metadata (catalogue filter facets).
  Stream<Map<String, dynamic>> getAppMetadata() {
    return supabase
        .from('catalog_metadata')
        .stream(primaryKey: ['id'])
        .eq('id', 'settings')
        .map(
          (rows) => rows.isEmpty
              ? const <String, dynamic>{}
              : Map<String, dynamic>.from(rows.first['data'] as Map? ?? {}),
        );
  }
}
