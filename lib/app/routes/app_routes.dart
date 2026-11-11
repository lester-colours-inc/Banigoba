// Route names. The pages themselves are registered in app_pages.dart.
class AppRoutes {
  static const String root = '/';
  static const String signUp = '/auth/sign-up';
  static const String home = '/home';
  static const String wardrobe = '/wardrobe';
  static const String cart = '/cart';
  static const String search = '/search';
  static const String profile = '/profile';
  static const String avatarTryOn = '/avatar-try-on';
  static const String planAhead = '/plan-ahead';
  static const String measurement = '/measurement';
  static const String curatorsWorkspace = '/admin/curators-workspace';
  static const String settings = '/settings';
  static const String shops = '/shops';
  static const String fashionDesigners = '/fashion-designers';
  static const String agents = '/agents';
  static const String notifications = '/notifications';

  /// A shared stock link, "/s?id=…" (K-9), opened from the web, a QR code or
  /// a phone link.
  static const String sharedStock = '/s';

  // Photos, sizes and measurements for the eFitting Room and Fashion Idol
  // Twin.
  static const String bodyProfile = '/profile/details';

  // A makeover is started from Home's floating Makeover button, not a tab.
  static const String makeover = '/makeover';

  // The earlier catalogue-first makeover. Not linked from anywhere now; kept
  // for "Get this look" (Phase 5), which needs real items to try on.
  static const String makeoverWithItems = '/makeover/items';

  // Daily Dress Up and Hair Style are not tab destinations — their work is one
  // coordinated makeover journey. They stay routable because they also host
  // the shop try-on picker and the hairstyle catalogue.
  static const String dailyDressUp = '/daily-dress-up';
}
