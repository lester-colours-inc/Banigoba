import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service handling all product-related operations (Firestore, Storage, Supabase)
class ProductService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _notificationService = NotificationService();

  static const String _bgRemoverUrl = 'https://banigoba-image-background-remover.onrender.com/process';

  /// Process image with background remover API
  /// Returns a map with 'raw_url' and 'processed_url'
  Future<Map<String, String>> removeBackground(File imageFile, {String? customFilename}) async {
    final request = http.MultipartRequest('POST', Uri.parse(_bgRemoverUrl));
    
    // Sanitize customFilename and ensure it has an extension
    String filename = imageFile.path.split('/').last;
    if (customFilename != null && customFilename.trim().isNotEmpty) {
      filename = "${customFilename.trim().replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_')}.jpg";
    }

    request.files.add(await http.MultipartFile.fromPath(
      'file', 
      imageFile.path,
      filename: filename,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      debugPrint("DEBUG: BG Remover API Response Body: ${response.body}");
      final Map<String, dynamic> data = json.decode(response.body);
      
      // Try multiple possible key names
      final String rawUrl = data['rawUrl'] ?? data['raw_url'] ?? data['rawImageUrl'] ?? data['raw'] ?? data['url_raw'] ?? '';
      final String processedUrl = data['processedUrl'] ?? data['processed_url'] ?? data['processedImageUrl'] ?? data['processed'] ?? data['url_processed'] ?? '';

      // Debug API returned URL values
      debugPrint("DEBUG: BG Remover API Raw URL: $rawUrl");
      debugPrint("DEBUG: BG Remover API Processed URL: $processedUrl");

      return {
        'raw_url': rawUrl,
        'processed_url': processedUrl,
      };
    } else {
      throw Exception('Failed to process image: ${response.statusCode} - ${response.body}');
    }
  }

  /// Get stream of all products in the main collection
  Stream<QuerySnapshot> getProducts() {
    return _db.collection('products').snapshots();
  }

  /// Get products filtered by weather tags
  Stream<QuerySnapshot> getRecommendedProducts(List<String> tags) {
    if (tags.isEmpty) return getProducts();
    // Firestore 'array-contains-any' can match any of the provided tags
    return _db.collection('products')
        .where('weatherTags', arrayContainsAny: tags)
        .snapshots();
  }

  /// Get stream of products added by a specific admin
  Stream<QuerySnapshot> getAdminProducts(String adminId) {
    return _db.collection('products')
        .where('uploaderId', isEqualTo: adminId)
        .snapshots();
  }

  /// Add a new product to the main products collection
  Future<void> addProduct(Map<String, dynamic> product) async {
    await _db.collection('products').add(product);
  }

  /// Update an existing catalog product
  Future<void> updateCatalogProduct(String productId, Map<String, dynamic> updatedData) async {
    await _db.collection('products').doc(productId).update(updatedData);
  }

  /// Delete a product from the main products collection
  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  /// Upload a user product image to Firebase Storage
  Future<String> uploadProductImage(String userId, File image) async {
    final ref = _storage.ref().child('user_products').child(userId).child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  /// Upload a user's own product to Firestore and their personal wardrobe
  Future<void> uploadUserProduct({
    required String userId,
    required String name,
    required String imageUrl,
    required String visibility,
    String? rawImageUrl,
    String? category,
    String? subcategory,
    String? colour,
    List<String>? colours,
    String? gender,
    List<String>? weatherTags,
    List<String>? functionalTags,
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
      'colours': finalColours,
      'gender': gender,
      'weatherTags': weatherTags ?? [],
      'functionalTags': functionalTags ?? [],
      'createdAt': FieldValue.serverTimestamp(),
      'visibility': visibility,
    };
    
    // Save to community list and user's private wardrobe tracker
    final docRef = await _db.collection('user_products').add(data);
    if (visibility == 'public') {
      await _notificationService.notifyFollowersNewPost(name);
    }
    await _db.collection('users').doc(userId).collection('wardrobe').doc(docRef.id).set(data);
  }

  /// Get stream of items uploaded by a specific user
  Stream<QuerySnapshot> getUserProducts(String userId) {
    return _db.collection('user_products')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  /// Delete a user's uploaded product from both 'user_products' and their wardrobe tracker
  Future<void> deleteUserProduct(String userId, String userProductId) async {
    // 1. Delete from community/global user_products list
    await _db.collection('user_products').doc(userProductId).delete();
    
    // 2. Delete from user's personal wardrobe tracker
    await _db.collection('users').doc(userId).collection('wardrobe').doc(userProductId).delete();
  }

  /// Update an existing user product
  Future<void> updateUserProduct({
    required String userProductId,
    required String userId,
    required Map<String, dynamic> updatedData,
  }) async {
    // Ensure the uploader ID and other essential fields are preserved/not overwritten incorrectly if needed
    updatedData['updatedAt'] = FieldValue.serverTimestamp();

    // 1. Update in community/global user_products list
    await _db.collection('user_products').doc(userProductId).update(updatedData);
    
    // 2. Update in user's personal wardrobe tracker
    await _db.collection('users').doc(userId).collection('wardrobe').doc(userProductId).update(updatedData);
  }

  /// Toggle an item in the user's personal wardrobe (save/remove)
  Future<void> toggleWardrobeItem({
    required String userId,
    required String productId,
    required Map<String, dynamic> productData,
  }) async {
    final wardrobeRef = _db.collection('users').doc(userId).collection('wardrobe').doc(productId);
    final doc = await wardrobeRef.get();

    if (doc.exists) {
      // If already saved, delete from wardrobe tracker and user_products
      await wardrobeRef.delete();
      final userProdQuery = await _db.collection('user_products')
          .where('userId', isEqualTo: userId)
          .where('originalProductId', isEqualTo: productId)
          .get();
      
      for (var d in userProdQuery.docs) {
        await d.reference.delete();
      }
    } else {
      // If not saved, flatten color data and add to wardrobe tracker and user_products
      List<String> finalColours = [];
      final dynamic rawColours = productData['colours'];
      final dynamic rawColour = productData['colour'];
      
      if (rawColours is List) {
        for (var item in rawColours) {
          if (item is String) finalColours.add(item);
          else if (item is List) finalColours.addAll(item.whereType<String>());
        }
      } else if (rawColours != null) {
        finalColours.add(rawColours.toString());
      } else if (rawColour != null) {
        if (rawColour is List) finalColours.addAll(rawColour.whereType<String>());
        else finalColours.add(rawColour.toString());
      }

      final data = {
        'userId': userId,
        'originalProductId': productId,
        'originalPosterId': productData['userId'],
        'name': productData['name'] ?? 'No Name',
        'imageUrl': productData['imageUrl'] ?? productData['imageURL'] ?? '',
        'rawImageUrl': productData['rawImageUrl'] ?? productData['imageUrl'] ?? productData['imageURL'] ?? '',
        'category': productData['category'] ?? 'other',
        'subcategory': productData['subcategory'] ?? '',
        'colours': finalColours,
        'gender': productData['gender'] ?? 'unisex',
        'weatherTags': productData['weatherTags'] ?? [],
        'functionalTags': productData['functionalTags'] ?? [],
        'createdAt': FieldValue.serverTimestamp(),
        'visibility': 'public',
      };

      await wardrobeRef.set(data);
      await _db.collection('user_products').add(data);
    }
  }

  /// Check if a product is currently in the user's wardrobe
  Stream<bool> isInWardrobe(String userId, String productId) {
    return _db.collection('users').doc(userId).collection('wardrobe').doc(productId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  /// Helper to fetch unique values for a field (e.g. all available categories)
  Future<List<String>> getUniqueValues(String field) async {
    try {
      final snapshot = await _db.collection('products').get();
      final Set<String> uniqueValues = {'all'};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey(field) && data[field] != null) {
          final dynamic val = data[field];
          if (val is List) {
            for (var item in val) {
              if (item != null) uniqueValues.add(item.toString().toLowerCase().trim());
            }
          } else {
            uniqueValues.add(val.toString().toLowerCase().trim());
          }
        }
      }
      List<String> sortedList = uniqueValues.where((s) => s.isNotEmpty).toList();
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

  /// Get general app settings/metadata from Firestore
  Stream<DocumentSnapshot> getAppMetadata() {
    return _db.collection('metadata').doc('settings').snapshots();
  }
}
