import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/friend_service.dart';
import 'profile_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationService notificationService = NotificationService();
    final FriendService friendService = FriendService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => notificationService.markAllAsRead(),
            child: const Text("Mark all as read"),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          final notifications = snapshot.data!.docs;

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool isRead = data['isRead'] ?? false;
              final String type = data['type'] ?? '';
              final extraData = data['extraData'] as Map<String, dynamic>?;

              return ListTile(
                tileColor: isRead ? Colors.white : Colors.blue.shade50,
                leading: _getIconForType(type),
                title: Text(
                  data['title'] ?? '',
                  style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['body'] ?? ''),
                    if (data['timestamp'] != null)
                      Text(
                        _formatTimestamp(data['timestamp'] as Timestamp),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    if (type == 'follow_request' && extraData != null && extraData['fromId'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await friendService.acceptFollowRequest(extraData['fromId']);
                                final fromName = extraData['fromName'] ?? 'Someone';
                                await notificationService.updateNotification(
                                  notificationId: doc.id,
                                  data: {
                                    'body': '$fromName started following you',
                                    'type': 'follow_accepted',
                                    'isRead': true,
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(80, 30),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text("Accept", style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () async {
                                await friendService.declineFollowRequest(extraData['fromId']);
                                final fromName = extraData['fromName'] ?? 'Someone';
                                await notificationService.updateNotification(
                                  notificationId: doc.id,
                                  data: {
                                    'body': 'You declined $fromName\'s follow request',
                                    'type': 'request_declined',
                                    'isRead': true,
                                  },
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                minimumSize: const Size(80, 30),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text("Decline", style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  notificationService.markAsRead(doc.id);
                  _handleNotificationTap(context, type, extraData);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _getIconForType(String type) {
    switch (type) {
      case 'follow_request':
        return const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.person_add, color: Colors.white));
      case 'follow_accepted':
        return const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white));
      case 'request_declined':
        return const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.cancel, color: Colors.white));
      case 'new_post':
        return const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.image, color: Colors.white));
      default:
        return const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.notifications, color: Colors.white));
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dt = timestamp.toDate();
    return "${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  void _handleNotificationTap(BuildContext context, String type, Map<String, dynamic>? extraData) {
    if (extraData == null) return;

    if (type == 'follow_request' || type == 'follow_accepted' || type == 'new_post') {
      final userId = extraData['fromId'] ?? extraData['userId'];
      if (userId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage(userId: userId)),
        );
      }
    }
  }
}
