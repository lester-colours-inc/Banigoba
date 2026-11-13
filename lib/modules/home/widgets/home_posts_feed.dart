// The posts of the My Fashion Makeover and Community feeds, ranked, with
// their loading, error and empty states. My Daily Dress Up has its own feed.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/offline/local_cache.dart';
import 'package:banigoba/modules/home/controllers/home_feed_controller.dart';
import 'package:banigoba/modules/home/widgets/daily_dress_up_feed.dart';
import 'package:banigoba/modules/home/widgets/home_feed_message.dart';
import 'package:banigoba/modules/home/widgets/home_feed_tabs.dart';
import 'package:banigoba/modules/home/widgets/home_post_item.dart';
import 'package:banigoba/modules/makeover/widgets/makeover_fab.dart';

/// A feed with fewer posts than this keeps loading pages on its own: the
/// newest page may be mostly posts that belong in another feed.
const int kMinFeedPosts = 8;

/// How close to the end of a feed (in pixels) the next page is asked for.
const double kLoadMoreExtent = 800;

class HomePostsFeed extends StatelessWidget {
  const HomePostsFeed({
    super.key,
    required this.controller,
    required this.feed,
  });

  final HomeFeedController controller;
  final HomeFeed feed;

  @override
  Widget build(BuildContext context) {
    if (feed == HomeFeed.dailyDressUp) {
      return DailyDressUpFeed(
        emptyBuilder: (icon, message) =>
            HomeFeedMessage(icon: icon, message: message),
      );
    }
    return Obx(() {
      final error = controller.postsError.value;
      final visiblePosts = controller.visiblePosts.value;
      if (error != null && visiblePosts == null) {
        debugPrint('Unable to load posts: $error');
        return HomeFeedMessage(
          icon: Icons.cloud_off_outlined,
          message: isNetworkError(error)
              ? "You're offline. Looks will show here when you reconnect."
              : 'Posts could not be loaded.',
        );
      }
      if (visiblePosts == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final isMyMakeover = feed == HomeFeed.myMakeover;
      final posts = controller.rankedPostsFor(feed, visiblePosts);
      final hasMore = controller.hasMorePosts.value;
      final loadingMore = controller.loadingMorePosts.value;
      if (hasMore && posts.length < kMinFeedPosts) {
        // Not enough of this feed yet: fetch the next page after this frame.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => controller.loadMorePosts(),
        );
      }
      if (posts.isEmpty && hasMore) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (posts.isEmpty) {
        return HomeFeedMessage(
          icon: Icons.checkroom_outlined,
          message: isMyMakeover
              ? 'Your looks and your friends\' looks will appear here. '
                    'Tap "$kMakeoverFabLabel" to make your first one.'
              : controller.nearOnly
              ? 'No looks near you yet. Switch to Everyone, or follow people '
                    'to see theirs here.'
              : 'No community looks yet. Follow people to see theirs here.',
        );
      }
      return Column(
        children: [
          for (var index = 0; index < posts.length; index++) ...[
            HomePostItem(
              controller: controller,
              post: posts[index],
              index: index,
              feed: feed,
            ),
            if (index != posts.length - 1) const SizedBox(height: 18),
          ],
          if (loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      );
    });
  }
}
