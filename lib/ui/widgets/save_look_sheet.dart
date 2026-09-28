// Where a finished look goes: a post on the timeline (kept private, shared
// with friends, or shared with the whole community), or straight to the
// Wardrobe to wear again later — no post, no audience. Sharing is the user's
// choice, never the default.
//
// When the look is an edit of a saved post, the user can also update that
// post in place instead of adding a second one.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/main_tab.dart';
import '../../data/models/post.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/outfit_service.dart';
import '../../data/services/post_service.dart';
import '../screens/main/main_screen.dart';

enum SaveLookVisibility { replace, private, wardrobe, friends, community }

/// Asks where the look goes, saves it, and returns to Home (or the Wardrobe)
/// on success.
///
/// [replacePostId] is the post being edited, if any; it adds the option to
/// update that post rather than create a new one. [avatarImageUrl] is the
/// photo the look started from; the Wardrobe destination keeps it alongside
/// the result so the look can be told apart from others later.
///
/// Returns false when the user cancels or the save fails (a snackbar explains
/// the failure).
Future<bool> saveLookToTimeline(
  BuildContext context, {
  required String imageUrl,
  required String caption,
  String? replacePostId,
  String? avatarImageUrl,
  PostService? posts,
  OutfitService? outfits,
  NotificationService? notifications,
}) async {
  final visibility = await showModalBottomSheet<SaveLookVisibility>(
    context: context,
    showDragHandle: true,
    builder: (_) => SaveLookSheet(canReplace: replacePostId != null),
  );
  if (visibility == null || !context.mounted) return false;

  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  try {
    switch (visibility) {
      case SaveLookVisibility.replace:
        if (replacePostId != null) {
          await (posts ?? PostService()).updatePostImage(
            replacePostId,
            imageUrl,
          );
        } else {
          // The sheet only offers this when a post is being edited; this is
          // just a safe fallback if it is ever reached without one.
          await (posts ?? PostService()).createPost(
            caption: caption,
            imageURL: imageUrl,
          );
        }
      case SaveLookVisibility.private:
        await (posts ?? PostService()).createPost(
          caption: caption,
          imageURL: imageUrl,
        );
      case SaveLookVisibility.friends:
        await (posts ?? PostService()).createPost(
          caption: caption,
          imageURL: imageUrl,
          visibility: PostVisibility.friends,
        );
      case SaveLookVisibility.community:
        await (posts ?? PostService()).createPost(
          caption: caption,
          imageURL: imageUrl,
          visibility: PostVisibility.public,
        );
        // Only a community share goes out to everyone who follows the user;
        // a friends-only share stays quiet.
        await (notifications ?? NotificationService()).notifyFollowersNewPost(
          caption,
        );
      case SaveLookVisibility.wardrobe:
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) throw const SignInRequiredException();
        await (outfits ?? OutfitService()).saveOutfit(
          userId: userId,
          avatarImageUrl: avatarImageUrl ?? imageUrl,
          resultImageUrl: imageUrl,
          products: const [],
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
      content: Text(switch (visibility) {
        SaveLookVisibility.replace => 'Your look has been updated.',
        SaveLookVisibility.friends => 'Your look is shared with friends.',
        SaveLookVisibility.community =>
          'Your look is on your timeline and shared with the community.',
        SaveLookVisibility.private => 'Your look is saved to My Timeline.',
        SaveLookVisibility.wardrobe => 'Your look is saved to your wardrobe.',
      }),
    ),
  );
  MainScreen.selectTab(
    visibility == SaveLookVisibility.wardrobe ? MainTab.wardrobe : MainTab.home,
  );
  navigator.popUntil((route) => route.isFirst);
  return true;
}

/// The choice between keeping a look private, wearing it from the wardrobe,
/// or sharing it with friends or the community.
class SaveLookSheet extends StatelessWidget {
  const SaveLookSheet({super.key, this.canReplace = false});

  /// Offers "Update the original" first, for an edited saved look.
  final bool canReplace;

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
                'Save your look',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (canReplace)
              ListTile(
                key: const ValueKey('save_look_replace'),
                leading: const Icon(Icons.published_with_changes),
                title: const Text('Update the original'),
                subtitle: const Text('Replace the saved look with this one.'),
                onTap: () => Navigator.pop(context, SaveLookVisibility.replace),
              ),
            ListTile(
              key: const ValueKey('save_look_private'),
              leading: const Icon(Icons.lock_outline),
              title: Text(
                canReplace ? 'Save as a new look' : 'Save to My Timeline',
              ),
              subtitle: const Text('Only you can see it. Share it later.'),
              onTap: () => Navigator.pop(context, SaveLookVisibility.private),
            ),
            ListTile(
              key: const ValueKey('save_look_wardrobe'),
              leading: const Icon(Icons.checkroom_outlined),
              title: const Text('Save to Wardrobe'),
              subtitle: const Text('Keep it to wear again. Not posted.'),
              onTap: () => Navigator.pop(context, SaveLookVisibility.wardrobe),
            ),
            ListTile(
              key: const ValueKey('save_look_friends'),
              leading: const Icon(Icons.people_alt_outlined),
              title: const Text('Share with friends'),
              subtitle: const Text('Only your friends can see it.'),
              onTap: () => Navigator.pop(context, SaveLookVisibility.friends),
            ),
            ListTile(
              key: const ValueKey('save_look_community'),
              leading: const Icon(Icons.public),
              title: const Text('Share with community'),
              subtitle: const Text('Everyone can see it.'),
              onTap: () => Navigator.pop(context, SaveLookVisibility.community),
            ),
          ],
        ),
      ),
    );
  }
}
