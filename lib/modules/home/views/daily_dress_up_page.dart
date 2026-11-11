// Home: an X-style feed of looks — My Fashion Makeover, My Daily Dress Up and
// Community — with a floating Makeover button that starts a new look, like
// composing a tweet.
//
// Under each look sits one evenly spaced row: affirm (affirming and
// commenting are one action), repost, quote, save to Smart Wardrobe, more,
// forward.
//
// Kept deliberately simple (September 2026 review): no weather or calendar
// banner here. Style by Occasion, Plan Ahead and Shopping Intelligence live on
// My Fashion Style.
//
// UNCLEAR: Shopping Intelligence should become an "order / get this look"
// action beside each post. For now each post's menu has "Find pieces"; its
// final placement and wording are still to be agreed.
// UNCLEAR: this class is still called DailyDressUpPage although it is Home.
// Daily Dress Up is meant to be a separate feature whose role after the
// review is undecided; rename once that is settled.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/modules/events/views/community_events_strip.dart';
import 'package:banigoba/modules/home/controllers/home_feed_controller.dart';
import 'package:banigoba/modules/home/widgets/fashion_news_section.dart';
import 'package:banigoba/modules/home/widgets/home_app_bar_action.dart';
import 'package:banigoba/modules/home/widgets/home_feed_tabs.dart';
import 'package:banigoba/modules/home/widgets/home_posts_feed.dart';
import 'package:banigoba/modules/home/widgets/keep_alive_page.dart';
import 'package:banigoba/modules/home/widgets/near_me_bar.dart';
import 'package:banigoba/modules/home/widgets/shop_drops_strip.dart';
import 'package:banigoba/modules/makeover/views/makeover_start_sheet.dart';
import 'package:banigoba/modules/makeover/widgets/makeover_fab.dart';
import 'package:banigoba/shared/widgets/app_drawer.dart';
import 'package:banigoba/shared/widgets/menu_or_back_button.dart';

/// Home feed of the user's own looks, friends' looks and the community.
class DailyDressUpPage extends StatelessWidget {
  const DailyDressUpPage({super.key});

  static const Color primaryColor = Color(0xFF0D0140);

  /// Switches Home to [feed] from anywhere, e.g. "My Fashion Community" in
  /// the drawer.
  static void showFeed(HomeFeed feed) => HomeFeedController.showFeed(feed);

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: created and disposed with the widget.
    return GetBuilder<HomeFeedController>(
      init: HomeFeedController(),
      global: false,
      builder: (controller) => _HomeView(controller: controller),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({required this.controller});

  final HomeFeedController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      // This is the Home tab. It keeps its own drawer because it is also
      // reachable as a standalone route, where there is no MainScreen drawer.
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: MenuOrBackButton(color: colors.onSurface),
        // The menu button already has its own padding; the default 16dp gap
        // left a hole between it and the wordmark.
        titleSpacing: 0,
        // The app name, written like the logo wordmark; the bottom bar
        // already says this is Home. It shrinks rather than truncates on
        // narrow phones.
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Banigoba',
            maxLines: 1,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: colors.primary,
            ),
          ),
        ),
        actions: [
          IconButton(
            key: const ValueKey('home_find_people'),
            tooltip: 'Find people',
            icon: Icon(Icons.person_search_outlined, color: colors.onSurface),
            onPressed: () => Get.toNamed<void>(AppRoutes.search),
          ),
          HomeNotificationsAction(
            onPressed: () => Get.toNamed<void>(AppRoutes.notifications),
          ),
          HomeCartAction(onPressed: () => Get.toNamed<void>(AppRoutes.cart)),
          const SizedBox(width: 8),
        ],
        bottom: HomeFeedTabs(controller: controller.feeds),
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: controller.foldFabOnScroll,
        child: TabBarView(
          controller: controller.feeds,
          children: [
            for (final feed in HomeFeed.values)
              KeepAlivePage(
                child: SingleChildScrollView(
                  key: PageStorageKey(feed),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (feed == HomeFeed.community) ...[
                        const CommunityEventsStrip(),
                        const ShopDropsStrip(),
                        const FashionNewsSection(),
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                          child: Obx(
                            () => NearMeBar(
                              city: controller.viewerCity.value,
                              nearMe:
                                  controller.nearMe.value &&
                                  controller.hasPlace,
                              onChanged: (value) =>
                                  controller.nearMe.value = value,
                              onSetCity: controller.addCity,
                              hasLocation: controller.viewerCell.value != null,
                              onUseLocation: controller.useLocation,
                            ),
                          ),
                        ),
                      ],
                      HomePostsFeed(controller: controller, feed: feed),
                      // Clears the floating Makeover button so it never covers
                      // the last post's actions.
                      const SizedBox(height: 96),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: Obx(
        () => MakeoverFab(
          color: DailyDressUpPage.primaryColor,
          isExtended: controller.fabExtended.value,
          onPressed: () => startMakeover(context),
        ),
      ),
    );
  }
}
