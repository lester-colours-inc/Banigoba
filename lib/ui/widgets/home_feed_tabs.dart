// The Home feed switcher: three text tabs on a soft track pinned under the
// app bar, with a navy capsule behind the selected feed, the same mark as the
// selected Home button in the bottom bar.
//
// Each tab is as wide as its label, so the long feed names get the room they
// need and the short "Community" does not waste it; all three labels share
// one font size. The capsule slides, and stretches between tab widths, as the
// feeds are swiped.
//
// It sits in AppBar.bottom so it never scrolls away and is never covered by
// the bottom navigation or the floating Makeover button. Paired with a
// TabBarView on the same TabController, the feeds can also be swiped.
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

/// Space either side of a label, inside its tab.
const double kFeedTabPadding = 12;

/// How the tabs share the bar.
@immutable
class FeedTabLayout {
  const FeedTabLayout({required this.fontSize, required this.widths});

  /// One size for every label.
  final double fontSize;

  /// Each tab's width, in tab order. Together they fill the bar.
  final List<double> widths;

  /// Where tab [index] starts.
  double leftOf(int index) =>
      widths.take(index).fold(0.0, (sum, width) => sum + width);
}

/// Shares [width] between tabs labelled [labels]: each as wide as its label
/// (measured in [style] at its bold, selected weight) plus [kFeedTabPadding]
/// either side. Labels are drawn at [kFeedTabFontSize], or smaller by one
/// factor for all of them when they do not fit, down to
/// [kFeedTabMinFontSize]. Sizing them together keeps the row even, instead
/// of only the longest label looking smaller. Room left over is shared out
/// in proportion.
FeedTabLayout feedTabLayout({
  required List<String> labels,
  required double width,
  TextStyle style = const TextStyle(),
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final natural = [
    for (final label in labels) _labelWidth(label, style, textScaler),
  ];
  final textWidth = natural.fold(0.0, (sum, width) => sum + width);
  final padding = 2 * kFeedTabPadding * labels.length;
  final fit = textWidth <= 0 ? 1.0 : (width - padding) / textWidth;
  final scale = fit.clamp(kFeedTabMinFontSize / kFeedTabFontSize, 1.0);
  final wanted = [
    for (final labelWidth in natural) labelWidth * scale + 2 * kFeedTabPadding,
  ];
  final total = wanted.fold(0.0, (sum, width) => sum + width);
  return FeedTabLayout(
    fontSize: kFeedTabFontSize * scale,
    widths: [for (final tab in wanted) tab * width / total],
  );
}

double _labelWidth(String label, TextStyle style, TextScaler textScaler) {
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: style.copyWith(
        fontSize: kFeedTabFontSize,
        fontWeight: FontWeight.w700,
      ),
    ),
    maxLines: 1,
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

class HomeFeedTabs extends StatelessWidget implements PreferredSizeWidget {
  const HomeFeedTabs({super.key, this.controller});

  /// Which feed is shown, one tab per [HomeFeed]. Defaults to the enclosing
  /// [DefaultTabController].
  final TabController? controller;

  static const Color _primaryColor = Color(0xFF0D0140);
  static const double _height = 54;
  static const double _trackInset = 3;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final tabs = controller ?? DefaultTabController.of(context);
    assert(tabs.length == HomeFeed.values.length);
    // Runs from 0 to the last feed's index, fractional while swiping.
    final position = tabs.animation!;
    final labelStyle = theme.textTheme.labelLarge ?? const TextStyle();
    final textScaler = MediaQuery.textScalerOf(context);
    final capsule = isDark ? colors.primary : _primaryColor;

    return SizedBox(
      height: _height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (isDark ? colors.onSurface : _primaryColor).withValues(
              alpha: isDark ? 0.08 : 0.05,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.all(_trackInset),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final layout = feedTabLayout(
                  labels: [for (final feed in HomeFeed.values) feed.label],
                  width: constraints.maxWidth,
                  style: labelStyle,
                  textScaler: textScaler,
                );
                return AnimatedBuilder(
                  animation: position,
                  builder: (context, _) {
                    final indicator = _indicatorAt(layout, position.value);
                    return Stack(
                      children: [
                        Positioned(
                          key: const ValueKey('home_feed_indicator'),
                          left: indicator.left,
                          width: indicator.width,
                          top: 0,
                          bottom: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: capsule,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: capsule.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (final feed in HomeFeed.values)
                              SizedBox(
                                width: layout.widths[feed.index],
                                child: _FeedTab(
                                  label: feed.label,
                                  style: labelStyle.copyWith(
                                    fontSize: layout.fontSize,
                                  ),
                                  isSelected:
                                      feed.index == position.value.round(),
                                  selectedness:
                                      (1 - (position.value - feed.index).abs())
                                          .clamp(0.0, 1.0),
                                  onTap: () => tabs.animateTo(feed.index),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Where the capsule sits at [position]: on a tab, or part way between two
  /// while swiping, its width easing from one tab's to the other's.
  static ({double left, double width}) _indicatorAt(
    FeedTabLayout layout,
    double position,
  ) {
    final last = layout.widths.length - 1;
    final from = position.floor().clamp(0, last);
    final to = (from + 1).clamp(0, last);
    final t = (position - from).clamp(0.0, 1.0);
    double lerp(double a, double b) => a + (b - a) * t;
    return (
      left: lerp(layout.leftOf(from), layout.leftOf(to)),
      width: lerp(layout.widths[from], layout.widths[to]),
    );
  }
}

class _FeedTab extends StatelessWidget {
  const _FeedTab({
    required this.label,
    required this.style,
    required this.isSelected,
    required this.selectedness,
    required this.onTap,
  });

  final String label;
  final TextStyle style;
  final bool isSelected;

  /// How far the capsule is over this tab: 1 when it is selected, easing to
  /// 0 as the feed is swiped away. The label turns from muted to light with
  /// it.
  final double selectedness;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final onCapsule = colors.brightness == Brightness.dark
        ? colors.onPrimary
        : Colors.white;

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            // All tabs share one size, chosen so the labels fit.
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: Color.lerp(
                  colors.onSurfaceVariant,
                  onCapsule,
                  selectedness,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
