// Follow, Requested (tap to cancel) or Unfollow, as one pill.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/social/controllers/profile_controller.dart';
import 'package:banigoba/modules/social/widgets/profile_style.dart';

class ProfileFollowButton extends StatelessWidget {
  const ProfileFollowButton({
    super.key,
    required this.controller,
    required this.isFollowing,
  });

  final ProfileController controller;
  final bool isFollowing;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: controller.hasPendingRequest,
      builder: (context, requestSnapshot) {
        final hasRequest = requestSnapshot.data ?? false;
        final ink = profileInk(Theme.of(context).colorScheme);
        void onPressed() => controller.toggleFollow(
          following: isFollowing,
          requested: hasRequest,
        );

        const shape = StadiumBorder();
        const size = Size(200, 46);
        const textStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);
        if (isFollowing) {
          return OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: ink,
              side: BorderSide(color: ink.withValues(alpha: 0.3)),
              shape: shape,
              minimumSize: size,
              textStyle: textStyle,
            ),
            child: const Text('Unfollow'),
          );
        }
        return FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: hasRequest
                ? profileAccent.withValues(alpha: 0.2)
                : profilePrimaryColor,
            foregroundColor: hasRequest ? ink : Colors.white,
            shape: shape,
            minimumSize: size,
            textStyle: textStyle,
          ),
          icon: Icon(
            hasRequest ? Icons.schedule : Icons.person_add_alt_1,
            size: 20,
          ),
          label: Text(hasRequest ? 'Requested' : 'Follow'),
        );
      },
    );
  }
}
