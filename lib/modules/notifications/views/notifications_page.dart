// Displays social and product notifications and lets users respond to follow requests.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/modules/notifications/controllers/notifications_controller.dart';
import 'package:banigoba/modules/notifications/widgets/notification_item.dart';
import 'package:banigoba/modules/notifications/widgets/notification_tabs.dart';
import 'package:banigoba/modules/notifications/widgets/notifications_empty_state.dart';
import 'package:banigoba/modules/shop/widgets/cart_badge_button.dart';
import 'package:banigoba/shared/widgets/menu_or_back_button.dart';

/// Screen displaying a list of user notifications, matching the provided designs
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: created and disposed with the widget.
    return GetBuilder<NotificationsController>(
      init: NotificationsController(),
      global: false,
      builder: (controller) => _NotificationsView(controller: controller),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView({required this.controller});

  final NotificationsController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: const MenuOrBackButton(),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          CartBadgeButton(
            onPressed: () => Get.toNamed<void>(AppRoutes.cart),
            color: colors.onSurface,
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: NotificationTabs(controller: controller),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
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
          Expanded(child: _NotificationsContent(controller: controller)),
        ],
      ),
    );
  }
}

/// Switches between loading, empty, and list states.
class _NotificationsContent extends StatelessWidget {
  const _NotificationsContent({required this.controller});

  final NotificationsController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: controller.service.getNotifications(category: 'all'),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Notifications error: ${snapshot.error}');
          return Center(
            child: Text(
              'Error loading notifications. Please try again.',
              style: TextStyle(color: colors.outline),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const NotificationsEmptyState();
        }

        return Obx(() {
          final filtered = controller.forSelectedTab(snapshot.data!);
          if (filtered.isEmpty) return const NotificationsEmptyState();
          final newIds = controller.newIds.toSet();
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            itemCount: filtered.length,
            separatorBuilder: (context, index) =>
                Divider(height: 30, color: colors.outlineVariant),
            itemBuilder: (context, index) {
              final data = filtered[index];
              final id = data['id'].toString();
              return NotificationItem(
                controller: controller,
                id: id,
                data: data,
                isNew: newIds.contains(id) || data['isRead'] == false,
              );
            },
          );
        });
      },
    );
  }
}
