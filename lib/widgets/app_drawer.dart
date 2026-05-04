import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme_provider.dart';

class AppDrawer extends StatelessWidget {
  final ThemeProvider themeProvider;

  const AppDrawer({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? '';
    final userName = user?.displayName ?? (userEmail.isNotEmpty ? userEmail.split('@')[0] : 'User');
    final initials = userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U';
    final theme = Theme.of(context);

    return Drawer(
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildHeader(context),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text(
                      'Overview',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  _buildDrawerItem(context, Icons.grid_view, 'My Fashion Style'),
                  _buildDrawerItem(context, Icons.shopping_bag_outlined, 'My Smart Wardrobe'),
                  _buildDrawerItem(context, Icons.storefront, 'Shops & Boutiques'),
                  _buildDrawerItem(context, Icons.description_outlined, 'Fashion Designers'),
                  _buildDrawerItem(context, Icons.calendar_today_outlined, 'Agents'),
                  _buildDrawerItem(context, Icons.bar_chart, 'Curators Workspace'),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text(
                      'Account',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  _buildDrawerItem(context, Icons.chat_bubble_outline, 'Chat'),
                  _buildDrawerItem(context, Icons.settings_outlined, 'Settings'),
                  _buildDrawerItem(context, Icons.logout, 'Logout', onTap: () {
                    FirebaseAuth.instance.signOut();
                  }),
                ],
              ),
            ),
            _buildFooter(context, userName, userEmail, initials),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoColor = isDark ? Colors.white : const Color(0xFF0D0140);
    
    return Padding(
      padding: const EdgeInsets.only(top: 60.0, left: 20, bottom: 20),
      child: Row(
        children: [
          Icon(Icons.blur_on, color: logoColor, size: 40),
          const SizedBox(width: 10),
          Text(
            'Banigoba',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: logoColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.iconTheme.color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
      onTap: onTap ?? () {},
      horizontalTitleGap: 0,
      visualDensity: const VisualDensity(vertical: -2),
    );
  }

  Widget _buildFooter(BuildContext context, String name, String email, String initials) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wb_sunny_outlined, size: 20, color: Colors.grey),
              Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
                activeColor: isDark ? Colors.indigoAccent : const Color(0xFF0D0140),
              ),
              const Icon(Icons.nightlight_round, size: 20, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? Colors.indigoAccent : const Color(0xFF0D0140),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
