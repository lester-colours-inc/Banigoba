// Renders the four-destination tab bar: Home, Discover, Wardrobe, Profile.
//
// Creating a makeover is not a destination; it starts from the floating
// Makeover button on Home.
//
// No destination carries a count of anything social. The only badge is the
// unread notification indicator on Home, which is a signal to the user about
// their own activity, not a public total.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../core/main_tab.dart';
import '../../data/services/notification_service.dart';

class CustomBottomNavigation extends StatelessWidget {
  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const Color _primaryColor = Color(0xFF0D0140);

  static const Map<MainTab, IconData> _icons = {
    MainTab.home: Icons.home_filled,
    MainTab.discover: Icons.search,
    MainTab.wardrobe: Icons.checkroom_outlined,
    MainTab.profile: Icons.person_outline,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 85,
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final tab in MainTab.values) _buildNavItem(context, tab),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, MainTab tab) {
    final isActive = currentIndex == tab.index;
    final colors = Theme.of(context).colorScheme;

    // Unread notifications live on Home; no other destination is badged.
    final showsBadge = tab == MainTab.home;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: tab.label,
        child: InkWell(
          onTap: () => onTap(tab.index),
          customBorder: const CircleBorder(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: isActive ? _primaryColor : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _icons[tab] ?? Icons.circle_outlined,
                      size: 23,
                      color: isActive ? Colors.white : colors.onSurface,
                    ),
                  ),
                  if (showsBadge) const _UnreadBadge(),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? _primaryColor : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge();

  @override
  Widget build(BuildContext context) {
    // No badge without Firebase (widget tests and previews).
    if (Firebase.apps.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<int>(
      stream: NotificationService().getUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        if (unreadCount == 0) return const SizedBox.shrink();

        return Positioned(
          right: -2,
          top: 0,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
        );
      },
    );
  }
}
