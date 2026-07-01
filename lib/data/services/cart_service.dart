// Firestore data access for the user's boutique cart.
//
// Cart rows live under users/{uid}/cart. The service enforces one boutique per
// cart, carries selected sizes into cart rows, and keeps cart totals reactive.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/size_inventory.dart';

class CartService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _cart(String userId) {
    return _db.collection('users').doc(userId).collection('cart');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCart(String userId) {
    return _cart(userId).snapshots();
  }

  Stream<int> watchItemCount(String userId) {
    return watchCart(userId).map((snapshot) {
      return snapshot.docs.fold<int>(0, (total, doc) {
        final quantity = (doc.data()['quantity'] as num?)?.toInt() ?? 1;
        return total + quantity;
      });
    });
  }

  Future<void> addToCart({
    required String userId,
    required String productId,
    required Map<String, dynamic> productData,
    String? selectedSize,
  }) async {
    final cartProductData = await _withLiveProductData(productId, productData);
    final normalizedSize = normalizeSizeLabel(selectedSize);
    final sizeInventory = parseSizeInventory(cartProductData);
    // Products with size inventory must carry the chosen size into the cart so
    // checkout can decrement the correct size bucket later.
    if (sizeInventory.isNotEmpty) {
      if (normalizedSize.isEmpty) {
        throw Exception('Choose a size before adding this item.');
      }
      final sizeStock = sizeInventory[normalizedSize] ?? 0;
      if (sizeStock <= 0) {
        throw Exception('Size $normalizedSize is out of stock.');
      }
      cartProductData['stock'] = sizeStock;
    }
    final existing = await _cart(userId).get();
    final newShopId = _shopIdFor(cartProductData);
    final newShopName = _shopNameFor(cartProductData);
    final cartItemId = cartItemIdForSize(productId, normalizedSize);
    for (final doc in existing.docs) {
      if (doc.id == cartItemId) continue;
      final itemShopId = _shopIdFor(doc.data());
      if (itemShopId.isNotEmpty &&
          newShopId.isNotEmpty &&
          itemShopId != newShopId) {
        throw CartShopConflictException(
          currentShopName: _shopNameFor(doc.data()),
          newShopName: newShopName,
        );
      }
    }

    final ref = _cart(userId).doc(cartItemId);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      final currentQuantity =
          (snapshot.data()?['quantity'] as num?)?.toInt() ?? 1;
      if (sizeInventory.isNotEmpty &&
          currentQuantity + 1 > (sizeInventory[normalizedSize] ?? 0)) {
        throw Exception(
          'Only ${sizeInventory[normalizedSize]} left in size $normalizedSize.',
        );
      }
      await ref.update({
        'quantity': FieldValue.increment(1),
        ..._cartPriceAndStockFields(cartProductData),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await ref.set({
      ...cartProductData,
      'productId': productId,
      'shopId': newShopId,
      'shopName': newShopName,
      if (normalizedSize.isNotEmpty) 'selectedSize': normalizedSize,
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
    final snapshot = await _cart(userId).doc(productId).get();
    final data = snapshot.data();
    final selectedSize = (data?['selectedSize'] ?? '').toString();
    final sizeInventory = parseSizeInventory(data ?? const <String, dynamic>{});
    if (selectedSize.isNotEmpty &&
        sizeInventory.isNotEmpty &&
        quantity > (sizeInventory[selectedSize] ?? 0)) {
      throw Exception(
        'Only ${sizeInventory[selectedSize]} left in size $selectedSize.',
      );
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

  Future<void> clearCart(String userId) async {
    final snapshot = await _cart(userId).get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  String _shopIdFor(Map<String, dynamic> data) {
    return (data['shopId'] ?? data['uploaderId'] ?? data['sellerId'] ?? '')
        .toString();
  }

  String _shopNameFor(Map<String, dynamic> data) {
    return (data['shopName'] ?? data['boutiqueName'] ?? 'this boutique')
        .toString();
  }

  Future<Map<String, dynamic>> _withLiveProductData(
    String productId,
    Map<String, dynamic> fallback,
  ) async {
    final product = await _db.collection('products').doc(productId).get();
    final liveData = product.data();
    if (liveData == null) {
      return {...fallback, ..._cartPriceAndStockFields(fallback)};
    }

    return {
      ...fallback,
      ...liveData,
      'price': _moneyValue(liveData['price'] ?? fallback['price']),
      if (liveData.containsKey('sizeInventory') ||
          fallback.containsKey('sizeInventory'))
        'sizeInventory': parseSizeInventory(
          liveData.containsKey('sizeInventory') ? liveData : fallback,
        ),
      if (liveData.containsKey('stock') || fallback.containsKey('stock'))
        'stock': _intValue(liveData['stock'] ?? fallback['stock']),
    };
  }

  Map<String, dynamic> _cartPriceAndStockFields(Map<String, dynamic> data) {
    return {
      'price': _moneyValue(data['price']),
      if (data.containsKey('stock')) 'stock': _intValue(data['stock']),
    };
  }

  double _moneyValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0;
    return 0;
  }

  int _intValue(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}

class CartShopConflictException implements Exception {
  const CartShopConflictException({
    required this.currentShopName,
    required this.newShopName,
  });

  final String currentShopName;
  final String newShopName;

  @override
  String toString() {
    return 'Your bag already has items from $currentShopName.';
  }
}
