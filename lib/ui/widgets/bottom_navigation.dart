// Renders the five-destination tab bar.
//
// Destinations are Home, Discover, Create, Wardrobe and Profile (BNG SRS 001).
// Create sits centre and is emphasised by shape, not by size — the spec asks
// for "visually central but not oversized".
//
// No destination carries a count of anything social. The only badge is the
// unread notification indicator on Home, which is a signal to the user about
// their own activity, not a public total.
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
    MainTab.create: Icons.auto_awesome,
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
    final isCreate = tab == MainTab.create;
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
                      color: isActive
                          ? _primaryColor
                          : isCreate
                          ? _primaryColor.withValues(alpha: 0.08)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isCreate && !isActive
                          ? Border.all(
                              color: _primaryColor.withValues(alpha: 0.35),
                            )
                          : null,
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
