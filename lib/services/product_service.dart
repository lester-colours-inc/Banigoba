import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProductService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Stream<QuerySnapshot> getProducts() {
    return _db.collection('products').snapshots();
  }

  Future<void> addProduct(Map<String, dynamic> product) async {
    await _db.collection('products').add(product);
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
  }) async {
    await _db.collection('user_products').add({
      'userId': userId,
      'name': name,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'visibility': visibility,
    });
  }

  Stream<QuerySnapshot> getUserProducts(String userId) {
    return _db.collection('user_products')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
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
