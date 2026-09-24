// Hosts the app drawer, bottom navigation, and the four main destinations:
// Home, Discover, Wardrobe, Profile. A makeover is started from the floating
// Makeover button on Home rather than from a tab.
import 'package:flutter/material.dart';

import '../../../core/main_tab.dart';
import '../../../core/theme_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_navigation.dart';
import '../social/profile_page.dart';
import '../wardrobe/wardrobe_page.dart';
import 'daily_dress_up_page.dart';
import 'search_page.dart';

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
    return Scaffold(
      drawer: AppDrawer(
        themeProvider: themeProvider,
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
