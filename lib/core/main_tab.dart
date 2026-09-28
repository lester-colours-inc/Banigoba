// The four consumer destinations.
//
// BNG SRS 001 originally placed a Create tab at the centre. Following the
// September 2026 review, Create was removed as a destination: a makeover now
// starts from the floating Makeover button on Home, the way a tweet starts
// from X's compose button. The order here is the tab order.
//
// Notifications is deliberately not a destination. It is a signal surfaced on
// Home, reached by route.
enum MainTab {
  home('Home'),
  discover('Discover'),
  wardrobe('Wardrobe'),
  profile('Profile');

  const MainTab(this.label);

  final String label;

  /// Tab position. Declaration order is the tab order.
  int get position => index;

  static MainTab fromIndex(int position) {
    if (position < 0 || position >= MainTab.values.length) return MainTab.home;
    return MainTab.values[position];
  }
}
