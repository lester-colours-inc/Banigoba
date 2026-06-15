import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/services/shop_chat_service.dart';

class ShopChatInboxPage extends StatelessWidget {
  const ShopChatInboxPage({super.key, this.sellerOnly = false});

  final bool sellerOnly;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final service = ShopChatService();
    return Scaffold(
      appBar: AppBar(
        title: Text(sellerOnly ? 'Customer Messages' : 'Shop Messages'),
      ),
      body: user == null
          ? const Center(child: Text('Sign in to view messages.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.watchConversations(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final chats =
                    snapshot.data!.docs.where((doc) {
                      return !sellerOnly || doc.data()['sellerId'] == user.uid;
                    }).toList()..sort((a, b) {
                      final aTime = a.data()['lastMessageAt'] as Timestamp?;
                      final bTime = b.data()['lastMessageAt'] as Timestamp?;
                      return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(
                        aTime?.millisecondsSinceEpoch ?? 0,
                      );
                    });
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
                  itemBuilder: (context, index) {
                    final doc = chats[index];
                    final data = doc.data();
                    final isSeller = data['sellerId'] == user.uid;
                    final title = isSeller
                        ? (data['customerName'] ?? 'Customer').toString()
                        : (data['shopName'] ?? 'Boutique').toString();
                    final unread =
                        (data[isSeller ? 'unreadBySeller' : 'unreadByCustomer']
                                as num?)
                            ?.toInt() ??
                        0;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF0D0140),
                        foregroundColor: Colors.white,
                        child: Text(
                          title.isEmpty ? 'C' : title[0].toUpperCase(),
                        ),
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: unread > 0
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        (data['lastMessage'] ?? 'Start a conversation')
                            .toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: unread > 0
                          ? CircleAvatar(
                              radius: 11,
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              child: Text(
                                unread > 99 ? '99+' : '$unread',
                                style: const TextStyle(fontSize: 8),
                              ),
                            )
                          : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ShopChatPage(
                            chatId: doc.id,
                            title: title,
                            asSeller: isSeller,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class ShopChatPage extends StatefulWidget {
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
  State<ShopChatPage> createState() => _ShopChatPageState();
}

class _ShopChatPageState extends State<ShopChatPage> {
  final _controller = TextEditingController();
  final _service = ShopChatService();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _service.markRead(chatId: widget.chatId, asSeller: widget.asSeller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _service.sendMessage(chatId: widget.chatId, text: text);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.watchMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                if (messages.isEmpty) {
                  return const Center(child: Text('Send the first message.'));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data();
                    final mine = data['senderId'] == currentUserId;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: mine
                              ? const Color(0xFF0D0140)
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          (data['text'] ?? '').toString(),
                          style: TextStyle(color: mine ? Colors.white : null),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
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
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF0D0140),
                    ),
                    icon: const Icon(Icons.send_rounded),
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
