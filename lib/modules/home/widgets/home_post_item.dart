// A post plus the profiles it needs (author, and who it reposts), loaded once
// and cached by the controller.
import 'package:flutter/material.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/home/controllers/home_feed_controller.dart';
import 'package:banigoba/modules/home/models/post_author.dart';
import 'package:banigoba/modules/home/widgets/home_feed_tabs.dart';
import 'package:banigoba/modules/home/widgets/home_post_card.dart';
import 'package:banigoba/modules/social/models/post.dart';

class HomePostItem extends StatelessWidget {
  const HomePostItem({
    super.key,
    required this.controller,
    required this.post,
    required this.index,
    required this.feed,
  });

  final HomeFeedController controller;
  final Post post;
  final int index;
  final HomeFeed feed;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PostAuthor>(
      future: controller.authorOf(post.authorId),
      builder: (context, authorSnapshot) {
        final author =
            authorSnapshot.data ?? PostAuthor.fallback(post.authorId);
        final currentUserId = AppAuth.instance.currentUser?.uid ?? '';
        final imageUrl = post.imageURL.isNotEmpty
            ? post.imageURL
            : author.fullBodyImageUrl;
        final caption = post.caption.trim().isEmpty
            ? 'Daily Outfit'
            : post.caption.trim();
        final styleLabel = author.stylePreference.isEmpty
            ? 'Styled for your day'
            : '${titleCase(author.stylePreference)} style';

        HomePostCard card({String repostLabel = ''}) => HomePostCard(
          controller: controller,
          post: post,
          index: index,
          author: author,
          isOwner: currentUserId == post.authorId,
          isMineTab: feed == HomeFeed.myMakeover,
          imageUrl: imageUrl,
          caption: caption,
          styleLabel: styleLabel,
          currentUserId: currentUserId,
          repostLabel: repostLabel,
        );

        if (!post.isRepost) return card();
        return FutureBuilder<PostAuthor>(
          future: controller.authorOf(post.repostOfAuthorId),
          builder: (context, sourceSnapshot) {
            final source =
                sourceSnapshot.data ??
                PostAuthor.fallback(post.repostOfAuthorId);
            final sourceName = post.repostOfAuthorId == currentUserId
                ? 'you'
                : source.displayName;
            return card(
              repostLabel: post.isQuote
                  ? 'Quoting $sourceName'
                  : 'Reposted from $sourceName',
            );
          },
        );
      },
    );
  }
}
