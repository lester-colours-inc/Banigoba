// The five consumer destinations.
//
// BNG SRS 001 fixes this navigation model: Home, Discover, Create, Wardrobe
// and Profile, with Create visually central but not oversized. The order here
// is the tab order, so it must not be rearranged casually — it is a spec
// commitment, not a layout preference.
//
// Notifications is deliberately not a destination. It is a signal surfaced on
// Home, reached by route.
enum MainTab {
  home('Home'),
  discover('Discover'),
  create('Create'),
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
