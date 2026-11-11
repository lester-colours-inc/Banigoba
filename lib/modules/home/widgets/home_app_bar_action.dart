// Consistent action buttons in Home's app bar: notifications (with the unread
// count) and the cart.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/notifications/services/notification_service.dart';
import 'package:banigoba/modules/shop/widgets/cart_badge_button.dart';

class HomeNotificationsAction extends StatelessWidget {
  const HomeNotificationsAction({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_none_rounded,
            color: colors.onSurface,
            size: 28,
          ),
          onPressed: onPressed,
        ),
        StreamBuilder<int>(
          stream: NotificationService().getUnreadCount(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            if (unreadCount == 0) return const SizedBox.shrink();

            return Positioned(
              right: 5,
              top: 5,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.surface, width: 2),
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
}

class HomeCartAction extends StatelessWidget {
  const HomeCartAction({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CartBadgeButton(
    onPressed: onPressed,
    color: Theme.of(context).colorScheme.onSurface,
  );
}
