import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class ProductService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _supabase = Supabase.instance.client;

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
    String? gender,
  }) async {
    final data = {
      'userId': userId,
      'name': name,
      'imageUrl': imageUrl,
      'category': category,
      'subcategory': subcategory,
      'colour': colour,
      'gender': gender,
      'createdAt': FieldValue.serverTimestamp(),
      'visibility': visibility,
    };
    
    // Add to user_products (Mine tab)
    await _db.collection('user_products').add(data);
    
    // Also save to a separate favourites collection for tracking
    await _db.collection('users').doc(userId).collection('favourites').add(data);
  }

  Stream<QuerySnapshot> getUserProducts(String userId) {
    return _db.collection('user_products')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Improved Favourite Logic
  Future<void> toggleFavourite({
    required String userId,
    required String productId,
    required Map<String, dynamic> productData,
  }) async {
    final favRef = _db.collection('users').doc(userId).collection('favourites').doc(productId);
    final doc = await favRef.get();

    if (doc.exists) {
      // Unfavourite
      await favRef.delete();
      
      // Also remove from user_products (Mine tab)
      final userProdQuery = await _db.collection('user_products')
          .where('userId', isEqualTo: userId)
          .where('originalProductId', isEqualTo: productId)
          .get();
      
      for (var d in userProdQuery.docs) {
        await d.reference.delete();
      }
    } else {
      // Favourite
      final data = {
        'userId': userId,
        'originalProductId': productId,
        'name': productData['name'],
        'imageUrl': productData['imageURL'] ?? productData['imageUrl'] ?? '',
        'category': productData['category'],
        'subcategory': productData['subcategory'],
        'colour': productData['colour'],
        'gender': productData['gender'],
        'createdAt': FieldValue.serverTimestamp(),
        'visibility': 'public',
      };

      await favRef.set({'timestamp': FieldValue.serverTimestamp()});
      await _db.collection('user_products').add(data);
    }
  }

  Stream<bool> isFavourited(String userId, String productId) {
    return _db.collection('users').doc(userId).collection('favourites').doc(productId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // Wardrobe / Favourites logic
  Future<void> addToWardrobe(String userId, Map<String, dynamic> productData, String productId) async {
    await _db.collection('users').doc(userId).collection('wardrobe').doc(productId).set({
      ...productData,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getWardrobeItems(String userId) {
    return _db.collection('users').doc(userId).collection('wardrobe').orderBy('addedAt', descending: true).snapshots();
  }

  Future<void> removeFromWardrobe(String userId, String productId) async {
    await _db.collection('users').doc(userId).collection('wardrobe').doc(productId).delete();
  }

  // Filter Helper
  Future<List<String>> getUniqueValues(String field) async {
    final snapshot = await _db.collection('products').get();
    final Set<String> uniqueValues = {'all'};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey(field) && data[field] != null) {
        String val = data[field].toString().toLowerCase();
        if (val.isNotEmpty) {
          uniqueValues.add(val);
        }
      }
    }
    List<String> sortedList = uniqueValues.toList();
    sortedList.sort((a, b) {
      if (a == 'all') return -1;
      if (b == 'all') return 1;
      return a.compareTo(b);
    });
    return sortedList;
  }
}
