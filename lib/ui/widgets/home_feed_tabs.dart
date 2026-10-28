// The Home feed switcher, modelled on X: equal-width text tabs pinned under
// the app bar, with an underline beneath the selected feed.
//
// It sits in AppBar.bottom so it never scrolls away and is never covered by
// the bottom navigation or the floating Makeover button. Paired with a
// TabBarView on the same TabController, the feeds can also be swiped, and the
// underline follows the swipe.
import 'package:flutter/material.dart';

/// The three Home feeds, in tab order.
///
/// My Fashion Makeover is the user's own looks and the affirmations they
/// receive. My Daily Dress Up is what to wear, fed from the Smart Wardrobe.
/// Community is friends, people the user follows and the public.
enum HomeFeed {
  myMakeover('My Fashion Makeover'),
  dailyDressUp('My Daily Dress Up'),
  community('Community');

  const HomeFeed(this.label);

  final String label;
}

/// The size the tab labels are drawn at when they all fit.
const double kFeedTabFontSize = 14;

/// The smallest the labels shrink to on a narrow phone.
const double kFeedTabMinFontSize = 11;

/// One font size for every tab: [kFeedTabFontSize], or smaller by the same
/// factor for all three when the widest label (at its bold, selected weight)
/// does not fit in [tabWidth]. Sizing them together keeps the row even, instead
/// of only the longest label looking smaller.
double feedTabFontSize({
  required List<String> labels,
  required double tabWidth,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  const padding = 8.0;
  final available = tabWidth - padding;
  var widest = 0.0;
  for (final label in labels) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: kFeedTabFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      maxLines: 1,
      textScaler: textScaler,
      textDirection: TextDirection.ltr,
    )..layout();
    if (painter.width > widest) widest = painter.width;
    painter.dispose();
  }
  if (widest <= available) return kFeedTabFontSize;
  final scaled = kFeedTabFontSize * available / widest;
  return scaled < kFeedTabMinFontSize ? kFeedTabMinFontSize : scaled;
}

class HomeFeedTabs extends StatelessWidget implements PreferredSizeWidget {
  const HomeFeedTabs({super.key, this.controller});

  /// Which feed is shown, one tab per [HomeFeed]. Defaults to the enclosing
  /// [DefaultTabController].
  final TabController? controller;

  static const Color _primaryColor = Color(0xFF0D0140);
  static const double _height = 48;
  static const double _underlineWidth = 56;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tabs = controller ?? DefaultTabController.of(context);
    assert(tabs.length == HomeFeed.values.length);
    // Runs from 0 to the last feed's index, fractional while swiping.
    final position = tabs.animation!;

    return Container(
      height: _height,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fontSize = feedTabFontSize(
            labels: [for (final feed in HomeFeed.values) feed.label],
            tabWidth: constraints.maxWidth / HomeFeed.values.length,
            textScaler: MediaQuery.textScalerOf(context),
          );
          return AnimatedBuilder(
            animation: position,
            builder: (context, _) => Row(
              children: [
                for (final feed in HomeFeed.values)
                  Expanded(
                    child: _FeedTab(
                      label: feed.label,
                      fontSize: fontSize,
                      isSelected: feed.index == position.value.round(),
                      underline: (1 - (position.value - feed.index).abs())
                          .clamp(0.0, 1.0),
                      onTap: () => tabs.animateTo(feed.index),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FeedTab extends StatelessWidget {
  const _FeedTab({
    required this.label,
    required this.fontSize,
    required this.isSelected,
    required this.underline,
    required this.onTap,
  });

  final String label;
  final double fontSize;
  final bool isSelected;

  /// How much of the underline shows: 1 on the selected feed, easing to 0 as
  /// the feed is swiped away.
  final double underline;
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
            // All tabs share one size, chosen so the widest label fits.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? colors.onSurface
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 3,
              width: HomeFeedTabs._underlineWidth * underline,
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
