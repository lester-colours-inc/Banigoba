// Every page the app can open, with the binding that builds its controllers.
// Add a page here, give it a binding in its module, and name it in
// app_routes.dart.
import 'package:get/get.dart';

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/modules/admin/bindings/curators_workspace_binding.dart';
import 'package:banigoba/modules/admin/views/curators_workspace_page.dart';
import 'package:banigoba/modules/agents/views/agents_page.dart';
import 'package:banigoba/modules/auth/bindings/auth_gate_binding.dart';
import 'package:banigoba/modules/auth/bindings/email_signup_binding.dart';
import 'package:banigoba/modules/auth/views/auth_gate.dart';
import 'package:banigoba/modules/auth/views/email_signup_screen.dart';
import 'package:banigoba/modules/designers/views/fashion_designers_page.dart';
import 'package:banigoba/modules/home/views/daily_dress_up_page.dart';
import 'package:banigoba/modules/home/views/main_screen.dart';
import 'package:banigoba/modules/home/views/search_page.dart';
import 'package:banigoba/modules/makeover/bindings/create_makeover_binding.dart';
import 'package:banigoba/modules/makeover/views/avatar_try_on_page.dart';
import 'package:banigoba/modules/makeover/views/create_makeover_page.dart';
import 'package:banigoba/modules/makeover/views/makeover_page.dart';
import 'package:banigoba/modules/notifications/views/notifications_page.dart';
import 'package:banigoba/modules/profile_details/views/body_profile_page.dart';
import 'package:banigoba/modules/settings/views/settings_page.dart';
import 'package:banigoba/modules/shop/bindings/cart_binding.dart';
import 'package:banigoba/modules/shop/models/shop_link.dart';
import 'package:banigoba/modules/shop/views/cart_page.dart';
import 'package:banigoba/modules/shop/views/shared_stock_page.dart';
import 'package:banigoba/modules/shop/views/shops_page.dart';
import 'package:banigoba/modules/social/views/profile_page.dart';
import 'package:banigoba/modules/wardrobe/bindings/plan_ahead_binding.dart';
import 'package:banigoba/modules/wardrobe/views/measurement_page.dart';
import 'package:banigoba/modules/wardrobe/views/plan_ahead_page.dart';
import 'package:banigoba/modules/wardrobe/views/wardrobe_page.dart';

abstract final class AppPages {
  static const String initial = AppRoutes.root;

  static final GetPage<dynamic> _root = GetPage<dynamic>(
    name: AppRoutes.root,
    page: AuthGate.new,
    binding: AuthGateBinding(),
  );

  static final List<GetPage<dynamic>> pages = [
    _root,
    GetPage(
      name: AppRoutes.signUp,
      page: EmailSignUpScreen.new,
      binding: EmailSignUpBinding(),
    ),
    GetPage(name: AppRoutes.home, page: MainScreen.new),
    GetPage(name: AppRoutes.wardrobe, page: WardrobePage.new),
    GetPage(name: AppRoutes.cart, page: CartPage.new, binding: CartBinding()),
    GetPage(name: AppRoutes.search, page: SearchPage.new),
    GetPage(name: AppRoutes.profile, page: ProfilePage.new),
    GetPage(name: AppRoutes.avatarTryOn, page: AvatarTryOnPage.new),
    GetPage(
      name: AppRoutes.planAhead,
      page: PlanAheadPage.new,
      binding: PlanAheadBinding(),
    ),
    GetPage(name: AppRoutes.measurement, page: MeasurementPage.new),
    GetPage(
      name: AppRoutes.curatorsWorkspace,
      page: CuratorsWorkspacePage.new,
      binding: CuratorsWorkspaceBinding(),
    ),
    GetPage(name: AppRoutes.settings, page: SettingsPage.new),
    GetPage(name: AppRoutes.shops, page: ShopsPage.new),
    GetPage(name: AppRoutes.fashionDesigners, page: FashionDesignersPage.new),
    GetPage(name: AppRoutes.agents, page: AgentsPage.new),
    GetPage(name: AppRoutes.notifications, page: NotificationsPage.new),
    GetPage(name: AppRoutes.bodyProfile, page: BodyProfilePage.new),
    GetPage(name: AppRoutes.makeover, page: MakeoverPage.new),
    GetPage(
      name: AppRoutes.makeoverWithItems,
      page: CreateMakeoverPage.new,
      binding: CreateMakeoverBinding(),
    ),
    GetPage(name: AppRoutes.dailyDressUp, page: DailyDressUpPage.new),
    GetPage(name: AppRoutes.sharedStock, page: _sharedStock),
  ];

  /// Anything unrecognised falls back to the launch gate.
  static final GetPage<dynamic> unknown = GetPage<dynamic>(
    name: '/not-found',
    page: AuthGate.new,
    binding: AuthGateBinding(),
  );

  static SharedStockPage _sharedStock() {
    final id = shopLinkIdFrom(
      Uri(path: AppRoutes.sharedStock, queryParameters: Get.parameters),
    );
    return SharedStockPage(linkId: id ?? '');
  }
}
