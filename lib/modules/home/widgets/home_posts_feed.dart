// The posts of the My Fashion Makeover and Community feeds, ranked, with
// their loading, error and empty states. My Daily Dress Up has its own feed.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/home/controllers/home_feed_controller.dart';
import 'package:banigoba/modules/home/widgets/daily_dress_up_feed.dart';
import 'package:banigoba/modules/home/widgets/home_feed_message.dart';
import 'package:banigoba/modules/home/widgets/home_feed_tabs.dart';
import 'package:banigoba/modules/home/widgets/home_post_item.dart';
import 'package:banigoba/modules/makeover/widgets/makeover_fab.dart';

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
      if (error != null) {
        debugPrint('Unable to load posts: $error');
        return const HomeFeedMessage(
          icon: Icons.cloud_off_outlined,
          message: 'Posts could not be loaded.',
        );
      }
      final visiblePosts = controller.visiblePosts.value;
      if (visiblePosts == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final isMyMakeover = feed == HomeFeed.myMakeover;
      final posts = controller.rankedPostsFor(feed, visiblePosts);
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
        ],
      );
    });
  }
}
