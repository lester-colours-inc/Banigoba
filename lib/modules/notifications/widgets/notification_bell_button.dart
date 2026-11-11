// The notifications bell for app bars: opens the inbox and shows how many
// notifications are unread.
import 'package:flutter/material.dart';

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/notifications/services/notification_service.dart';

class NotificationBellButton extends StatefulWidget {
  const NotificationBellButton({
    super.key,
    this.color,
    this.iconSize = 28,
    this.unreadCount,
  });

  final Color? color;
  final double iconSize;

  /// The unread count to show; defaults to the signed-in user's.
  final Stream<int>? unreadCount;

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  static const _maxShown = 9;

  // Created once so a rebuild does not open a new realtime subscription.
  late final Stream<int>? _unread =
      widget.unreadCount ??
      (AppAuth.instance.currentUser == null
          ? null
          : NotificationService().getUnreadCount());

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final button = IconButton(
      tooltip: 'Notifications',
      onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
      icon: Icon(
        Icons.notifications_none_rounded,
        color: widget.color ?? colors.onSurface,
        size: widget.iconSize,
      ),
    );
    final unread = _unread;
    // No badge without a backend (widget tests and previews).
    if (unread == null) return button;

    return StreamBuilder<int>(
      stream: unread,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            button,
            if (count > 0)
              Positioned(
                right: 5,
                top: 5,
                child: IgnorePointer(
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.surface, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      count > _maxShown ? '$_maxShown+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
