// Where an already-saved, private post is shared: to friends only, or to the
// whole community. Used from an existing post's Share action on Home.
import 'package:flutter/material.dart';

import '../../data/models/post.dart';

/// Asks which audience should see the post now. Returns null when cancelled.
Future<PostVisibility?> showShareAudienceSheet(BuildContext context) {
  return showModalBottomSheet<PostVisibility>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _ShareAudienceSheet(),
  );
}

class _ShareAudienceSheet extends StatelessWidget {
  const _ShareAudienceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Share your look',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              key: const ValueKey('share_audience_friends'),
              leading: const Icon(Icons.people_alt_outlined),
              title: const Text('Friends'),
              subtitle: const Text(
                'Only your friends can see it, send affirmations and reply.',
              ),
              onTap: () => Navigator.pop(context, PostVisibility.friends),
            ),
            ListTile(
              key: const ValueKey('share_audience_community'),
              leading: const Icon(Icons.public),
              title: const Text('Community'),
              subtitle: const Text(
                'Everyone can see it, send affirmations and reply.',
              ),
              onTap: () => Navigator.pop(context, PostVisibility.public),
            ),
          ],
        ),
      ),
    );
  }
}
