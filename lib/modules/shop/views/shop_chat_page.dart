import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/supabase/rows.dart';
import 'package:flutter/material.dart';

import 'package:banigoba/modules/shop/services/shop_chat_service.dart';
import 'package:banigoba/modules/designers/views/fashion_designers_page.dart';
import 'package:banigoba/modules/shop/views/shop_products_page.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

class ShopChatInboxPage extends StatelessWidget {
  const ShopChatInboxPage({super.key, this.sellerOnly = false});

  final bool sellerOnly;

  @override
  Widget build(BuildContext context) {
    final user = AppAuth.instance.currentUser;
    final service = ShopChatService();
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: user == null
          ? const Center(child: Text('Sign in to view messages.'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: service.watchConversations(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final chats =
                    snapshot.data!.where((chat) {
                      return !sellerOnly || chat['sellerId'] == user.uid;
                    }).toList()..sort((a, b) {
                      final aTime = asDateTime(a['lastMessageAt']);
                      final bTime = asDateTime(b['lastMessageAt']);
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
                    final data = chats[index];
                    final isSeller = data['sellerId'] == user.uid;
                    final conversationType =
                        (data['conversationType'] ?? 'shop').toString();
                    final title = isSeller
                        ? (data['customerName'] ?? 'Customer').toString()
                        : conversationType == 'designer'
                        ? (data['designerName'] ?? 'Designer').toString()
                        : (data['shopName'] ?? 'Boutique').toString();
                    final unread =
                        (data[isSeller ? 'unreadBySeller' : 'unreadByCustomer']
                                as num?)
                            ?.toInt() ??
                        0;
                    final lastMessageWhen = _formatConversationTimestamp(data);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF0D0140),
                        foregroundColor: Colors.white,
                        child: Text(
                          title.isEmpty ? 'C' : title[0].toUpperCase(),
                        ),
                      ),
                      title: _ConversationTitle(title, bold: unread > 0),
                      subtitle: Text(
                        (data['lastMessage'] ?? 'Start a conversation')
                            .toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: _ConversationTrailing(
                        timestamp: lastMessageWhen,
                        unread: unread,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ShopChatPage(
                            chatId: data['id'].toString(),
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

class _ConversationTitle extends StatelessWidget {
  const _ConversationTitle(this.title, {required this.bold});

  final String title;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500),
    );
  }
}

class _ProductReferenceMessage extends StatelessWidget {
  const _ProductReferenceMessage({
    required this.data,
    required this.mine,
    required this.timestamp,
  });

  final Map<String, dynamic> data;
  final bool mine;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    final imageUrl = (data['productImageUrl'] ?? '').toString();
    final productName = (data['productName'] ?? 'This product').toString();
    final price = (data['productPrice'] as num?)?.toDouble();
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: mine
              ? const Color(0xFF0D0140)
              : colorScheme.surfaceContainerLow,
          borderRadius: _messageBubbleRadius(mine),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageUrl.isEmpty
                      ? _ProductReferenceImageFallback(mine: mine)
                      : AppNetworkImage(
                          imageUrl,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          fallback: _ProductReferenceImageFallback(mine: mine),
                        ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asked about',
                        style: TextStyle(
                          color: mine
                              ? Colors.white70
                              : colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: mine ? Colors.white : colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (price != null && price > 0) ...[
                        const SizedBox(height: 3),
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: mine
                                ? Colors.white70
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            _MessageTimestamp(timestamp: timestamp, mine: mine, system: false),
          ],
        ),
      ),
    );
  }
}

/// A look forwarded from the Home feed: the picture, then its caption.
class _LookReferenceMessage extends StatelessWidget {
  const _LookReferenceMessage({
    required this.data,
    required this.mine,
    required this.timestamp,
  });

  final Map<String, dynamic> data;
  final bool mine;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    final imageUrl = (data['lookImageUrl'] ?? '').toString();
    final text = (data['text'] ?? 'Forwarded a look').toString();
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width * 0.62;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: mine
              ? const Color(0xFF0D0140)
              : colorScheme.surfaceContainerLow,
          borderRadius: _messageBubbleRadius(mine),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: imageUrl.isEmpty
                    ? _ProductReferenceImageFallback(mine: mine)
                    : AppNetworkImage(
                        imageUrl,
                        fit: BoxFit.cover,
                        fallback: _ProductReferenceImageFallback(mine: mine),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.shortcut_rounded,
                    size: 16,
                    color: mine ? Colors.white70 : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: mine ? Colors.white : colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _MessageTimestamp(
                  timestamp: timestamp,
                  mine: mine,
                  system: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesignRequestReferenceMessage extends StatelessWidget {
  const _DesignRequestReferenceMessage({
    required this.data,
    required this.mine,
    required this.timestamp,
  });

  final Map<String, dynamic> data;
  final bool mine;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final occasion = (data['occasion'] ?? 'Custom design').toString();
    final budget = (data['budget'] ?? '').toString();
    final deadline = (data['deadline'] ?? '').toString();
    final status = (data['status'] ?? '').toString();

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mine
              ? const Color(0xFF0D0140)
              : colorScheme.surfaceContainerLow,
          borderRadius: _messageBubbleRadius(mine),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: mine ? Colors.white70 : const Color(0xFF0D0140),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Design request',
                    style: TextStyle(
                      color: mine
                          ? Colors.white70
                          : colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              occasion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: mine ? Colors.white : colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (budget.isNotEmpty || deadline.isNotEmpty || status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (budget.isNotEmpty)
                      _RequestReferenceMeta(
                        label: 'Budget',
                        value: budget,
                        mine: mine,
                      ),
                    if (deadline.isNotEmpty)
                      _RequestReferenceMeta(
                        label: 'Deadline',
                        value: deadline,
                        mine: mine,
                      ),
                    if (status.isNotEmpty)
                      _RequestReferenceMeta(
                        label: 'Status',
                        value: status,
                        mine: mine,
                      ),
                  ],
                ),
              ),
            _MessageTimestamp(timestamp: timestamp, mine: mine, system: false),
          ],
        ),
      ),
    );
  }
}

class _RequestReferenceMeta extends StatelessWidget {
  const _RequestReferenceMeta({
    required this.label,
    required this.value,
    required this.mine,
  });

  final String label;
  final String value;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      '$label: $value',
      style: TextStyle(
        color: mine ? Colors.white70 : colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _MessageTimestamp extends StatelessWidget {
  const _MessageTimestamp({
    required this.timestamp,
    required this.mine,
    this.system = false,
  });

  final String timestamp;
  final bool mine;
  final bool system;

  @override
  Widget build(BuildContext context) {
    if (timestamp.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        timestamp,
        style: TextStyle(
          color: system
              ? colorScheme.onSurfaceVariant
              : mine
              ? Colors.white70
              : colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ConversationTrailing extends StatelessWidget {
  const _ConversationTrailing({required this.timestamp, required this.unread});

  final String timestamp;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 58,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (timestamp.isNotEmpty)
            Text(
              timestamp,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unread > 0
                    ? const Color(0xFF0D0140)
                    : colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          if (unread > 0) ...[
            const SizedBox(height: 6),
            CircleAvatar(
              radius: 11,
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(fontSize: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatConversationTimestamp(Map<String, dynamic> data) {
  final dateTime = _conversationDateTime(data);
  if (dateTime == null) return '';

  final local = dateTime.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDay = DateTime(local.year, local.month, local.day);
  final diff = today.difference(messageDay).inDays;
  if (diff == 0) {
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  if (diff == 1) return 'Yesterday';

  return '${local.day}/${local.month}/${local.year.toString().substring(2)}';
}

DateTime? _conversationDateTime(Map<String, dynamic> data) {
  final value = data['lastMessageAt'] ?? data['updatedAt'] ?? data['createdAt'];
  return asDateTime(value);
}

void _openDesignerDetail(BuildContext context, String designerId) {
  if (designerId.isEmpty) return;
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => DesignerDetailPage(designerId: designerId),
    ),
  );
}

String _formatMessageTimestamp(Map<String, dynamic> data) {
  final dateTime = _messageDateTime(data);
  if (dateTime == null) return '';

  final local = dateTime.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

DateTime? _messageDateTime(Map<String, dynamic> data) {
  final value = data['createdAt'];
  return asDateTime(value);
}

String _formatMessageDateLabel(Map<String, dynamic> data) {
  final dateTime = _messageDateTime(data);
  if (dateTime == null) return '';

  final local = dateTime.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDay = DateTime(local.year, local.month, local.day);
  final diff = today.difference(messageDay).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

bool _isSameMessageDay(
  Map<String, dynamic> first,
  Map<String, dynamic> second,
) {
  final firstDate = _messageDateTime(first)?.toLocal();
  final secondDate = _messageDateTime(second)?.toLocal();
  if (firstDate == null || secondDate == null) return false;
  return firstDate.year == secondDate.year &&
      firstDate.month == secondDate.month &&
      firstDate.day == secondDate.day;
}

BorderRadius _messageBubbleRadius(bool mine) {
  return BorderRadius.only(
    topLeft: const Radius.circular(18),
    topRight: const Radius.circular(18),
    bottomLeft: Radius.circular(mine ? 18 : 5),
    bottomRight: Radius.circular(mine ? 5 : 18),
  );
}

class _MessageDateSeparator extends StatelessWidget {
  const _MessageDateSeparator(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProductReferenceImageFallback extends StatelessWidget {
  const _ProductReferenceImageFallback({required this.mine});

  final bool mine;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 58,
      height: 58,
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.checkroom_outlined,
        color: mine ? Colors.white70 : colorScheme.onSurface,
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
    final currentUserId = AppAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: _buildTitle(context)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.watchMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text('Send the first message.'));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index];
                    final isSystem = data['senderType'] == 'system';
                    final isProductReference =
                        data['senderType'] == 'product_reference';
                    final isDesignRequestReference =
                        data['senderType'] == 'design_request_reference';
                    final isLookReference =
                        data['senderType'] == 'look_reference';
                    final mine = data['senderId'] == currentUserId;
                    final timestamp = _formatMessageTimestamp(data);
                    final nextOlderData = index + 1 < messages.length
                        ? messages[index + 1]
                        : null;
                    final showDateSeparator =
                        nextOlderData == null ||
                        !_isSameMessageDay(data, nextOlderData);
                    late final Widget message;
                    if (isLookReference) {
                      message = _LookReferenceMessage(
                        data: data,
                        mine: mine,
                        timestamp: timestamp,
                      );
                    } else if (isProductReference) {
                      message = _ProductReferenceMessage(
                        data: data,
                        mine: mine,
                        timestamp: timestamp,
                      );
                    } else if (isDesignRequestReference) {
                      message = _DesignRequestReferenceMessage(
                        data: data,
                        mine: mine,
                        timestamp: timestamp,
                      );
                    } else if (isSystem) {
                      message = Center(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                          ),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                (data['text'] ?? '').toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              _MessageTimestamp(
                                timestamp: timestamp,
                                mine: false,
                                system: true,
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      message = Align(
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
                            borderRadius: _messageBubbleRadius(mine),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: mine
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                (data['text'] ?? '').toString(),
                                style: TextStyle(
                                  color: mine ? Colors.white : null,
                                ),
                              ),
                              _MessageTimestamp(
                                timestamp: timestamp,
                                mine: mine,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showDateSeparator)
                          _MessageDateSeparator(_formatMessageDateLabel(data)),
                        message,
                      ],
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

  Widget _buildTitle(BuildContext context) {
    if (widget.asSeller) return Text(widget.title);

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _service.watchChat(widget.chatId),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final conversationType = (data?['conversationType'] ?? 'shop')
            .toString();
        if (conversationType == 'designer') {
          final designerId = (data?['designerId'] ?? data?['sellerId'] ?? '')
              .toString();
          final designerName = (data?['designerName'] ?? widget.title)
              .toString();
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: widget.asSeller || designerId.isEmpty
                ? null
                : () => _openDesignerDetail(context, designerId),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(designerName, overflow: TextOverflow.ellipsis),
                ),
                if (!widget.asSeller && designerId.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.design_services_outlined, size: 18),
                ],
              ],
            ),
          );
        }
        final sellerId = (data?['sellerId'] ?? '').toString();
        final shopName = (data?['shopName'] ?? widget.title).toString();

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: sellerId.isEmpty
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ShopProductsPage(
                      sellerId: sellerId,
                      shopName: shopName,
                    ),
                  ),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(shopName, overflow: TextOverflow.ellipsis)),
              if (sellerId.isNotEmpty) ...[
                const SizedBox(width: 6),
                const Icon(Icons.storefront_outlined, size: 18),
              ],
            ],
          ),
        );
      },
    );
  }
}
