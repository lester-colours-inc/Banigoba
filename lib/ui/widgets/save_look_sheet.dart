// Saves a generated look as a post, so it lands on the user's own timeline,
// then returns to Home. Sharing is the user's choice, never the default.
import 'package:flutter/material.dart';

import '../../core/main_tab.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/post_service.dart';
import '../screens/main/main_screen.dart';

enum SaveLookVisibility { private, share }

/// Asks where the look goes, saves it, and returns to Home on success.
///
/// Returns false when the user cancels or the save fails (a snackbar explains
/// the failure).
Future<bool> saveLookToTimeline(
  BuildContext context, {
  required String imageUrl,
  required String caption,
  PostService? posts,
  NotificationService? notifications,
}) async {
  final visibility = await showModalBottomSheet<SaveLookVisibility>(
    context: context,
    showDragHandle: true,
    builder: (_) => const SaveLookSheet(),
  );
  if (visibility == null || !context.mounted) return false;

  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final isPublic = visibility == SaveLookVisibility.share;

  try {
    await (posts ?? PostService()).createPost(
      caption: caption,
      imageURL: imageUrl,
      isPublic: isPublic,
    );
    if (isPublic) {
      await (notifications ?? NotificationService()).notifyFollowersNewPost(
        caption,
      );
    }
  } on SignInRequiredException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
    return false;
  } on Exception catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Unable to save your look: $error')),
    );
    return false;
  }

  messenger.showSnackBar(
    SnackBar(
      content: Text(
        isPublic
            ? 'Your look is on your timeline and shared with friends and '
                  'community.'
            : 'Your look is saved to My Timeline.',
      ),
    ),
  );
  MainScreen.selectTab(MainTab.home);
  navigator.popUntil((route) => route.isFirst);
  return true;
}

/// The choice between keeping a look private or sharing it.
class SaveLookSheet extends StatelessWidget {
  const SaveLookSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // UNCLEAR: the meeting asked to share "to friends or to the community".
    // Posts are currently either private or public (friends and community
    // together), so this offers one Share option. Splitting it needs a
    // visibility model change (Phase 4).
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
                'Save your look',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              key: const ValueKey('save_look_private'),
              leading: const Icon(Icons.lock_outline),
              title: const Text('Save to My Timeline'),
              subtitle: const Text('Only you can see it. Share it later.'),
              onTap: () => Navigator.pop(context, SaveLookVisibility.private),
            ),
            ListTile(
              key: const ValueKey('save_look_share'),
              leading: const Icon(Icons.public),
              title: const Text('Share with friends and community'),
              subtitle: const Text('It also appears on your timeline.'),
              onTap: () => Navigator.pop(context, SaveLookVisibility.share),
            ),
          ],
        ),
      ),
    );
  }
}
