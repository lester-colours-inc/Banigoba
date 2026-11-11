// Times and shapes shared by the shop chat screens.
import 'package:flutter/painting.dart';

import 'package:banigoba/core/supabase/rows.dart';

String formatConversationTimestamp(Map<String, dynamic> data) {
  final dateTime = conversationDateTime(data);
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

DateTime? conversationDateTime(Map<String, dynamic> data) {
  final value = data['lastMessageAt'] ?? data['updatedAt'] ?? data['createdAt'];
  return asDateTime(value);
}

String formatMessageTimestamp(Map<String, dynamic> data) {
  final dateTime = messageDateTime(data);
  if (dateTime == null) return '';

  final local = dateTime.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

DateTime? messageDateTime(Map<String, dynamic> data) {
  final value = data['createdAt'];
  return asDateTime(value);
}

String formatMessageDateLabel(Map<String, dynamic> data) {
  final dateTime = messageDateTime(data);
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

bool isSameMessageDay(Map<String, dynamic> first, Map<String, dynamic> second) {
  final firstDate = messageDateTime(first)?.toLocal();
  final secondDate = messageDateTime(second)?.toLocal();
  if (firstDate == null || secondDate == null) return false;
  return firstDate.year == secondDate.year &&
      firstDate.month == secondDate.month &&
      firstDate.day == secondDate.day;
}

BorderRadius messageBubbleRadius(bool mine) {
  return BorderRadius.only(
    topLeft: const Radius.circular(18),
    topRight: const Radius.circular(18),
    bottomLeft: Radius.circular(mine ? 18 : 5),
    bottomRight: Radius.circular(mine ? 5 : 18),
  );
}
