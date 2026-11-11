// The shop's list of share links, and making a new one.
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/shop/models/shop_link.dart';
import 'package:banigoba/modules/shop/services/shop_link_service.dart';
import 'package:banigoba/modules/shop/views/shop_links_pages.dart';

class ShopLinksController extends GetxController {
  ShopLinksController({ShopLinkService? service})
    : _service = service ?? ShopLinkService();

  final ShopLinkService _service;
  final String _userId = AppAuth.instance.currentUser?.uid ?? '';

  /// Null until the first load finishes.
  final Rxn<List<ShopLink>> links = Rxn<List<ShopLink>>();
  final RxBool failed = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      final loaded = await _service.mine(_userId);
      if (isClosed) return;
      failed.value = false;
      links.value = loaded;
    } on Exception {
      if (!isClosed) failed.value = true;
    }
  }

  Future<void> newLink() async {
    await Get.to<void>(() => const CreateShopLinkPage());
    if (!isClosed) await load();
  }

  void open(ShopLink link) => Get.to<void>(() => ShareShopLinkPage(link: link));

  Future<void> setActive(ShopLink link, {required bool on}) async {
    await _service.setActive(link, active: on);
    if (!isClosed) await load();
  }
}
