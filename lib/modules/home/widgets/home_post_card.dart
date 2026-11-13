// One look in a Home feed: the card, its action row and its ⋮ menu.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/home/controllers/home_feed_controller.dart';
import 'package:banigoba/modules/home/models/post_author.dart';
import 'package:banigoba/modules/home/widgets/home_post_image.dart';
import 'package:banigoba/modules/makeover/widgets/find_pieces_sheet.dart';
import 'package:banigoba/modules/makeover/widgets/look_viewer_page.dart';
import 'package:banigoba/modules/settings/services/safety_service.dart';
import 'package:banigoba/modules/social/models/affirmation.dart';
import 'package:banigoba/modules/social/models/post.dart';
import 'package:banigoba/modules/social/widgets/affirmation_row.dart';
import 'package:banigoba/modules/social/widgets/dress_up_post_card.dart';
import 'package:banigoba/modules/social/widgets/forward_look_sheet.dart';
import 'package:banigoba/modules/social/widgets/quoted_look_card.dart';
import 'package:banigoba/modules/social/widgets/repost_actions.dart';
import 'package:banigoba/modules/social/widgets/safety_actions.dart';

class HomePostCard extends StatelessWidget {
  const HomePostCard({
    super.key,
    required this.controller,
    required this.post,
    required this.index,
    required this.author,
    required this.isOwner,
    required this.isMineTab,
    required this.imageUrl,
    required this.caption,
    required this.styleLabel,
    required this.currentUserId,
    this.repostLabel = '',
  });

  final HomeFeedController controller;
  final Post post;
  final int index;
  final PostAuthor author;
  final bool isOwner;
  final bool isMineTab;
  final String imageUrl;
  final String caption;
  final String styleLabel;
  final String currentUserId;
  final String repostLabel;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final saved = controller.savedPostIds.value.contains(post.id);
      return DressUpPostCard(
        key: ValueKey('dress_up_post_${post.id}'),
        isMineLayout: isMineTab,
        title: author.displayName,
        subtitle: isMineTab && !post.isQuote ? caption : '',
        detail: isMineTab ? styleLabel : '',
        captionLead: isOwner ? 'Your look' : "${author.displayName}'s",
        caption: isMineTab || post.isQuote ? '' : caption,
        quote: post.quoteText,
        repostLabel: repostLabel,
        avatarUrl: author.profileImageUrl.isNotEmpty
            ? author.profileImageUrl
            : author.fullBodyImageUrl,
        timeLabel: formatPostTime(post.createdAt),
        imageBackground: kLookBackdrops[index % kLookBackdrops.length],
        visual: HomePostImage(imageUrl: imageUrl),
        onImageTap: imageUrl.isEmpty
            ? null
            : () => openLookViewer(
                context,
                imageUrl: imageUrl,
                title: author.displayName,
                caption: caption,
              ),
        // One row: affirm & comment · repost · quote · save to Smart
        // Wardrobe, then send to and the ⋮ menu at the far end. Reposting a
        // private look asks to share it first.
        actions: [
          DressUpCardAction(
            icon: Icons.add_comment_outlined,
            label: isOwner
                ? 'Affirmations & comments received'
                : 'Affirm & comment',
            onTap: () => controller.openAffirmations(
              post,
              isOwner: isOwner,
              ownerName: author.displayName,
            ),
          ),
          // Always offered; a private look is shared first (P-8).
          DressUpCardAction(
            icon: Icons.repeat,
            label: 'Repost',
            onTap: () => controller.passOn(post, repostLook),
          ),
          DressUpCardAction(
            icon: Icons.format_quote_outlined,
            label: 'Quote',
            onTap: () => controller.passOn(
              post,
              (context, post, {posts}) => quoteLook(
                context,
                post,
                posts: posts,
                preview: QuotedLookPreview(
                  authorName: author.displayName,
                  authorAvatarUrl: author.profileImageUrl,
                  timeLabel: formatPostTime(post.createdAt),
                  text: post.isQuote ? post.quoteText : caption,
                  imageUrl: imageUrl,
                ),
                myAvatarUrl: controller
                    .authorOf(currentUserId)
                    .then((me) => me.profileImageUrl),
              ),
            ),
          ),
          DressUpCardAction(
            icon: Icons.checkroom_outlined,
            activeIcon: Icons.checkroom,
            isActive: saved,
            label: saved ? 'Saved to Smart Wardrobe' : 'Save to Smart Wardrobe',
            // Saved looks are only removed from the Wardrobe page.
            onTap: () => saved
                ? controller.showAlreadySaved()
                : controller.saveToWardrobe(post, imageUrl, caption),
          ),
        ],
        menuItems: [
          if (isOwner && !post.isRepost)
            DressUpMenuItem(
              icon: Icons.edit_outlined,
              label: 'Edit my look',
              onSelected: () => controller.editPost(post, imageUrl),
            ),
          DressUpMenuItem(
            icon: Icons.shopping_bag_outlined,
            label: 'Place Order',
            onSelected: () => showFindPiecesSheet(context),
          ),
          // Post decides who sees the look in the feeds; Send to (the share
          // icon) passes it to someone specific (P-4).
          if (isOwner && !post.isRepost)
            DressUpMenuItem(
              icon: post.isShared
                  ? Icons.visibility_outlined
                  : Icons.public_outlined,
              label: post.isShared ? 'Who can see this' : 'Post to feed',
              onSelected: () => controller.sharePost(post),
            ),
          DressUpMenuItem(
            icon: Icons.accessibility_new,
            label: 'Try On',
            onSelected: () => controller.tryOnPost(post),
          ),
          if (isOwner && post.isShared)
            DressUpMenuItem(
              icon: Icons.lock_outline,
              label: 'Make private',
              onSelected: () => controller.makePrivate(post),
            ),
          if (isOwner)
            DressUpMenuItem(
              icon: Icons.delete_outline,
              label: 'Delete',
              isDestructive: true,
              onSelected: () => controller.deletePost(post),
            ),
          // Report and block, on everyone else's looks (App Store 1.2).
          if (!isOwner) ...[
            DressUpMenuItem(
              icon: Icons.flag_outlined,
              label: 'Report look',
              onSelected: () => showReportSheet(
                context,
                subject: 'look',
                onReport: (reason) =>
                    SafetyService.instance.reportPost(post.id, reason),
              ),
            ),
            DressUpMenuItem(
              icon: Icons.person_off_outlined,
              label: 'Block ${author.displayName}',
              isDestructive: true,
              onSelected: () => confirmBlock(
                context,
                userId: post.authorId,
                name: author.displayName,
              ),
            ),
          ],
        ],
        trailingAction: DressUpCardAction(
          icon: Icons.share_outlined,
          label: kSendToLabel,
          onTap: () => showForwardLookSheet(
            context,
            imageUrl: imageUrl,
            caption: post.caption,
          ),
        ),
        // Which affirmations the look received; never how many (BNG SRS 001,
        // AFF-003). The affirm action is in the row above, so not repeated.
        footer: AffirmationRow(
          targetType: AffirmationTargetType.post,
          targetId: post.id,
          targetOwnerId: post.authorId,
          currentUserId: currentUserId,
          ownerName: isOwner ? 'your look' : author.displayName,
          showAction: false,
        ),
      );
    });
  }
}
