// A boutique's page: its pieces and the "Message Boutique" button.
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/shop/services/shop_chat_service.dart';
import 'package:banigoba/modules/shop/views/product_detail_page.dart';
import 'package:banigoba/modules/shop/views/shop_chat_page.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class BoutiqueDetailController extends GetxController {
  BoutiqueDetailController({required this.sellerId, required this.shopName});

  final String sellerId;
  final String shopName;

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
