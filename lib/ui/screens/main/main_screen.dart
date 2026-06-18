// Hosts the app drawer, bottom navigation, and the main tab pages.
import 'package:flutter/material.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/app_drawer.dart';
import '../../../core/theme_provider.dart';
import 'home_page.dart';
import 'daily_dress_up_page.dart';
import 'hair_style_page.dart';
import 'search_page.dart';
import 'notifications_page.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  static final ValueNotifier<int?> _tabRequests = ValueNotifier<int?>(null);

  static void selectTab(int index) {
    _tabRequests.value = null;
    _tabRequests.value = index;
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    MainScreen._tabRequests.addListener(_handleTabRequest);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleTabRequest());
  }

  @override
  void dispose() {
    MainScreen._tabRequests.removeListener(_handleTabRequest);
    super.dispose();
  }

  void _handleTabRequest() {
    final index = MainScreen._tabRequests.value;
    if (index == null || index < 0 || index >= _pages.length) return;
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _pages = [
    const HomePage(),
    const DailyDressUpPage(),
    const HairStylePage(),
    const SearchPage(),
    const NotificationsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        themeProvider: themeProvider,
        onTabSelect: (index) {
          setState(() {
            _currentIndex = index;
          });
          Navigator.pop(context);
        },
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
