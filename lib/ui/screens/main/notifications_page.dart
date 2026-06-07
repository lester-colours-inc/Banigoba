// Displays social and product notifications and lets users respond to follow requests.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/friend_service.dart';
import '../social/profile_page.dart';

/// Screen displaying a list of user notifications, matching the provided designs
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
  void initState() {
    super.initState();
    // Mark all as read when opening the page
    notificationService.markAllAsRead();
  }

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
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          _buildAppBarAction(Icons.shopping_bag_outlined, () {}, hasNotification: true),
          const SizedBox(width: 10),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // Category tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _buildTabs(),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Text(
              'New',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 15),
          // Scrollable list or empty state
          Expanded(
            child: _buildNotificationsContent(),
          ),
        ],
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
          StreamBuilder<int>(
            stream: notificationService.getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) return const SizedBox.shrink();

              return Positioned(
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
              );
            },
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
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade400,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Manages switching between loading, empty, and list states
  Widget _buildNotificationsContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: notificationService.getNotifications(category: 'all'),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("Firestore Error: ${snapshot.error}");
          return Center(
            child: Text(
              "Error loading notifications. Please try again.",
              style: TextStyle(color: Colors.grey.shade400),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        // Filter notifications client-side based on the selected tab
        final allNotifications = snapshot.data!.docs;
        final filteredNotifications = allNotifications.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final type = data['type'] ?? '';

          if (_selectedTabIndex == 0) return true; // All
          if (_selectedTabIndex == 1) { // Friends
            return ['follow_request', 'follow_accepted', 'new_post', 'like', 'comment'].contains(type);
          }
          if (_selectedTabIndex == 2) { // Shops
            return ['order_update', 'shop_promo', 'shop_new_item'].contains(type);
          }
          if (_selectedTabIndex == 3) { // Designers
            return ['designer_update', 'designer_collection'].contains(type);
          }
          return false;
        }).toList();

        if (filteredNotifications.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          itemCount: filteredNotifications.length,
          separatorBuilder: (context, index) => const Divider(height: 30, color: Color(0xFFF5F5F5)),
          itemBuilder: (context, index) {
            final doc = filteredNotifications[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildNotificationItem(doc.id, data);
          },
        );
      },
    );
  }

  /// Empty state UI shown when no notifications exist
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 80,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 25),
            const Text(
              "No Notifications",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "We'll let you know when there will be something to update you.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 100), // Offset from center to match design
          ],
        ),
      ),
    );
  }

  /// Individual notification row widget
  Widget _buildNotificationItem(String id, Map<String, dynamic> data) {
    final String type = data['type'] ?? '';
    final extraData = data['extraData'] as Map<String, dynamic>?;
    final fromName = extraData?['fromName'] as String? ?? 'Someone';
    final String? body = data['body'];
    final timestamp = data['timestamp'] as Timestamp?;

    // Style elements based on notification type
    IconData? typeIcon;
    Color? iconBgColor;
    bool isSystem = type == 'challenge' || type == 'system';

    if (type == 'challenge') {
      typeIcon = Icons.campaign_rounded;
      iconBgColor = const Color(0xFFFFB74D); // Orange
    }

    return GestureDetector(
      onTap: () {
        notificationService.markAsRead(id);
        _handleNotificationTap(context, type, extraData);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar or Icon
          if (isSystem)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(typeIcon, color: Colors.white, size: 28),
            )
          else
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.shade200, width: 2),
              ),
              child: const CircleAvatar(
                backgroundImage: NetworkImage(''),
              ),
            ),
          const SizedBox(width: 15),
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                          children: [
                            TextSpan(
                              text: fromName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: _getNotificationActionText(type, body),
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ],
                ),
                if (type == 'like')
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Icon(Icons.favorite, color: Colors.red, size: 16),
                  ),
                if (type == 'follow_accepted' || type == 'follow_request' || type == 'new_post')
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      type == 'new_post' ? 'Check out their latest style!' : 'Welcome to the Banigoba family',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                if (type == 'challenge')
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'is now live. Enter to win fashion prizes!',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Maps internal notification types to specific action strings
  String _getNotificationActionText(String type, String? defaultBody) {
    switch (type) {
      case 'like':
        return 'liked our Try On look!';
      case 'follow_request':
        return 'wants to follow you.';
      case 'follow_accepted':
        return 'accepted your follow request.';
      case 'new_post':
        return 'just added a new item.';
      case 'challenge':
        return 'New contest alert!';
      default:
        return defaultBody ?? '';
    }
  }

  /// Formats the Firestore timestamp into a relative string (e.g., 4h ago, 13d ago)
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "now";
    final dt = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
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
