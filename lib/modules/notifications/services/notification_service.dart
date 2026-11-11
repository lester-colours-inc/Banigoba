// User notification data access.
//
// Notifications live in the `notifications` table, one row per recipient, and
// are grouped by type in the UI tabs. extraData carries routing IDs such as
// sellerId, chatId, or designerId so tapping a notification can open the
// right screen. Only the recipient can read, mark or delete a notification.
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/core/supabase/rows.dart';

class NotificationService {
  String get currentUserId => AppAuth.instance.currentUser?.uid ?? '';

  /// The notification types shown on each tab; 'all' shows everything.
  static const Map<String, List<String>> categoryTypes = {
    'friends': [
      'follow_request',
      'follow_accepted',
      'new_post',
      'like',
      'comment',
      'try_on',
      'repost',
      'quote',
    ],
    'shops': [
      'order_update',
      'shop_promo',
      'shop_new_item',
      'shop_message',
      'shop_approval',
    ],
    'designers': [
      'designer_update',
      'designer_collection',
      'designer_message',
      'designer_request_status',
    ],
  };

  /// Types that only drive a push and never show in the inbox: AI job
  /// status ("your look is ready") has no sender and would read "Someone".
  static const Set<String> pushOnlyTypes = {'ai_job'};

  /// Whether a notification row belongs in the inbox and its unread count.
  static bool isInboxRow(Map<String, dynamic> row) =>
      !pushOnlyTypes.contains(row['type']);

  Future<void> addNotification({
    required String receiverId,
    required String title,
    required String body,
    required String type, // 'follow_request', 'follow_accepted', 'new_post'
    Map<String, dynamic>? extraData,
  }) async {
    if (receiverId == currentUserId && type != 'new_post') {
      return; // Don't notify self unless it's a post logic helper
    }

    await supabase.from('notifications').insert({
      'user_id': receiverId,
      'sender_id': currentUserId,
      'title': title,
      'body': body,
      'type': type,
      'extra_data': extraData ?? <String, dynamic>{},
    });
  }

  /// A notification row as the screens read it: camelCase fields, plus `id`,
  /// `timestamp` (a [DateTime]) and `response` (from extraData).
  static Map<String, dynamic> toMap(Map<String, dynamic> row) {
    final data = camelizeRow(row);
    final extra = data['extraData'];
    return {
      ...data,
      'timestamp': asDateTime(data['createdAt']),
      'response': extra is Map ? extra['response'] : null,
    };
  }

  /// The signed-in user's notifications, newest first.
  Stream<List<Map<String, dynamic>>> getNotifications({
    String category = 'all',
  }) {
    if (currentUserId.isEmpty) return Stream.value(const []);
    final types = categoryTypes[category];
    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false)
        .map(
          (rows) => [
            for (final row in rows)
              if (isInboxRow(row) &&
                  (types == null || types.contains(row['type'])))
                toMap(row),
          ],
        );
  }

  Stream<int> getUnreadCount() {
    if (currentUserId.isEmpty) return Stream.value(0);
    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .map(
          (rows) => rows
              .where((row) => isInboxRow(row) && row['is_read'] != true)
              .length,
        );
  }

  Future<void> markAsRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    if (currentUserId.isEmpty) return;
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', currentUserId)
        .eq('is_read', false);
  }

  /// Records how the person answered a notification (e.g. a follow request)
  /// and marks it read.
  Future<void> recordResponse({
    required String notificationId,
    required String response,
  }) async {
    final row = await supabase
        .from('notifications')
        .select('extra_data')
        .eq('id', notificationId)
        .maybeSingle();
    final extra = Map<String, dynamic>.from(row?['extra_data'] as Map? ?? {});
    await supabase
        .from('notifications')
        .update({
          'is_read': true,
          'extra_data': {
            ...extra,
            'response': response,
            'respondedAt': DateTime.now().toUtc().toIso8601String(),
          },
        })
        .eq('id', notificationId);
  }

  // Helper to notify all followers about a new post
  Future<void> notifyFollowersNewPost(String itemName) async {
    if (currentUserId.isEmpty) return;
    final followers = await supabase
        .from('follows')
        .select('follower_id')
        .eq('followee_id', currentUserId);
    final me = await supabase
        .from('profiles')
        .select('display_name')
        .eq('id', currentUserId)
        .maybeSingle();
    final userName = (me?['display_name'] ?? '').toString().isEmpty
        ? (AppAuth.instance.currentUser?.email?.split('@')[0] ?? 'Your friend')
        : me!['display_name'].toString();

    for (final row in followers) {
      await addNotification(
        receiverId: row['follower_id'].toString(),
        title: 'New Post!',
        body: '$userName just added a new item: $itemName',
        type: 'new_post',
        extraData: {'userId': currentUserId, 'fromName': userName},
      );
    }
  }
}
