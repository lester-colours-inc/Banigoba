// Builds the authenticated navigation drawer and account controls.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme_provider.dart';
import '../../core/app_routes.dart';
import '../../core/main_tab.dart';
import '../screens/agents/agents_page.dart';
import '../screens/designers/fashion_designers_page.dart';
import '../screens/shop/shop_chat_page.dart';

class AppDrawer extends StatelessWidget {
  final ThemeProvider themeProvider;
  final ValueChanged<MainTab>? onTabSelect;

  const AppDrawer({super.key, required this.themeProvider, this.onTabSelect});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? '';
    final userName =
        user?.displayName ??
        (userEmail.isNotEmpty ? userEmail.split('@')[0] : 'User');
    final initials = userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U';
    const Color primaryColor = Color(0xFF0D0140);
    final colors = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildHeader(context, primaryColor),
                const Padding(
                  padding: EdgeInsets.fromLTRB(25, 20, 25, 10),
                  child: Text(
                    'Overview',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  context,
                  Icons.grid_view,
                  'My Fashion Style',
                  onTap: () {
                    if (onTabSelect != null) {
                      onTabSelect!(MainTab.home);
                    } else {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
                ),
                _buildDrawerItem(
                  context,
                  Icons.auto_awesome,
                  'Create a Look',
                  onTap: () {
                    if (onTabSelect != null) {
                      onTabSelect!(MainTab.create);
                    }
                  },
                ),
                _buildDrawerItem(
                  context,
                  Icons.storefront,
                  'Shops & Boutiques',
                  onTap: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.pushNamed(AppRoutes.shops);
                  },
                ),
                _buildDrawerItem(
                  context,
                  Icons.description_outlined,
                  'Fashion Designers',
                  onTap: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute<void>(
                        builder: (_) => const FashionDesignersPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  Icons.calendar_today_outlined,
                  'Agents',
                  onTap: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AgentsPage(),
                      ),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(25, 20, 25, 10),
                  child: Text(
                    'Account',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  context,
                  Icons.chat_bubble_outline,
                  'Messages',
                  onTap: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ShopChatInboxPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  Icons.settings_outlined,
                  'Settings',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                ),
                _buildDrawerItem(
                  context,
                  Icons.logout,
                  'Logout',
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                  },
                ),
              ],
            ),
          ),
          if (user == null)
            _buildFooter(
              context,
              userName,
              userEmail,
              initials,
              primaryColor,
              '',
            )
          else
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final liveName =
                    (data?['displayName'] ?? user.displayName ?? userName)
                        .toString();
                final profileImageUrl =
                    (data?['profileImageURL'] ??
                            data?['profileImageUrl'] ??
                            user.photoURL ??
                            '')
                        .toString();
                final liveInitial = liveName.trim().isNotEmpty
                    ? liveName.trim()[0].toUpperCase()
                    : initials;
                return _buildFooter(
                  context,
                  liveName,
                  userEmail,
                  liveInitial,
                  primaryColor,
                  profileImageUrl,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 60.0,
        left: 25,
        bottom: 20,
        right: 25,
      ),
      child: Image.asset(
        'assets/images/logo.png',
        height: 80,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_right,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          const SizedBox(width: 5),
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 22,
          ),
        ],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 15,
        ),
      ),
      onTap: onTap ?? () {},
      horizontalTitleGap: 10,
      visualDensity: const VisualDensity(vertical: -1),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    String name,
    String email,
    String initials,
    Color primaryColor,
    String profileImageUrl,
  ) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wb_sunny_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  themeProvider.toggleTheme(!themeProvider.isDarkMode);
                },
                child: Container(
                  height: 25,
                  width: 50,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        left: themeProvider.isDarkMode ? 25 : 5,
                        top: 4,
                        child: Container(
                          width: 17,
                          height: 17,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.nightlight_round, size: 18, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 30),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              final navigator = Navigator.of(context);
              navigator.pop();
              navigator.pushNamed(AppRoutes.profile);
            },
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: profileImageUrl.isEmpty
                          ? Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            )
                          : Image.network(
                              profileImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                            ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
