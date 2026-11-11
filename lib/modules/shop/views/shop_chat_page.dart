import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/shop/controllers/shop_chat_controller.dart';
import 'package:banigoba/modules/shop/controllers/shop_chat_inbox_controller.dart';
import 'package:banigoba/modules/shop/models/chat_format.dart';
import 'package:banigoba/modules/shop/widgets/chat_basics.dart';
import 'package:banigoba/modules/shop/widgets/chat_message_tile.dart';
import 'package:banigoba/modules/shop/widgets/chat_title.dart';

class ShopChatInboxPage extends StatelessWidget {
  const ShopChatInboxPage({super.key, this.sellerOnly = false});

  final bool sellerOnly;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ShopChatInboxController>(
      init: ShopChatInboxController(sellerOnly: sellerOnly),
      global: false,
      builder: (controller) => Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: controller.userId == null
            ? const Center(child: Text('Sign in to view messages.'))
            : Obx(() {
                if (!controller.loaded.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final chats = controller.chats;
                if (chats.isEmpty) {
                  return Center(
                    child: Text(
                      sellerOnly
                          ? 'Customer conversations will appear here.'
                          : 'Your boutique conversations will appear here.',
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: chats.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) => _ConversationRow(
                    controller: controller,
                    data: chats[index],
                  ),
                );
              }),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.controller, required this.data});

  final ShopChatInboxController controller;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final isSeller = data['sellerId'] == controller.userId;
    final conversationType = (data['conversationType'] ?? 'shop').toString();
    final title = isSeller
        ? (data['customerName'] ?? 'Customer').toString()
        : conversationType == 'designer'
        ? (data['designerName'] ?? 'Designer').toString()
        : (data['shopName'] ?? 'Boutique').toString();
    final unread =
        (data[isSeller ? 'unreadBySeller' : 'unreadByCustomer'] as num?)
            ?.toInt() ??
        0;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF0D0140),
        foregroundColor: Colors.white,
        child: Text(title.isEmpty ? 'C' : title[0].toUpperCase()),
      ),
      title: ConversationTitle(title, bold: unread > 0),
      subtitle: Text(
        (data['lastMessage'] ?? 'Start a conversation').toString(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: ConversationTrailing(
        timestamp: formatConversationTimestamp(data),
        unread: unread,
      ),
      onTap: () => controller.open(
        chatId: data['id'].toString(),
        title: title,
        asSeller: isSeller,
      ),
    );
  }
}

class ShopChatPage extends StatelessWidget {
  const ShopChatPage({
    super.key,
    required this.chatId,
    required this.title,
    required this.asSeller,
  });

  final String chatId;
  final String title;
  final bool asSeller;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ShopChatController>(
      init: ShopChatController(
        chatId: chatId,
        title: title,
        asSeller: asSeller,
      ),
      global: false,
      builder: (controller) => _ShopChatView(controller: controller),
    );
  }
}

class _ShopChatView extends StatelessWidget {
  const _ShopChatView({required this.controller});

  final ShopChatController controller;

  @override
  Widget build(BuildContext context) {
    final currentUserId = AppAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: Obx(() => ChatTitle(controller: controller))),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (!controller.loaded.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final messages = controller.messages;
              if (messages.isEmpty) {
                return const Center(child: Text('Send the first message.'));
              }
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) => ChatMessageTile(
                  data: messages[index],
                  olderData: index + 1 < messages.length
                      ? messages[index + 1]
                      : null,
                  currentUserId: currentUserId,
                ),
              );
            }),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.text,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => controller.send(),
                    ),
                  ),
                  Obx(
                    () => IconButton.filled(
                      onPressed: controller.sending.value
                          ? null
                          : controller.send,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF0D0140),
                      ),
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
