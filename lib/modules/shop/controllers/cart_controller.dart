// The signed-in user's cart: live lines, current product prices, quantities.
import 'dart:async';

import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/modules/shop/services/cart_service.dart';
import 'package:banigoba/modules/shop/services/product_service.dart'
    show productMap;
import 'package:banigoba/shared/widgets/app_toast.dart';

class CartController extends GetxController {
  CartController({CartService? cart}) : _cart = cart ?? CartService();

  final CartService _cart;

  final String? userId = AppAuth.instance.currentUser?.uid;
  final RxList<Map<String, dynamic>> items = <Map<String, dynamic>>[].obs;
  final RxBool loaded = false.obs;

  /// Live products by cart line id. Cart rows keep a snapshot of product
  /// data, but the live product is loaded too so the price can recover if an
  /// older cart row is missing current fields.
  final RxMap<String, Map<String, dynamic>> liveProducts =
      <String, Map<String, dynamic>>{}.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void onInit() {
    super.onInit();
    final id = userId;
    if (id == null) return;
    _sub = _cart.watchCart(id).listen((rows) {
      items.assignAll(rows);
      loaded.value = true;
      _loadLiveProducts(rows);
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> _loadLiveProducts(List<Map<String, dynamic>> cartItems) async {
    final products = <String, Map<String, dynamic>>{};
    await Future.wait(
      cartItems.map((item) async {
        final productId = (item['productId'] ?? item['id']).toString();
        final row = await supabase
            .from('products')
            .select()
            .eq('id', productId)
            .maybeSingle();
        if (row != null) products[item['id'].toString()] = productMap(row);
      }),
    );
    if (!isClosed) liveProducts.assignAll(products);
  }

  double priceFor(Map<String, dynamic> line) {
    final cartPrice = _money(line['price']);
    if (cartPrice > 0) return cartPrice;
    return _money(liveProducts[line['id'].toString()]?['price']);
  }

  static double _money(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static int quantityOf(Map<String, dynamic> line) =>
      (line['quantity'] as num?)?.toInt() ?? 1;

  double get total => items.fold<double>(
    0,
    (sum, line) => sum + priceFor(line) * quantityOf(line),
  );

  /// The shop everything in the bag is from ('' when it cannot be told).
  String get sellerId {
    if (items.isEmpty) return '';
    final data = items.first;
    return (data['shopId'] ?? data['uploaderId'] ?? data['sellerId'] ?? '')
        .toString();
  }

  Future<void> setQuantity(String productId, int quantity) async {
    final id = userId;
    if (id == null) return;
    try {
      await _cart.setQuantity(
        userId: id,
        productId: productId,
        quantity: quantity,
      );
    } catch (error) {
      if (!isClosed) AppToast.say('Unable to update cart: $error');
    }
  }
}
