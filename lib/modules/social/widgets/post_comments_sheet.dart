import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/social/models/post.dart';
import 'package:banigoba/modules/social/controllers/post_comments_controller.dart';
import 'package:banigoba/modules/social/widgets/quick_reply_bar.dart';

export 'package:banigoba/modules/social/controllers/post_comments_controller.dart'
    show sendPostComment;

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

class _PostCommentsSheet extends StatelessWidget {
  const _PostCommentsSheet({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    // Scoped to this sheet: created and disposed with the widget.
    return GetBuilder<PostCommentsController>(
      init: PostCommentsController(post: post),
      global: false,
      builder: (controller) => _CommentsView(controller: controller),
    );
  }
}

class _CommentsView extends StatelessWidget {
  const _CommentsView({required this.controller});

  final PostCommentsController controller;

  Post get post => controller.post;

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
              stream: controller.service.getComments(post.id),
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
                                            post.authorId == user.uid,
                                        onRemove: () => controller
                                            .removeComment(comment.id),
                                        onReport: () => controller
                                            .reportComment(comment.id),
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
                      Obx(
                        () => QuickReplyBar(
                          wrap: true,
                          isSending: controller.sending.value,
                          onSelected: controller.sendComment,
                        ),
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
class PostQuickReplies extends StatelessWidget {
  const PostQuickReplies({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    // Scoped to this strip: created and disposed with the widget.
    return GetBuilder<PostQuickRepliesController>(
      init: PostQuickRepliesController(post: post),
      global: false,
      builder: (controller) => Obx(
        () => QuickReplyBar(
          isSending: controller.sending.value,
          onSelected: controller.reply,
        ),
      ),
    );
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
