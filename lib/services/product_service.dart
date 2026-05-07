import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'notification_service.dart';
import 'package:flutter/foundation.dart';

/// Service handling all product-related operations (Firestore, Storage, Supabase)
class ProductService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _supabase = Supabase.instance.client;
  final _notificationService = NotificationService();

  /// Get stream of all products in the main collection
  Stream<QuerySnapshot> getProducts() {
    return _db.collection('products').snapshots();
  }

  /// Add a new product to the main products collection
  Future<void> addProduct(Map<String, dynamic> product) async {
    await _db.collection('products').add(product);
  }

  /// Delete a product from the main products collection
  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  /// Upload an image to Supabase storage and return the public URL
  Future<String> uploadToSupabase({
    required File imageFile,
    required String category,
    required String subcategory,
  }) async {
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String path = '$category/$subcategory/$fileName';

    await _supabase.storage.from('images').upload(
          path,
          imageFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return _supabase.storage.from('images').getPublicUrl(path);
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
    String? category,
    String? subcategory,
    String? colour,
    List<String>? colours,
    String? gender,
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
      'category': category,
      'subcategory': subcategory,
      'colours': finalColours,
      'gender': gender,
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
        'name': productData['name'] ?? 'No Name',
        'imageUrl': productData['imageURL'] ?? productData['imageUrl'] ?? '',
        'category': productData['category'] ?? 'other',
        'subcategory': productData['subcategory'] ?? '',
        'colours': finalColours,
        'gender': productData['gender'] ?? 'unisex',
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
