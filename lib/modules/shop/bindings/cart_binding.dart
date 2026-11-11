import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/cart_controller.dart';

class CartBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CartController>(CartController.new);
  }
}
