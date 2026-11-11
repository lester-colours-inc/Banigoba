// Hosts the app drawer, bottom navigation, and the four main destinations:
// Home, Discover, Wardrobe, Profile. A makeover is started from the floating
// Makeover button on Home rather than from a tab.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/main_tab.dart';
import 'package:banigoba/modules/home/controllers/main_controller.dart';
import 'package:banigoba/modules/home/views/daily_dress_up_page.dart';
import 'package:banigoba/modules/home/views/search_page.dart';
import 'package:banigoba/modules/social/views/profile_page.dart';
import 'package:banigoba/modules/wardrobe/views/wardrobe_page.dart';
import 'package:banigoba/shared/widgets/app_drawer.dart';
import 'package:banigoba/shared/widgets/bottom_navigation.dart';
import 'package:banigoba/shared/widgets/double_back_to_exit.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, this.initialTab = MainTab.home});

  final MainTab initialTab;

  /// Switches the visible destination from anywhere in the app.
  static void selectTab(MainTab tab) => MainController.selectTab(tab);

  static const List<Widget> _pages = [
    DailyDressUpPage(),
    SearchPage(),
    WardrobePage(),
    ProfilePage(showBottomNav: false),
  ];

  @override
  Widget build(BuildContext context) {
    // Scoped to this screen: created and disposed with the widget.
    return GetBuilder<MainController>(
      init: MainController(initialTab: initialTab),
      global: false,
      builder: (controller) => DoubleBackToExit(
        onBackFirst: controller.closeDrawer,
        child: Obx(
          () => Scaffold(
            key: controller.scaffoldKey,
            drawer: AppDrawer(onTabSelect: controller.selectFromDrawer),
            body: IndexedStack(
              index: controller.currentTab.value.index,
              children: _pages,
            ),
            bottomNavigationBar: CustomBottomNavigation(
              currentIndex: controller.currentTab.value.index,
              onTap: controller.selectIndex,
            ),
          ),
        ),
      ),
    );
  }
}
