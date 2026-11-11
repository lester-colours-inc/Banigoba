// Represents an in-app notification read from the `notifications` table.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:banigoba/core/supabase/rows.dart';

part 'notification.freezed.dart';

@freezed
abstract class AppNotification with _$AppNotification {
  const AppNotification._();

  const factory AppNotification({
    required String id,
    required String title,
    required String body,
    required String type,
    required String senderId,
    Map<String, dynamic>? extraData,
    @Default(false) bool isRead,
    DateTime? timestamp,
  }) = _AppNotification;

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
