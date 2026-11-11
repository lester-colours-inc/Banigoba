// Small pieces of the chat screens: titles, timestamps, date separators.
import 'package:flutter/material.dart';

class ConversationTitle extends StatelessWidget {
  const ConversationTitle(this.title, {required this.bold});

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

class MessageTimestamp extends StatelessWidget {
  const MessageTimestamp({
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

class ConversationTrailing extends StatelessWidget {
  const ConversationTrailing({required this.timestamp, required this.unread});

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

class MessageDateSeparator extends StatelessWidget {
  const MessageDateSeparator(this.label);

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
