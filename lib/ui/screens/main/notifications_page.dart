// Displays social and product notifications and lets users respond to follow requests.
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/app_routes.dart';
import '../../../data/services/notification_service.dart';
import '../../widgets/cart_badge_button.dart';
import '../shop/shop_chat_page.dart';
import '../../../data/services/friend_service.dart';
import '../social/profile_page.dart';
import '../shop/shop_products_page.dart';

/// Screen displaying a list of user notifications, matching the provided designs
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedTabIndex = 0;
  final Set<String> _newNotificationIds = {};
  final NotificationService notificationService = NotificationService();
  final FriendService friendService = FriendService();
  static Color primaryColor = Color(0xFF0D0140);

  @override
  void initState() {
    super.initState();
    _captureNewNotificationsAndClearBell();
  }

  Future<void> _captureNewNotificationsAndClearBell() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    final unread = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    if (!mounted) return;

    setState(() {
      _newNotificationIds.addAll(unread.docs.map((doc) => doc.id));
    });
    await notificationService.markAllAsRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          _buildAppBarAction(
            Icons.shopping_bag_outlined,
            () => Navigator.pushNamed(context, AppRoutes.cart),
          ),
          SizedBox(width: 10),
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          SizedBox(width: 20),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),
          // Category tabs
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: _buildTabs(),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 25.0),
            child: Text(
              'New',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black.withValues(alpha: 0.8),
              ),
            ),
          ),
          SizedBox(height: 15),
          // Scrollable list or empty state
          Expanded(child: _buildNotificationsContent()),
        ],
      ),
    );
  }

  /// Helper for building AppBar icons with optional notification dots
  Widget _buildAppBarAction(
    IconData icon,
    VoidCallback onTap, {
    bool hasNotification = false,
  }) {
    if (icon == Icons.shopping_bag_outlined) {
      return CartBadgeButton(
        onPressed: onTap,
        color: Theme.of(context).colorScheme.onSurface,
      );
    }

    return Stack(
      children: [
        IconButton(
          icon: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurface,
            size: 28,
          ),
          onPressed: onTap,
        ),
        if (hasNotification)
          StreamBuilder<int>(
            stream: notificationService.getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) return SizedBox.shrink();

              return Positioned(
                right: 5,
                top: 5,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
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
          SizedBox(width: 15),
          _tabButton("Friends", 1),
          SizedBox(width: 15),
          _tabButton("Shops", 2),
          SizedBox(width: 15),
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
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.outline,
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
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
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
          if (_selectedTabIndex == 1) {
            // Friends
            return [
              'follow_request',
              'follow_accepted',
              'new_post',
              'like',
              'comment',
            ].contains(type);
          }
          if (_selectedTabIndex == 2) {
            // Shops
            return [
              'order_update',
              'shop_promo',
              'shop_new_item',
            ].contains(type);
          }
          if (_selectedTabIndex == 3) {
            // Designers
            return ['designer_update', 'designer_collection'].contains(type);
          }
          return false;
        }).toList();

        if (filteredNotifications.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          itemCount: filteredNotifications.length,
          separatorBuilder: (context, index) => Divider(
            height: 30,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          itemBuilder: (context, index) {
            final doc = filteredNotifications[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildNotificationItem(
              doc.id,
              data,
              _newNotificationIds.contains(doc.id) || data['isRead'] == false,
            );
          },
        );
      },
    );
  }

  /// Empty state UI shown when no notifications exist
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            SizedBox(height: 25),
            Text(
              "No Notifications",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "We'll let you know when there will be something to update you.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.outline,
                height: 1.5,
              ),
            ),
            SizedBox(height: 100), // Offset from center to match design
          ],
        ),
      ),
    );
  }

  /// Individual notification row widget
  Widget _buildNotificationItem(
    String id,
    Map<String, dynamic> data,
    bool isNew,
  ) {
    final String type = data['type'] ?? '';
    final extraData = data['extraData'] as Map<String, dynamic>?;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final String? title = data['title']?.toString();
    final String? body = data['body'];
    final fromName = _notificationSenderName(
      type: type,
      extraData: extraData,
      currentUserId: currentUserId,
      title: title,
      body: body,
    );
    final actionText = _getNotificationActionText(
      type,
      body,
      actorName: fromName,
    );
    final requesterId = extraData?['fromId'] as String?;
    final senderId =
        (data['senderId'] ?? extraData?['fromId'] ?? extraData?['userId'])
            ?.toString();
    final useShopIdentity = _usesShopIdentity(
      type: type,
      extraData: extraData,
      currentUserId: currentUserId,
    );
    final response = data['response'] as String?;
    final timestamp = data['timestamp'] as Timestamp?;

    // Style elements based on notification type
    IconData? typeIcon;
    Color? iconBgColor;
    bool isSystem = type == 'challenge' || type == 'system';

    if (type == 'challenge') {
      typeIcon = Icons.campaign_rounded;
      iconBgColor = Color(0xFFFFB74D); // Orange
    }

    return GestureDetector(
      onTap: () {
        notificationService.markAsRead(id);
        setState(() => _newNotificationIds.remove(id));
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
            useShopIdentity
                ? _buildInitialAvatar(fromName)
                : _buildSenderAvatar(senderId, fromName),
          SizedBox(width: 15),
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
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                          children: [
                            if (fromName.isNotEmpty) ...[
                              TextSpan(
                                text: fromName,
                                style: TextStyle(fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _openNotificationName(
                                    type: type,
                                    extraData: extraData,
                                    senderId: senderId,
                                    displayName: fromName,
                                    useShopIdentity: useShopIdentity,
                                  ),
                              ),
                              TextSpan(text: ' '),
                            ],
                            TextSpan(
                              text: actionText,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (isNew)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'New',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (type == 'like')
                  Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Icon(Icons.favorite, color: Colors.red, size: 16),
                  ),
                if (type == 'follow_accepted' ||
                    type == 'follow_request' ||
                    type == 'new_post')
                  Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text(
                      type == 'new_post'
                          ? 'Check out their latest style!'
                          : 'Welcome to the Banigoba family',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                if (type == 'follow_request' && requesterId != null) ...[
                  SizedBox(height: 10),
                  if (response == null)
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () =>
                              _respondToFollowRequest(id, requesterId, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                          ),
                          child: Text('Accept'),
                        ),
                        SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () =>
                              _respondToFollowRequest(id, requesterId, false),
                          child: Text('Decline'),
                        ),
                      ],
                    )
                  else
                    Text(
                      response == 'accepted' ? 'Accepted' : 'Declined',
                      style: TextStyle(
                        color: response == 'accepted'
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
                if (type == 'challenge')
                  Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text(
                      'is now live. Enter to win fashion prizes!',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderAvatar(String? senderId, String fallbackName) {
    if (senderId == null || senderId.isEmpty) {
      return _buildInitialAvatar(fallbackName);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name = (data?['displayName'] ?? fallbackName).toString();
        final imageUrl =
            (data?['profileImageURL'] ?? data?['profileImageUrl'] ?? '')
                .toString();

        if (imageUrl.isEmpty) return _buildInitialAvatar(name);

        return Container(
          width: 50,
          height: 50,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.orange.shade200, width: 2),
          ),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildInitialAvatar(name, includeBorder: false),
          ),
        );
      },
    );
  }

  Widget _buildInitialAvatar(String name, {bool includeBorder = true}) {
    final normalizedName = name.trim();
    final initial = normalizedName.isEmpty
        ? 'U'
        : normalizedName.substring(0, 1).toUpperCase();
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: primaryColor,
        shape: BoxShape.circle,
        border: includeBorder
            ? Border.all(color: Colors.orange.shade200, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _respondToFollowRequest(
    String notificationId,
    String requesterId,
    bool accept,
  ) async {
    try {
      if (accept) {
        await friendService.acceptFollowRequest(requesterId);
      } else {
        await friendService.declineFollowRequest(requesterId);
      }
      await notificationService.updateNotification(
        notificationId: notificationId,
        data: {
          'response': accept ? 'accepted' : 'declined',
          'isRead': true,
          'respondedAt': FieldValue.serverTimestamp(),
        },
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to respond to request: $error')),
      );
    }
  }

  /// Maps internal notification types to specific action strings
  String _notificationSenderName({
    required String type,
    required Map<String, dynamic>? extraData,
    required String currentUserId,
    required String? title,
    required String? body,
  }) {
    final defaultName = (extraData?['fromName'] ?? 'Someone').toString();
    final shopName = (extraData?['shopName'] ?? '').toString();
    final sellerId = (extraData?['sellerId'] ?? '').toString();

    if (type == 'order_update') {
      if (shopName.isNotEmpty && sellerId != currentUserId) return shopName;
      final titleName = (title ?? '').trim();
      if (titleName.isNotEmpty &&
          titleName != 'Order update' &&
          titleName != 'New order') {
        return titleName;
      }
      final bodyName = _nameFromNotificationBody(body);
      if (bodyName.isNotEmpty) return bodyName;
      if (defaultName == 'Someone' && body?.trim().isNotEmpty == true) {
        return '';
      }
    }

    if (type == 'shop_message' &&
        shopName.isNotEmpty &&
        _usesShopIdentity(
          type: type,
          extraData: extraData,
          currentUserId: currentUserId,
        )) {
      return shopName;
    }
    return defaultName;
  }

  bool _usesShopIdentity({
    required String type,
    required Map<String, dynamic>? extraData,
    required String currentUserId,
  }) {
    final shopName = (extraData?['shopName'] ?? '').toString();
    final sellerId = (extraData?['sellerId'] ?? '').toString();
    final fromId = (extraData?['fromId'] ?? '').toString();

    if (shopName.isEmpty) return false;
    if (type == 'order_update') return sellerId != currentUserId;
    if (type == 'shop_message') {
      return sellerId.isNotEmpty &&
          sellerId != currentUserId &&
          (fromId.isEmpty || fromId == sellerId);
    }
    return false;
  }

  String _getNotificationActionText(
    String type,
    String? defaultBody, {
    String actorName = '',
  }) {
    switch (type) {
      case 'like':
        return 'liked your Daily Dress Up.';
      case 'comment':
        return 'commented on your Daily Dress Up.';
      case 'shop_message':
        return 'sent you a shop message.';
      case 'order_update':
        return _stripActorName(defaultBody, actorName) ?? 'updated your order.';
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

  String _nameFromNotificationBody(String? body) {
    final text = body?.trim() ?? '';
    if (text.isEmpty) return '';

    for (final marker in [' updated your order', ' placed order']) {
      final index = text.toLowerCase().indexOf(marker);
      if (index > 0) return text.substring(0, index).trim();
    }
    return '';
  }

  String? _stripActorName(String? body, String actorName) {
    final text = body?.trim();
    if (text == null || text.isEmpty) return null;
    final actor = actorName.trim();
    if (actor.isNotEmpty &&
        text.toLowerCase().startsWith(actor.toLowerCase())) {
      return text.substring(actor.length).trim();
    }
    return text;
  }

  void _openNotificationName({
    required String type,
    required Map<String, dynamic>? extraData,
    required String? senderId,
    required String displayName,
    required bool useShopIdentity,
  }) {
    if (useShopIdentity) {
      final sellerId = (extraData?['sellerId'] ?? '').toString();
      final shopName = (extraData?['shopName'] ?? displayName)
          .toString()
          .trim();
      if (sellerId.isEmpty) return;
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ShopProductsPage(
            sellerId: sellerId,
            shopName: shopName.isEmpty ? 'Boutique' : shopName,
          ),
        ),
      );
      return;
    }

    final userId =
        (senderId ??
                extraData?['fromId'] ??
                extraData?['userId'] ??
                extraData?['customerId'] ??
                '')
            .toString();
    if (userId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => ProfilePage(userId: userId)),
    );
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
  Future<void> _handleNotificationTap(
    BuildContext context,
    String type,
    Map<String, dynamic>? extraData,
  ) async {
    if (extraData == null) return;
    if (type == 'shop_message' || type == 'order_update') {
      final chatId = (extraData['chatId'] ?? '').toString();
      if (chatId.isEmpty) return;
      final chat = await FirebaseFirestore.instance
          .collection('shop_chats')
          .doc(chatId)
          .get();
      if (!context.mounted || !chat.exists) return;
      final data = chat.data() ?? const <String, dynamic>{};
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final asSeller = data['sellerId'] == currentUserId;
      final title = asSeller
          ? (data['customerName'] ?? 'Customer').toString()
          : (data['shopName'] ?? 'Boutique').toString();
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              ShopChatPage(chatId: chatId, title: title, asSeller: asSeller),
        ),
      );
      return;
    }
    final userId = extraData['fromId'] ?? extraData['userId'];
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage(userId: userId)),
      );
    }
  }
}
