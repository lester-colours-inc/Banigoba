// The Home feed switcher, modelled on X: equal-width text tabs pinned under
// the app bar, with an underline beneath the selected feed.
//
// It sits in AppBar.bottom so it never scrolls away and is never covered by
// the bottom navigation or the floating Makeover button.
import 'package:flutter/material.dart';

/// The three Home feeds, in tab order.
enum HomeFeed {
  myTimeline('My Timeline'),
  friends('Friends'),
  community('Community');

  const HomeFeed(this.label);

  final String label;
}

class HomeFeedTabs extends StatelessWidget implements PreferredSizeWidget {
  const HomeFeedTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final HomeFeed selected;
  final ValueChanged<HomeFeed> onSelected;

  static const Color _primaryColor = Color(0xFF0D0140);
  static const double _height = 48;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: _height,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          for (final feed in HomeFeed.values)
            Expanded(
              child: _FeedTab(
                label: feed.label,
                isSelected: feed == selected,
                onTap: () => onSelected(feed),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedTab extends StatelessWidget {
  const _FeedTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colors.onSurface : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              width: isSelected ? 56 : 0,
              decoration: BoxDecoration(
                color: HomeFeedTabs._primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
