// "Follow back" for someone who follows you. Every follow is a request, so
// this sends one; it then reads Requested, and Following once accepted.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/social/controllers/follow_back_controller.dart';
import 'package:banigoba/modules/social/services/friend_service.dart';

class FollowBackButton extends StatelessWidget {
  const FollowBackButton({super.key, required this.userId, this.friends});

  final String userId;

  /// Injected in tests; the app's service otherwise.
  final FriendService? friends;

  @override
  Widget build(BuildContext context) {
    // Scoped to this button: created and disposed with the widget.
    return GetBuilder<FollowBackController>(
      init: FollowBackController(userId: userId, friends: friends),
      global: false,
      builder: (controller) => StreamBuilder<bool>(
        stream: controller.isFollowing,
        builder: (context, following) => StreamBuilder<bool>(
          stream: controller.isRequested,
          builder: (context, requested) {
            if (!following.hasData || !requested.hasData) {
              return const SizedBox.shrink();
            }
            if (following.data == true) {
              return _settled(context, 'Following');
            }
            if (requested.data == true) {
              return _settled(context, 'Requested');
            }
            return Obx(
              () => FilledButton(
                onPressed: controller.sending.value
                    ? null
                    : controller.followBack,
                child: const Text('Follow back'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _settled(BuildContext context, String label) => OutlinedButton(
    onPressed: null,
    child: Text(
      label,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}
