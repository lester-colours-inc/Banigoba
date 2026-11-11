// Round avatars for a notification's sender: their photo, or an initial.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

const Color _primaryColor = Color(0xFF0D0140);

/// The sender's profile photo (live), or their initial when they have none.
class NotificationSenderAvatar extends StatelessWidget {
  const NotificationSenderAvatar({
    super.key,
    required this.senderId,
    required this.fallbackName,
  });

  final String? senderId;
  final String fallbackName;

  @override
  Widget build(BuildContext context) => _senderAvatar(senderId, fallbackName);
}

/// A navy circle with [name]'s first letter.
class NotificationInitialAvatar extends StatelessWidget {
  const NotificationInitialAvatar({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => _initialAvatar(name);
}

Widget _senderAvatar(String? senderId, String fallbackName) {
  if (senderId == null || senderId.isEmpty) {
    return _initialAvatar(fallbackName);
  }

  return StreamBuilder<Map<String, dynamic>>(
    stream: ProfileService().watch(senderId),
    builder: (context, snapshot) {
      final data = snapshot.data;
      final name = (data?['displayName'] ?? fallbackName).toString();
      final imageUrl = (data?['profileImageUrl'] ?? '').toString();

      if (imageUrl.isEmpty) return _initialAvatar(name);

      return Container(
        width: 50,
        height: 50,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.orange.shade200, width: 2),
        ),
        child: AppNetworkImage(
          imageUrl,
          fit: BoxFit.cover,
          fallback: _initialAvatar(name, includeBorder: false),
        ),
      );
    },
  );
}

Widget _initialAvatar(String name, {bool includeBorder = true}) {
  final normalizedName = name.trim();
  final initial = normalizedName.isEmpty
      ? 'U'
      : normalizedName.substring(0, 1).toUpperCase();
  return Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      color: _primaryColor,
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
