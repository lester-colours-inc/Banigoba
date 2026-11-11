// One conversation: its messages, sending, and the title's links.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/designers/views/fashion_designers_page.dart';
import 'package:banigoba/modules/shop/services/shop_chat_service.dart';
import 'package:banigoba/modules/shop/views/shop_products_page.dart';

class ShopChatController extends GetxController {
  ShopChatController({
    required this.chatId,
    required this.title,
    required this.asSeller,
    ShopChatService? service,
  }) : _service = service ?? ShopChatService();

  final String chatId;
  final String title;
  final bool asSeller;
  final ShopChatService _service;

  final TextEditingController text = TextEditingController();
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxBool loaded = false.obs;
  final RxBool sending = false.obs;

  /// The conversation's own record (shop or designer); null until it loads.
  final Rxn<Map<String, dynamic>> chat = Rxn<Map<String, dynamic>>();

  StreamSubscription<List<Map<String, dynamic>>>? _messageSub;
  StreamSubscription<Map<String, dynamic>?>? _chatSub;

  @override
  void onInit() {
    super.onInit();
    _service.markRead(chatId: chatId, asSeller: asSeller);
    _messageSub = _service.watchMessages(chatId).listen((rows) {
      messages.assignAll(rows);
      loaded.value = true;
    });
    if (!asSeller) {
      _chatSub = _service.watchChat(chatId).listen((data) => chat.value = data);
    }
  }

  @override
  void onClose() {
    _messageSub?.cancel();
    _chatSub?.cancel();
    text.dispose();
    super.onClose();
  }

  Future<void> send() async {
    final message = text.text.trim();
    if (message.isEmpty || sending.value) return;
    sending.value = true;
    try {
      await _service.sendMessage(chatId: chatId, text: message);
      text.clear();
    } finally {
      if (!isClosed) sending.value = false;
    }
  }

  void openDesigner(String designerId) {
    if (designerId.isEmpty) return;
    Get.to<void>(() => DesignerDetailPage(designerId: designerId));
  }

  void openShop(String sellerId, String shopName) => Get.to<void>(
    () => ShopProductsPage(sellerId: sellerId, shopName: shopName),
  );
}
