// A designer's page: messaging them.
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/designers/models/designer_summary.dart';
import 'package:banigoba/modules/shop/services/shop_chat_service.dart';
import 'package:banigoba/modules/shop/views/shop_chat_page.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class DesignerDetailController extends GetxController {
  DesignerDetailController({required this.designer});

  final DesignerSummary designer;

  Future<void> openConversation() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      AppToast.say('Sign in to message this designer.');
      return;
    }
    final chatId = await ShopChatService().ensureDesignerConversation(
      designerId: designer.id,
      customerId: user.uid,
      designerName: designer.name,
    );
    if (isClosed) return;
    await Get.to<void>(
      () => ShopChatPage(chatId: chatId, title: designer.name, asSeller: false),
    );
  }
}
