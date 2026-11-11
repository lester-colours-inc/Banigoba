// One message in a shop chat: picks the bubble for its sender type and puts
// the date separator above the first message of a day.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/shop/models/chat_format.dart';
import 'package:banigoba/modules/shop/widgets/chat_basics.dart';
import 'package:banigoba/modules/shop/widgets/chat_reference_messages.dart';

class ChatMessageTile extends StatelessWidget {
  const ChatMessageTile({
    super.key,
    required this.data,
    required this.olderData,
    required this.currentUserId,
  });

  final Map<String, dynamic> data;

  /// The message just before this one, or null for the first.
  final Map<String, dynamic>? olderData;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final type = data['senderType'];
    final mine = data['senderId'] == currentUserId;
    final timestamp = formatMessageTimestamp(data);
    final older = olderData;
    final showDateSeparator = older == null || !isSameMessageDay(data, older);

    final Widget message = switch (type) {
      'look_reference' => LookReferenceMessage(
        data: data,
        mine: mine,
        timestamp: timestamp,
      ),
      'product_reference' => ProductReferenceMessage(
        data: data,
        mine: mine,
        timestamp: timestamp,
      ),
      'design_request_reference' => DesignRequestReferenceMessage(
        data: data,
        mine: mine,
        timestamp: timestamp,
      ),
      'system' => _SystemBubble(data: data, timestamp: timestamp),
      _ => _TextBubble(data: data, mine: mine, timestamp: timestamp),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDateSeparator)
          MessageDateSeparator(formatMessageDateLabel(data)),
        message,
      ],
    );
  }
}

class _SystemBubble extends StatelessWidget {
  const _SystemBubble({required this.data, required this.timestamp});

  final Map<String, dynamic> data;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (data['text'] ?? '').toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            MessageTimestamp(timestamp: timestamp, mine: false, system: true),
          ],
        ),
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  const _TextBubble({
    required this.data,
    required this.mine,
    required this.timestamp,
  });

  final Map<String, dynamic> data;
  final bool mine;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine
              ? const Color(0xFF0D0140)
              : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: messageBubbleRadius(mine),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              (data['text'] ?? '').toString(),
              style: TextStyle(color: mine ? Colors.white : null),
            ),
            MessageTimestamp(timestamp: timestamp, mine: mine),
          ],
        ),
      ),
    );
  }
}
