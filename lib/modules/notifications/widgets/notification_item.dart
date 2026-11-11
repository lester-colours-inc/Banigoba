// One row of the notifications list: avatar, who and what, time, and the
// follow-request buttons.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/notifications/controllers/notifications_controller.dart';
import 'package:banigoba/modules/notifications/models/notification_text.dart';
import 'package:banigoba/modules/notifications/widgets/notification_avatars.dart';
import 'package:banigoba/modules/social/widgets/follow_back_button.dart';

const Color _primaryColor = Color(0xFF0D0140);

class NotificationItem extends StatelessWidget {
  const NotificationItem({
    super.key,
    required this.controller,
    required this.id,
    required this.data,
    required this.isNew,
  });

  final NotificationsController controller;
  final String id;
  final Map<String, dynamic> data;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final String type = data['type'] ?? '';
    final extraData = data['extraData'] as Map<String, dynamic>?;
    final currentUserId = AppAuth.instance.currentUser?.uid ?? '';
    final String? title = data['title']?.toString();
    final String? body = data['body'];
    final fromName = notificationSenderName(
      type: type,
      extraData: extraData,
      currentUserId: currentUserId,
      title: title,
      body: body,
    );
    final actionText = notificationActionText(type, body, actorName: fromName);
    final requesterId = extraData?['fromId'] as String?;
    final senderId =
        (data['senderId'] ?? extraData?['fromId'] ?? extraData?['userId'])
            ?.toString();
    final useShopIdentity = usesShopIdentity(
      type: type,
      extraData: extraData,
      currentUserId: currentUserId,
    );
    final response = data['response'] as String?;
    final timestamp = data['timestamp'] as DateTime?;

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
        controller.markOpened(id);
        controller.openTarget(context, type, extraData);
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
                ? NotificationInitialAvatar(name: fromName)
                : NotificationSenderAvatar(
                    senderId: senderId,
                    fallbackName: fromName,
                  ),
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
                                  ..onTap = () {
                                    controller.markOpened(id);
                                    controller.openName(
                                      type: type,
                                      extraData: extraData,
                                      senderId: senderId,
                                      displayName: fromName,
                                      useShopIdentity: useShopIdentity,
                                    );
                                  },
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
                      formatNotificationTimestamp(timestamp),
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
                          onPressed: () => controller.respondToFollowRequest(
                            id,
                            requesterId,
                            accept: true,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _primaryColor,
                          ),
                          child: Text('Accept'),
                        ),
                        SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => controller.respondToFollowRequest(
                            id,
                            requesterId,
                            accept: false,
                          ),
                          child: Text('Decline'),
                        ),
                      ],
                    )
                  else if (response == 'accepted')
                    // They follow you now; offer to follow them too.
                    Row(
                      children: [
                        const Text(
                          'Accepted',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        FollowBackButton(userId: requesterId),
                      ],
                    )
                  else
                    const Text(
                      'Declined',
                      style: TextStyle(
                        color: Colors.red,
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
}
