// The notifications list: selected category, which ones are new, and the
// actions on them (open, mark read, accept or decline a follow request).
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/designers/views/fashion_designers_page.dart';
import 'package:banigoba/modules/notifications/models/notification_text.dart';
import 'package:banigoba/modules/notifications/services/notification_router.dart';
import 'package:banigoba/modules/notifications/services/notification_service.dart';
import 'package:banigoba/modules/shop/views/shop_products_page.dart';
import 'package:banigoba/modules/social/services/friend_service.dart';
import 'package:banigoba/modules/social/views/profile_page.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class NotificationsController extends GetxController {
  NotificationsController({
    NotificationService? notifications,
    FriendService? friends,
  }) : service = notifications ?? NotificationService(),
       _friends = friends ?? FriendService();

  final NotificationService service;
  final FriendService _friends;

  final RxInt selectedTab = 0.obs;

  /// Unread when the page opened; stays "New" until opened from here.
  final RxSet<String> newIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _captureUnread();
  }

  void selectTab(int index) => selectedTab.value = index;

  Future<void> _captureUnread() async {
    final userId = AppAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    final unread = await service.getNotifications().first;
    if (isClosed) return;

    newIds.addAll(
      unread
          .where((data) => data['isRead'] != true)
          .map((data) => data['id'].toString()),
    );
  }

  void markOpened(String id) {
    service.markAsRead(id);
    newIds.remove(id);
  }

  /// The notifications on the selected tab (filtered client-side).
  List<Map<String, dynamic>> forSelectedTab(List<Map<String, dynamic>> all) =>
      all
          .where(
            (data) => notificationInTab(
              selectedTab.value,
              (data['type'] ?? '').toString(),
            ),
          )
          .toList();

  /// Opens what the notification is about (shared with push taps).
  Future<void> openTarget(
    BuildContext context,
    String type,
    Map<String, dynamic>? extraData,
  ) => openNotificationTarget(context, type, extraData);

  Future<void> respondToFollowRequest(
    String notificationId,
    String requesterId, {
    required bool accept,
  }) async {
    try {
      if (accept) {
        await _friends.acceptFollowRequest(requesterId);
      } else {
        await _friends.declineFollowRequest(requesterId);
      }
      await service.recordResponse(
        notificationId: notificationId,
        response: accept ? 'accepted' : 'declined',
      );
    } catch (error) {
      if (isClosed) return;
      AppToast.say('Unable to respond to request: $error');
    }
  }

  /// Tapping the sender's name opens their profile, shop or designer page.
  void openName({
    required String type,
    required Map<String, dynamic>? extraData,
    required String? senderId,
    required String displayName,
    required bool useShopIdentity,
  }) {
    if (type == 'designer_request_status' || type == 'designer_message') {
      final designerId = (extraData?['designerId'] ?? '').toString();
      if (designerId.isEmpty) return;
      Get.to<void>(() => DesignerDetailPage(designerId: designerId));
      return;
    }

    if (useShopIdentity) {
      final sellerId = (extraData?['sellerId'] ?? '').toString();
      final shopName = (extraData?['shopName'] ?? displayName)
          .toString()
          .trim();
      if (sellerId.isEmpty) return;
      Get.to<void>(
        () => ShopProductsPage(
          sellerId: sellerId,
          shopName: shopName.isEmpty ? 'Boutique' : shopName,
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
    Get.to<void>(() => ProfilePage(userId: userId));
  }
}
