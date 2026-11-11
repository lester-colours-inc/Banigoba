// Data access for the user's boutique cart.
//
// Cart rows live in `cart_items`, one per piece and size, with a snapshot of
// the piece (name, price, picture, shop) so the bag still shows if the shop
// changes it. The service enforces one boutique per cart, carries selected
// sizes into cart rows, and keeps cart totals reactive. Items are identified
// by their cart row id.
import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/core/utils/size_inventory.dart';
import 'package:banigoba/modules/shop/services/product_service.dart';

class CartService {
  /// A `cart_items` row as the screens read it: the snapshot fields, plus
  /// `id` (the cart item), `productId`, `quantity` and `selectedSize`.
  static Map<String, dynamic> cartItemMap(Map<String, dynamic> row) {
    final data = row['data'];
    return {
      if (data is Map) ...Map<String, dynamic>.from(data),
      'id': row['id'].toString(),
      'productId': row['product_id'].toString(),
      'quantity': row['quantity'],
      if ((row['selected_size'] ?? '').toString().isNotEmpty)
        'selectedSize': row['selected_size'],
    };
  }

  Stream<List<Map<String, dynamic>>> watchCart(String userId) {
    return supabase
        .from('cart_items')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) => [for (final row in rows) cartItemMap(row)]);
  }

  Stream<int> watchItemCount(String userId) {
    return watchCart(userId).map((items) {
      return items.fold<int>(0, (total, item) {
        final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
        return total + quantity;
      });
    });
  }

  Future<void> addToCart({
    required String userId,
    required String productId,
    required Map<String, dynamic> productData,
    String? selectedSize,

    /// Who brought this sale (an influencer's post or link), if anyone. The
    /// database checks it again at checkout and ignores the buyer and the
    /// shop themselves.
    String? referrerId,
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
    final existing = await supabase
        .from('cart_items')
        .select()
        .eq('user_id', userId);
    final newShopId = _shopIdFor(cartProductData);
    final newShopName = _shopNameFor(cartProductData);
    Map<String, dynamic>? sameItem;
    for (final row in existing) {
      final item = cartItemMap(row);
      if (item['productId'] == productId &&
          (item['selectedSize'] ?? '').toString() == normalizedSize) {
        sameItem = item;
        continue;
      }
      final itemShopId = _shopIdFor(item);
      if (itemShopId.isNotEmpty &&
          newShopId.isNotEmpty &&
          itemShopId != newShopId) {
        throw CartShopConflictException(
          currentShopName: _shopNameFor(item),
          newShopName: newShopName,
        );
      }
    }

    if (sameItem != null) {
      final currentQuantity = (sameItem['quantity'] as num?)?.toInt() ?? 1;
      if (sizeInventory.isNotEmpty &&
          currentQuantity + 1 > (sizeInventory[normalizedSize] ?? 0)) {
        throw Exception(
          'Only ${sizeInventory[normalizedSize]} left in size $normalizedSize.',
        );
      }
      await supabase
          .from('cart_items')
          .update({
            'quantity': currentQuantity + 1,
            'data': {
              ..._snapshotOf(sameItem),
              ..._cartPriceAndStockFields(cartProductData),
            },
          })
          .eq('id', sameItem['id']);
      return;
    }

    await supabase.from('cart_items').insert({
      'user_id': userId,
      'product_id': productId,
      'selected_size': normalizedSize,
      'quantity': 1,
      'data': {
        ..._snapshotOf(cartProductData),
        'shopId': newShopId,
        'shopName': newShopName,
        if (referrerId != null && referrerId.isNotEmpty)
          'referrerId': referrerId,
      },
    });
  }

  /// The snapshot fields of a cart item, without the row's own columns.
  Map<String, dynamic> _snapshotOf(Map<String, dynamic> item) {
    return {
      for (final entry in item.entries)
        if (!const {
          'id',
          'productId',
          'quantity',
          'selectedSize',
          'userId',
          'createdAt',
          'updatedAt',
        }.contains(entry.key))
          entry.key: entry.value,
    };
  }

  /// Sets how many of a cart item are wanted. [productId] is the cart item id.
  Future<void> setQuantity({
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await removeFromCart(userId: userId, productId: productId);
      return;
    }
    final row = await supabase
        .from('cart_items')
        .select()
        .eq('id', productId)
        .maybeSingle();
    final data = row == null ? null : cartItemMap(row);
    final selectedSize = (data?['selectedSize'] ?? '').toString();
    final sizeInventory = parseSizeInventory(data ?? const <String, dynamic>{});
    if (selectedSize.isNotEmpty &&
        sizeInventory.isNotEmpty &&
        quantity > (sizeInventory[selectedSize] ?? 0)) {
      throw Exception(
        'Only ${sizeInventory[selectedSize]} left in size $selectedSize.',
      );
    }
    await supabase
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', productId);
  }

  /// Removes a cart item. [productId] is the cart item id.
  Future<void> removeFromCart({
    required String userId,
    required String productId,
  }) async {
    await supabase
        .from('cart_items')
        .delete()
        .eq('id', productId)
        .eq('user_id', userId);
  }

  Future<void> clearCart(String userId) async {
    await supabase.from('cart_items').delete().eq('user_id', userId);
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
    final row = await supabase
        .from('products')
        .select()
        .eq('id', productId)
        .maybeSingle();
    if (row == null) {
      return {...fallback, ..._cartPriceAndStockFields(fallback)};
    }
    final liveData = productMap(row);

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
