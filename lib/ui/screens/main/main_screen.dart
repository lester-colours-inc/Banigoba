// Hosts the app drawer, bottom navigation, and the five main destinations.
//
// Home, Discover, Create, Wardrobe, Profile (BNG SRS 001). Daily Dress Up and
// Hair Style are no longer destinations: their clothing and hair work is now
// one coordinated journey under Create. Both pages remain reachable by route,
// since they also host the shop try-on picker and the hairstyle catalogue.
import 'package:flutter/material.dart';

import '../../../core/main_tab.dart';
import '../../../core/theme_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_navigation.dart';
import '../makeover/create_makeover_page.dart';
import '../social/profile_page.dart';
import '../wardrobe/wardrobe_page.dart';
import 'home_page.dart';
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
    HomePage(),
    SearchPage(),
    CreateMakeoverPage(),
    WardrobePage(),
    ProfilePage(),
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
