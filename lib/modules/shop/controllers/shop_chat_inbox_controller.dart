// The Messages list: the user's conversations, newest first.
import 'dart:async';

import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/modules/shop/services/shop_chat_service.dart';
import 'package:banigoba/modules/shop/views/shop_chat_page.dart';

class ShopChatInboxController extends GetxController {
  ShopChatInboxController({this.sellerOnly = false});

  final bool sellerOnly;

  final String? userId = AppAuth.instance.currentUser?.uid;
  final RxList<Map<String, dynamic>> chats = <Map<String, dynamic>>[].obs;
  final RxBool loaded = false.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void onInit() {
    super.onInit();
    final id = userId;
    if (id == null) return;
    _sub = ShopChatService().watchConversations(id).listen((rows) {
      chats.assignAll(
        rows.where((chat) => !sellerOnly || chat['sellerId'] == id).toList()
          ..sort((a, b) {
            final aTime = asDateTime(a['lastMessageAt']);
            final bTime = asDateTime(b['lastMessageAt']);
            return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(
              aTime?.millisecondsSinceEpoch ?? 0,
            );
          }),
      );
      loaded.value = true;
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void open({
    required String chatId,
    required String title,
    required bool asSeller,
  }) => Get.to<void>(
    () => ShopChatPage(chatId: chatId, title: title, asSeller: asSeller),
  );
}
