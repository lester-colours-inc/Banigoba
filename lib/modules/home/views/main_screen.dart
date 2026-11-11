// Hosts the app drawer, bottom navigation, and the four main destinations:
// Home, Discover, Wardrobe, Profile. A makeover is started from the floating
// Makeover button on Home rather than from a tab.
import 'package:flutter/material.dart';

import 'package:banigoba/core/main_tab.dart';
import 'package:banigoba/shared/widgets/app_drawer.dart';
import 'package:banigoba/shared/widgets/bottom_navigation.dart';
import 'package:banigoba/shared/widgets/double_back_to_exit.dart';
import 'package:banigoba/modules/social/views/profile_page.dart';
import 'package:banigoba/modules/wardrobe/views/wardrobe_page.dart';
import 'package:banigoba/modules/home/views/daily_dress_up_page.dart';
import 'package:banigoba/modules/home/views/search_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialTab = MainTab.home});

  final MainTab initialTab;

  static final ValueNotifier<MainTab?> _tabRequests = ValueNotifier<MainTab?>(
    null,
  );

  /// Switches the visible destination from anywhere in the app.
  static void selectTab(MainTab tab) {
    _tabRequests.value = null;
    _tabRequests.value = tab;
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late MainTab _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    MainScreen._tabRequests.addListener(_handleTabRequest);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleTabRequest());
  }

  @override
  void dispose() {
    MainScreen._tabRequests.removeListener(_handleTabRequest);
    super.dispose();
  }

  void _handleTabRequest() {
    final tab = MainScreen._tabRequests.value;
    if (tab == null || !mounted) return;
    setState(() => _currentTab = tab);
  }

  static const List<Widget> _pages = [
    DailyDressUpPage(),
    SearchPage(),
    WardrobePage(),
    ProfilePage(showBottomNav: false),
  ];

  @override
  Widget build(BuildContext context) {
    return DoubleBackToExit(
      onBackFirst: _closeDrawer,
      child: _buildScaffold(context),
    );
  }

  bool _closeDrawer() {
    final scaffold = _scaffoldKey.currentState;
    if (scaffold == null || !scaffold.isDrawerOpen) return false;
    scaffold.closeDrawer();
    return true;
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        onTabSelect: (tab) {
          setState(() => _currentTab = tab);
          Navigator.pop(context);
        },
      ),
      body: IndexedStack(index: _currentTab.index, children: _pages),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentTab.index,
        onTap: (index) =>
            setState(() => _currentTab = MainTab.fromIndex(index)),
      ),
    );
  }
}
