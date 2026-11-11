import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/social/models/post.dart';
import 'package:banigoba/core/utils/text_moderation.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/modules/social/services/post_service.dart';
import 'package:banigoba/modules/social/widgets/quick_reply_bar.dart';
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

Future<void> showPostCommentsSheet(BuildContext context, Post post) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PostCommentsSheet(post: post),
  );
}

class _PostCommentsSheet extends StatefulWidget {
  const _PostCommentsSheet({required this.post});

  final Post post;

  @override
  State<_PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<_PostCommentsSheet> {
  final _postService = PostService();
  bool _isSending = false;

  Future<void> _sendComment(String preset) async {
    final text = preset.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await sendPostComment(widget.post, text, postService: _postService);
    } on ModerationException catch (error) {
      if (!mounted) return;
      AppToast.say(error.message);
    } catch (error) {
      if (!mounted) return;
      AppToast.say('Unable to add comment: $error');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _act(Future<void> Function() action, String done) async {
    try {
      await action();
      AppToast.say(done);
    } on Exception catch (error) {
      AppToast.say('That did not work: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AppAuth.instance.currentUser;
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: colors.outlineVariant,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<PostComment>>(
              stream: _postService.getComments(widget.post.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Comments could not be loaded.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!;
                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      'No comments yet. Start the conversation.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CommentAvatar(comment: comment),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        comment.username,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTime(comment.createdAt),
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                    if (user != null)
                                      _CommentMenu(
                                        key: ValueKey(
                                          'comment_menu_${comment.id}',
                                        ),
                                        canRemove:
                                            comment.authorId == user.uid ||
                                            widget.post.authorId == user.uid,
                                        onRemove: () => _act(
                                          () => _postService.deleteComment(
                                            comment.id,
                                          ),
                                          'Comment removed.',
                                        ),
                                        onReport: () => _act(
                                          () => _postService.reportComment(
                                            comment.id,
                                          ),
                                          'Thanks for telling us. We will take a look.',
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(comment.text),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: user == null
                ? const Text('Sign in to reply.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tap a reply to send it',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      QuickReplyBar(
                        wrap: true,
                        isSending: _isSending,
                        onSelected: _sendComment,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.isNegative || difference.inMinutes < 1) return 'Now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({required this.comment});

  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    final imageUrl = comment.profileImageURL.trim();
    final username = comment.username.trim();
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFF0D0140),
      backgroundImage: imageUrl.isEmpty
          ? null
          : CachedNetworkImageProvider(imageUrl),
      child: imageUrl.isEmpty
          ? Text(
              username.isEmpty ? 'U' : username[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}

/// Quick-reply strip for a feed card: one tap posts a preset comment.
class PostQuickReplies extends StatefulWidget {
  const PostQuickReplies({super.key, required this.post});

  final Post post;

  @override
  State<PostQuickReplies> createState() => _PostQuickRepliesState();
}

class _PostQuickRepliesState extends State<PostQuickReplies> {
  bool _isSending = false;

  Future<void> _reply(String text) async {
    if (_isSending) return;
    setState(() => _isSending = true);
    try {
      await sendPostComment(widget.post, text);
      AppToast.say('Replied "$text"');
    } catch (error) {
      AppToast.say('Unable to send reply: $error');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return QuickReplyBar(isSending: _isSending, onSelected: _reply);
  }
}

/// The small menu on a comment: remove it (its author, or the look's owner) or
/// report it (everyone else).
class _CommentMenu extends StatelessWidget {
  const _CommentMenu({
    super.key,
    required this.canRemove,
    required this.onRemove,
    required this.onReport,
  });

  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 24,
      child: PopupMenuButton<bool>(
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: const Icon(Icons.more_horiz),
        tooltip: 'More',
        onSelected: (remove) => remove ? onRemove() : onReport(),
        itemBuilder: (_) => [
          if (canRemove)
            const PopupMenuItem(value: true, child: Text('Remove comment')),
          if (!canRemove)
            const PopupMenuItem(value: false, child: Text('Report as unkind')),
        ],
      ),
    );
  }
}
