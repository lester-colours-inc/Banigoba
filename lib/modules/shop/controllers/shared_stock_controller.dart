// Opens a shared stock link: loads it and sends the viewer on to try-on, buy
// or sign-in.
import 'package:get/get.dart';

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/makeover/views/avatar_try_on_page.dart';
import 'package:banigoba/modules/shop/models/shop_link.dart';
import 'package:banigoba/modules/shop/services/shop_link_service.dart';
import 'package:banigoba/modules/shop/views/product_detail_page.dart';

typedef SharedStock = (ShopLink?, List<Map<String, dynamic>>);

class SharedStockController extends GetxController {
  SharedStockController({required this.linkId, ShopLinkSource? source})
    : _source = source ?? ShopLinkService();

  final String linkId;
  final ShopLinkSource _source;

  /// The link and its pieces; null while loading.
  final Rxn<SharedStock> data = Rxn<SharedStock>();
  final RxBool failed = false.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      final link = await _source.load(linkId);
      final result = (link == null || !link.active)
          ? (link, <Map<String, dynamic>>[])
          : (link, await _source.pieces(link));
      if (!isClosed) data.value = result;
    } on Object {
      if (!isClosed) failed.value = true;
    }
  }

  bool get signedIn {
    try {
      return AppAuth.instance.currentUser != null;
    } on Object {
      return false;
    }
  }

  void tryOn(Map<String, dynamic> piece) => Get.to<void>(
    () => AvatarTryOnPage(
      garmentImageUrl:
          (piece['rawImageUrl'] ?? piece['imageUrl'] ?? piece['imageURL'])
              ?.toString(),
      garmentName: (piece['name'] ?? '').toString(),
      category: (piece['category'] ?? '').toString(),
    ),
  );

  void buy(Map<String, dynamic> piece) => Get.to<void>(
    () => ProductDetailPage(
      productId: (piece['id'] ?? '').toString(),
      productData: piece,
    ),
  );

  /// Back to the start, where signing in happens. The link can be opened
  /// again afterwards.
  void signIn() => Get.offAllNamed<void>(AppRoutes.root);
}
