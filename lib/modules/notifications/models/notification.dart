// Represents an in-app notification read from the `notifications` table.
import 'package:banigoba/core/supabase/rows.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final String senderId;
  final Map<String, dynamic>? extraData;
  final bool isRead;
  final DateTime? timestamp;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.senderId,
    this.extraData,
    this.isRead = false,
    this.timestamp,
  });

  factory AppNotification.fromRow(Map<String, dynamic> row) {
    final data = camelizeRow(row);
    final extra = data['extraData'];
    return AppNotification(
      id: (data['id'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      body: (data['body'] ?? '').toString(),
      type: (data['type'] ?? '').toString(),
      senderId: (data['senderId'] ?? '').toString(),
      extraData: extra is Map ? Map<String, dynamic>.from(extra) : null,
      isRead: data['isRead'] == true,
      timestamp: asDateTime(data['createdAt']),
    );
  }
}
