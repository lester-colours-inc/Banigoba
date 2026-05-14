import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/friend_service.dart';
import 'profile_page.dart';

/// Screen displaying a list of user notifications, including social and shopping updates
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedTabIndex = 0;
  final NotificationService notificationService = NotificationService();
  final FriendService friendService = FriendService();
  static const Color primaryColor = Color(0xFF0D0140);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          _buildAppBarAction(Icons.shopping_bag_outlined, () {}),
          _buildAppBarAction(Icons.chat_bubble_outline, () {}, hasNotification: true),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Notification',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            // Category filter tabs (All, Friends, etc.)
            _buildTabs(),
            const SizedBox(height: 25),
            // The scrollable list of notifications
            Expanded(
              child: _buildNotificationsList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper for building AppBar icons with optional notification dots
  Widget _buildAppBarAction(IconData icon, VoidCallback onTap, {bool hasNotification = false}) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.black, size: 28),
          onPressed: onTap,
        ),
        if (hasNotification)
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  /// Horizontal scrolling category selector
  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabButton("All", 0),
          const SizedBox(width: 15),
          _tabButton("Friends", 1),
          const SizedBox(width: 15),
          _tabButton("Shops", 2),
          const SizedBox(width: 15),
          _tabButton("Designers", 3),
        ],
      ),
    );
  }

  /// Individual tab button widget
  Widget _tabButton(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade100,
            width: 1.5,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  /// Real-time stream of notifications from Firestore
  Widget _buildNotificationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: notificationService.getNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No notifications yet."));

        final notifications = snapshot.data!.docs;

        return ListView.separated(
          itemCount: notifications.length,
          separatorBuilder: (context, index) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            final doc = notifications[index];
            final data = doc.data() as Map<String, dynamic>;
            final bool isRead = data['isRead'] ?? false;
            final String type = data['type'] ?? '';
            final extraData = data['extraData'] as Map<String, dynamic>?;
            final fromName = extraData?['fromName'] as String? ?? 'Someone';

            return GestureDetector(
              onTap: () {
                notificationService.markAsRead(doc.id);
                _handleNotificationTap(context, type, extraData);
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User avatar with unread dot
                  Stack(
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            fromName.isNotEmpty ? fromName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                      ),
                      if (!isRead)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF69B4), // Pink dot
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  // Notification text, timestamp, and action buttons
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black, fontSize: 16),
                            children: [
                              TextSpan(text: fromName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const TextSpan(text: ' '),
                              TextSpan(text: _getNotificationText(type, data['body'])),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _formatTimestamp(data['timestamp'] as Timestamp?),
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        ),
                        // Action buttons for specific notification types (e.g., follow requests)
                        if (type == 'follow_request' && !isRead)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Row(
                              children: [
                                _buildActionMiniButton("Accept", Colors.green, () async {
                                   await friendService.acceptFollowRequest(extraData?['fromId']);
                                   await notificationService.updateNotification(
                                      notificationId: doc.id,
                                      data: {
                                        'body': '$fromName started following you',
                                        'type': 'follow_accepted',
                                        'isRead': true,
                                      },
                                    );
                                }),
                                const SizedBox(width: 10),
                                _buildActionMiniButton("Decline", Colors.red, () async {
                                   await friendService.declineFollowRequest(extraData?['fromId']);
                                   await notificationService.updateNotification(
                                      notificationId: doc.id,
                                      data: {
                                        'body': 'You declined $fromName\'s follow request',
                                        'type': 'request_declined',
                                        'isRead': true,
                                      },
                                    );
                                }, isOutline: true),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Maps internal notification types to user-friendly messages
  String _getNotificationText(String type, String? defaultBody) {
    if (type == 'follow_request') return 'accepted your follow request.';
    if (type == 'follow_accepted') return 'started following you.';
    return defaultBody ?? '';
  }

  /// Small action button helper for notifications (Accept/Decline)
  Widget _buildActionMiniButton(String label, Color color, VoidCallback onTap, {bool isOutline = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isOutline ? Colors.white : color,
          borderRadius: BorderRadius.circular(10),
          border: isOutline ? Border.all(color: color) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isOutline ? color : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  /// Formats the Firestore timestamp into a relative string (e.g., 2m, 5h, 1d)
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "now";
    final dt = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    return "${diff.inDays}d";
  }

  /// Logic for navigating when a notification is tapped
  void _handleNotificationTap(BuildContext context, String type, Map<String, dynamic>? extraData) {
    if (extraData == null) return;
    final userId = extraData['fromId'] ?? extraData['userId'];
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage(userId: userId)),
      );
    }
  }
}
