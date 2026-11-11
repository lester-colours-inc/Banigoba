// Commenting on a look: posting a comment, removing or reporting one, and the
// one-tap quick replies on feed cards.
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/utils/text_moderation.dart';
import 'package:banigoba/modules/social/models/post.dart';
import 'package:banigoba/modules/social/services/post_service.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

/// Posts [text] as the signed-in user's comment on [post].
///
/// Shared by the comments sheet and the quick-reply strip on feed cards so
/// both write identical comment documents. Throws if nobody is signed in.
Future<void> sendPostComment(
  Post post,
  String text, {
  PostService? postService,
}) async {
  final user = AppAuth.instance.currentUser;
  if (user == null) throw StateError('Sign in to reply.');

  final userData = await ProfileService().get(user.uid);
  final username = (userData['displayName'] ?? user.displayName ?? 'User')
      .toString();
  final profileImageUrl = (userData['profileImageUrl'] ?? user.photoURL ?? '')
      .toString();

  await (postService ?? PostService()).addComment(
    postId: post.id,
    text: text,
    username: username,
    profileImageURL: profileImageUrl,
  );
}

class PostCommentsController extends GetxController {
  PostCommentsController({required this.post, PostService? postService})
    : service = postService ?? PostService();

  final Post post;
  final PostService service;
  final RxBool sending = false.obs;

  Future<void> sendComment(String preset) async {
    final text = preset.trim();
    if (text.isEmpty || sending.value) return;

    sending.value = true;
    try {
      await sendPostComment(post, text, postService: service);
    } on ModerationException catch (error) {
      if (isClosed) return;
      AppToast.say(error.message);
    } catch (error) {
      if (isClosed) return;
      AppToast.say('Unable to add comment: $error');
    } finally {
      if (!isClosed) sending.value = false;
    }
  }

  Future<void> removeComment(String commentId) =>
      _act(() => service.deleteComment(commentId), 'Comment removed.');

  Future<void> reportComment(String commentId) => _act(
    () => service.reportComment(commentId),
    'Thanks for telling us. We will take a look.',
  );

  Future<void> _act(Future<void> Function() action, String done) async {
    try {
      await action();
      AppToast.say(done);
    } on Exception catch (error) {
      AppToast.say('That did not work: $error');
    }
  }
}

class PostQuickRepliesController extends GetxController {
  PostQuickRepliesController({required this.post});

  final Post post;
  final RxBool sending = false.obs;

  Future<void> reply(String text) async {
    if (sending.value) return;
    sending.value = true;
    try {
      await sendPostComment(post, text);
      AppToast.say('Replied "$text"');
    } catch (error) {
      AppToast.say('Unable to send reply: $error');
    } finally {
      if (!isClosed) sending.value = false;
    }
  }
}
