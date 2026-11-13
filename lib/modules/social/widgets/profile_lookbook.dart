// The lookbook on a profile: heading, the person's public looks as studio
// cards, or an empty studio.
import 'package:flutter/material.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/makeover/widgets/look_viewer_page.dart';
import 'package:banigoba/modules/social/controllers/profile_controller.dart';
import 'package:banigoba/modules/social/models/affirmation.dart';
import 'package:banigoba/modules/social/models/post.dart';
import 'package:banigoba/modules/social/widgets/affirmation_row.dart';
import 'package:banigoba/modules/social/widgets/dress_up_post_card.dart';
import 'package:banigoba/modules/social/widgets/forward_look_sheet.dart';
import 'package:banigoba/modules/social/widgets/post_comments_sheet.dart';
import 'package:banigoba/modules/social/widgets/profile_style.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

class ProfileLookbookHeading extends StatelessWidget {
  const ProfileLookbookHeading({super.key, required this.isMe});

  final bool isMe;

  @override
  Widget build(BuildContext context) =>
      _buildLookbookHeading(context, isMe: isMe);
}

class ProfileLookbook extends StatelessWidget {
  const ProfileLookbook({
    super.key,
    required this.controller,
    required this.userName,
    required this.profileImageUrl,
  });

  final ProfileController controller;
  final String userName;
  final String profileImageUrl;

  @override
  Widget build(BuildContext context) =>
      _buildPublicDailyDressUps(context, controller, userName, profileImageUrl);
}

Widget _buildLookbookHeading(BuildContext context, {required bool isMe}) {
  final colors = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.fromLTRB(22, 32, 22, 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            isMe ? 'My lookbook' : 'Lookbook',
            style: TextStyle(
              color: profileInk(colors),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
        Icon(Icons.public, size: 15, color: colors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          'Public looks',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget _buildPublicDailyDressUps(
  BuildContext context,
  ProfileController controller,
  String userName,
  String profileImageUrl,
) {
  final stream = controller.publicPosts;

  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
    child: StreamBuilder<List<Post>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Unable to load public Daily Dress Ups.'),
          );
        }

        final posts = [...?snapshot.data];
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (posts.isEmpty) return _buildEmptyLookbook(context);

        return Column(
          children: [
            for (var index = 0; index < posts.length; index++) ...[
              _buildPublicDailyDressUpCard(
                context,
                controller,
                posts[index],
                index,
                userName,
                profileImageUrl,
              ),
              if (index != posts.length - 1) const SizedBox(height: 18),
            ],
          ],
        );
      },
    ),
  );
}

/// An empty studio: the backdrop and a hanger, waiting for a first look.
Widget _buildEmptyLookbook(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  final isDark = colors.brightness == Brightness.dark;
  final backdrop = kLookBackdrops[1];
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: RadialGradient(
        radius: 1.2,
        colors: [
          for (final colour in [Colors.white, backdrop])
            isDark ? Color.lerp(colour, Colors.black, 0.7)! : colour,
        ],
      ),
    ),
    child: Column(
      children: [
        Icon(Icons.checkroom_outlined, size: 44, color: profileInk(colors)),
        const SizedBox(height: 12),
        Text(
          'No public Daily Dress Ups yet.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget _buildPublicDailyDressUpCard(
  BuildContext context,
  ProfileController controller,
  Post post,
  int index,
  String userName,
  String profileImageUrl,
) {
  final currentUserId = AppAuth.instance.currentUser?.uid ?? '';
  final isOwner = currentUserId == post.authorId;
  final caption = post.caption.trim().isEmpty
      ? 'Daily dress-up'
      : post.caption.trim();
  final pieces = post.products
      .map(_productImageUrl)
      .where((url) => url.isNotEmpty)
      .take(4)
      .toList();

  return DressUpPostCard(
    key: ValueKey('profile_post_${post.id}'),
    isMineLayout: true,
    title: userName,
    subtitle: caption,
    avatarUrl: profileImageUrl,
    timeLabel: _formatPostTime(post.createdAt),
    imageBackground: kLookBackdrops[index % kLookBackdrops.length],
    visual: _buildLookImage(context, post.imageURL),
    onImageTap: post.imageURL.isEmpty
        ? null
        : () => openLookViewer(
            context,
            imageUrl: post.imageURL,
            title: userName,
            caption: caption,
          ),
    actions: [
      DressUpCardAction(
        icon: Icons.add_comment_outlined,
        label: isOwner ? 'Affirmations received' : 'Affirm',
        onTap: () => controller.openAffirmations(
          context,
          post,
          isOwner: isOwner,
          ownerName: userName,
        ),
      ),
      DressUpCardAction(
        icon: Icons.chat_bubble_outline,
        label: post.commentCount == 1
            ? '1 comment'
            : '${post.commentCount} comments',
        onTap: () => showPostCommentsSheet(context, post),
      ),
      DressUpCardAction(
        icon: Icons.accessibility_new,
        label: 'Try On',
        onTap: () => controller.tryOnPost(context, post),
      ),
    ],
    trailingAction: DressUpCardAction(
      icon: Icons.share_outlined,
      label: kSendToLabel,
      onTap: () => showForwardLookSheet(
        context,
        imageUrl: post.imageURL,
        caption: post.caption,
      ),
    ),
    // The pieces the look is made of, then which affirmations it got;
    // never how many (BNG SRS 001, AFF-003).
    footer: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pieces.isNotEmpty) _buildPieces(context, pieces),
        AffirmationRow(
          targetType: AffirmationTargetType.post,
          targetId: post.id,
          targetOwnerId: post.authorId,
          currentUserId: currentUserId,
          ownerName: isOwner ? 'your look' : userName,
          showAction: false,
          onOpenReceived: () => showReceivedAffirmations(
            context,
            targetType: AffirmationTargetType.post,
            targetId: post.id,
          ),
        ),
      ],
    ),
  );
}

/// The whole look, standing on the bottom of the card's studio frame.
Widget _buildLookImage(BuildContext context, String imageUrl) {
  final fallback = Center(
    child: Icon(
      Icons.checkroom_outlined,
      size: 64,
      color: Theme.of(context).colorScheme.outline,
    ),
  );
  if (imageUrl.isEmpty) return fallback;
  return AppNetworkImage(
    imageUrl,
    fit: BoxFit.contain,
    alignment: Alignment.bottomCenter,
    fallback: fallback,
  );
}

/// "In this look": small swatches of the pieces the outfit is made of.
Widget _buildPieces(BuildContext context, List<String> imageUrls) {
  final colors = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(top: 2, bottom: 10),
    child: Row(
      children: [
        Text(
          'In this look',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        for (final url in imageUrls)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: AppNetworkImage(
                url,
                fit: BoxFit.contain,
                fallback: Icon(
                  Icons.checkroom_outlined,
                  size: 20,
                  color: colors.outline,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

String _productImageUrl(Map<String, dynamic> product) {
  const fields = [
    'rawImageUrl',
    'imageUrl',
    'imageURL',
    'processedImageUrl',
    'processed_url',
    'raw_url',
  ];
  for (final field in fields) {
    final value = product[field];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return '';
}

String _formatPostTime(DateTime createdAt) {
  final difference = DateTime.now().difference(createdAt);
  if (difference.isNegative || difference.inMinutes < 1) return 'Now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m';
  if (difference.inHours < 24) return '${difference.inHours}h';
  if (difference.inDays == 1) return 'Yesterday';
  if (difference.inDays < 7) return '${difference.inDays}d';
  return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
}
