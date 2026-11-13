// A boutique's page: its pieces and the "Message Boutique" button.
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/settings/services/private_account_service.dart';
import 'package:banigoba/modules/shop/models/shop_filters.dart';
import 'package:banigoba/modules/shop/services/shop_chat_service.dart';
import 'package:banigoba/modules/shop/views/product_detail_page.dart';
import 'package:banigoba/modules/shop/views/shop_chat_page.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class BoutiqueDetailController extends GetxController {
  BoutiqueDetailController({
    required this.sellerId,
    required this.shopName,
    required this.products,
  });

  final String sellerId;
  final String shopName;

  /// Every piece this boutique lists.
  final List<Map<String, dynamic>> products;

  final Rx<ShopFilters> filters = const ShopFilters().obs;

  /// 'male' / 'female' from the viewer's profile, or null.
  final RxnString viewerGender = RxnString();

  late final ShopFilterOptions options = ShopFilterOptions.from(products);

  @override
  void onInit() {
    super.onInit();
    _loadViewerGender();
  }

  Future<void> _loadViewerGender() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) return;
    try {
      final details = await PrivateAccountService().details(user.uid);
      if (!isClosed) viewerGender.value = details.shopsFor;
    } on Object {
      // Ordering falls back to newest first.
    }
  }

  List<Map<String, dynamic>> get visible => applyShopFilters(
    products,
    filters.value,
    viewerGender: viewerGender.value,
  );

  void setFilters(ShopFilters value) => filters.value = value;

  void setSort(ShopSort sort) =>
      filters.value = filters.value.copyWith(sort: sort);

  void toggleCategory(String category) => filters.value = filters.value
      .copyWith(categories: toggled(filters.value.categories, category));

  void clearCategories() =>
      filters.value = filters.value.copyWith(categories: const {});

  void clearFilters() => filters.value = filters.value.cleared();

  Future<void> messageBoutique() async {
    final customer = AppAuth.instance.currentUser;
    if (customer == null) {
      AppToast.say('Sign in to send messages.');
      return;
    }
    if (customer.uid == sellerId) return;
    final chatId = await ShopChatService().ensureConversation(
      sellerId: sellerId,
      customerId: customer.uid,
      shopName: shopName,
    );
    if (isClosed) return;
    await Get.to<void>(
      () => ShopChatPage(chatId: chatId, title: shopName, asSeller: false),
    );
  }

  void openProduct(Map<String, dynamic> product) => Get.to<void>(
    () => ProductDetailPage(
      productId: product['id']?.toString(),
      productData: product,
    ),
  );
}
