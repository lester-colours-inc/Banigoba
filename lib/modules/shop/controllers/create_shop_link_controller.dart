// Loads the shop's name and pieces, then saves a new share link.
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/shop/models/shop_link.dart';
import 'package:banigoba/modules/shop/services/product_service.dart';
import 'package:banigoba/modules/shop/services/shop_link_service.dart';
import 'package:banigoba/modules/shop/views/shop_links_pages.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';

typedef ShopStock = (String, List<Map<String, dynamic>>);

class CreateShopLinkController extends GetxController {
  CreateShopLinkController({ShopLinkService? service})
    : _service = service ?? ShopLinkService();

  final ShopLinkService _service;
  final String userId = AppAuth.instance.currentUser?.uid ?? '';

  /// The shop's name and pieces; null while loading.
  final Rxn<ShopStock> data = Rxn<ShopStock>();
  final RxBool failed = false.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await ProfileService().get(userId);
      final shop = user['shop'];
      final name = shop is Map && (shop['name'] ?? '').toString().isNotEmpty
          ? shop['name'].toString()
          : (user['displayName'] ?? 'My shop').toString();
      final products = await ProductService().getAdminProducts(userId).first;
      if (!isClosed) data.value = (name, products);
    } on Exception {
      if (!isClosed) failed.value = true;
    }
  }

  Future<void> create(ShopLink draft) async {
    final id = await _service.create(draft);
    if (isClosed) return;
    final saved = ShopLink.fromMap(id, draft.toMap());
    await Get.off<void>(() => ShareShopLinkPage(link: saved));
  }
}
