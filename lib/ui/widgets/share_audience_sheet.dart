// Who a post goes out to: friends, followers or the public. Used when sharing
// an already-saved private post, and when reposting or quoting a look.
import 'package:flutter/material.dart';

import '../../data/models/post.dart';

/// Asks which audience should see the post. Returns null when cancelled.
Future<PostVisibility?> showShareAudienceSheet(
  BuildContext context, {
  String title = 'Share your look',
}) {
  return showModalBottomSheet<PostVisibility>(
    context: context,
    showDragHandle: true,
    builder: (_) => _ShareAudienceSheet(title: title),
  );
}

class _ShareAudienceSheet extends StatelessWidget {
  const _ShareAudienceSheet({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              key: const ValueKey('share_audience_friends'),
              leading: const Icon(Icons.people_alt_outlined),
              title: const Text('Friends'),
              subtitle: const Text('Only people you follow who follow you.'),
              onTap: () => Navigator.pop(context, PostVisibility.friends),
            ),
            ListTile(
              key: const ValueKey('share_audience_followers'),
              leading: const Icon(Icons.group_outlined),
              title: const Text('Followers'),
              subtitle: const Text('Everyone who follows you.'),
              onTap: () => Navigator.pop(context, PostVisibility.followers),
            ),
            ListTile(
              key: const ValueKey('share_audience_community'),
              leading: const Icon(Icons.public),
              title: const Text('Public'),
              subtitle: const Text('Everyone on Banigoba can see it.'),
              onTap: () => Navigator.pop(context, PostVisibility.public),
            ),
          ],
        ),
      ),
    );
  }
}
