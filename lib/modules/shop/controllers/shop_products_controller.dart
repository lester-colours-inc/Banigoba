// A boutique's own product list, live.
import 'dart:async';

import 'package:get/get.dart';

import 'package:banigoba/modules/shop/services/product_service.dart';
import 'package:banigoba/modules/shop/views/product_detail_page.dart';

class ShopProductsController extends GetxController {
  ShopProductsController({required this.sellerId});

  final String sellerId;

  final RxList<Map<String, dynamic>> products = <Map<String, dynamic>>[].obs;
  final RxBool loaded = false.obs;
  final RxBool failed = false.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = ProductService().getAdminProducts(sellerId).listen((rows) {
      failed.value = false;
      products.assignAll(rows);
      loaded.value = true;
    }, onError: (Object _) => failed.value = true);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void openProduct(Map<String, dynamic> product) => Get.to<void>(
    () => ProductDetailPage(
      productId: product['id'].toString(),
      productData: product,
    ),
  );
}
