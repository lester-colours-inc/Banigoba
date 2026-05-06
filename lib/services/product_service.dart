import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'notification_service.dart';
import 'package:flutter/foundation.dart';

class ProductService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _supabase = Supabase.instance.client;
  final _notificationService = NotificationService();

  Stream<QuerySnapshot> getProducts() {
    return _db.collection('products').snapshots();
  }

  Future<void> addProduct(Map<String, dynamic> product) async {
    await _db.collection('products').add(product);
  }

  // Supabase Upload
  Future<String> uploadToSupabase({
    required File imageFile,
    required String category,
    required String subcategory,
  }) async {
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    // Path: category/subcategory/filename.jpg
    final String path = '$category/$subcategory/$fileName';

    await _supabase.storage.from('images').upload(
          path,
          imageFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    final String publicUrl = _supabase.storage.from('images').getPublicUrl(path);
    return publicUrl;
  }

  // User Products (Private Wardrobe with Upload)
  Future<String> uploadProductImage(String userId, File image) async {
    final ref = _storage.ref().child('user_products').child(userId).child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

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
    // Ensure colours is a flat List<String>
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
    
    // Add to user_products (Mine tab)
    final docRef = await _db.collection('user_products').add(data);
    
    // Notify followers if it's public
    if (visibility == 'public') {
      await _notificationService.notifyFollowersNewPost(name);
    }
    
    // Also save to a separate wardrobe collection for tracking
    await _db.collection('users').doc(userId).collection('wardrobe').doc(docRef.id).set(data);
  }

  Stream<QuerySnapshot> getUserProducts(String userId) {
    return _db.collection('user_products')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  // Wardrobe logic (Toggle Add/Remove)
  Future<void> toggleWardrobeItem({
    required String userId,
    required String productId,
    required Map<String, dynamic> productData,
  }) async {
    final wardrobeRef = _db.collection('users').doc(userId).collection('wardrobe').doc(productId);
    final doc = await wardrobeRef.get();

    if (doc.exists) {
      // Remove from Wardrobe
      await wardrobeRef.delete();
      
      // Also remove from user_products (Mine tab)
      final userProdQuery = await _db.collection('user_products')
          .where('userId', isEqualTo: userId)
          .where('originalProductId', isEqualTo: productId)
          .get();
      
      for (var d in userProdQuery.docs) {
        await d.reference.delete();
      }
    } else {
      // Add to Wardrobe
      
      // Safely extract and flatten colours
      List<String> finalColours = [];
      final dynamic rawColours = productData['colours'];
      final dynamic rawColour = productData['colour'];
      
      if (rawColours is List) {
        for (var item in rawColours) {
          if (item is String) {
            finalColours.add(item);
          } else if (item is List) {
            // Flatten if nested
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

  Stream<bool> isInWardrobe(String userId, String productId) {
    return _db.collection('users').doc(userId).collection('wardrobe').doc(productId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // Filter Helper
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

  Stream<DocumentSnapshot> getAppMetadata() {
    return _db.collection('metadata').doc('settings').snapshots();
  }
}
