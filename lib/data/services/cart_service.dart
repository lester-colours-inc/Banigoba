import 'package:cloud_firestore/cloud_firestore.dart';

class CartService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _cart(String userId) {
    return _db.collection('users').doc(userId).collection('cart');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCart(String userId) {
    return _cart(userId).snapshots();
  }

  Future<void> addToCart({
    required String userId,
    required String productId,
    required Map<String, dynamic> productData,
  }) async {
    final ref = _cart(userId).doc(productId);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      await ref.update({
        'quantity': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await ref.set({
      ...productData,
      'productId': productId,
      'quantity': 1,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setQuantity({
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await removeFromCart(userId: userId, productId: productId);
      return;
    }
    await _cart(userId).doc(productId).update({
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFromCart({
    required String userId,
    required String productId,
  }) {
    return _cart(userId).doc(productId).delete();
  }
}
