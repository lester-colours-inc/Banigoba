// My Smart Wardrobe: the tab shown, My Clothes (stream + collection filter),
// and the per-piece actions.
import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/modules/makeover/widgets/change_look_category_sheet.dart';
import 'package:banigoba/modules/notifications/services/notification_service.dart';
import 'package:banigoba/modules/notifications/views/notifications_page.dart';
import 'package:banigoba/modules/shop/services/product_service.dart';
import 'package:banigoba/modules/shop/views/product_detail_page.dart';
import 'package:banigoba/modules/wardrobe/models/wardrobe_collections.dart';
import 'package:banigoba/modules/wardrobe/views/wardrobe_insights_page.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

/// The wardrobe's sections, in tab order.
enum WardrobeTab { clothes, savedLooks, shops }

class WardrobeController extends GetxController {
  WardrobeController({
    this.initialTab = WardrobeTab.clothes,
    ProductService? productService,
  }) : _productService = productService ?? ProductService();

  final WardrobeTab initialTab;
  final ProductService _productService;

  final String userId = AppAuth.instance.currentUser?.uid ?? '';

  late final RxInt selectedTab = initialTab.index.obs;

  // Which of My Clothes is shown: everything, the pieces in no collection,
  // or one of the person's own collections (W-6).
  final Rx<CollectionView> collectionView = CollectionView.all.obs;
  final RxnString collectionName = RxnString();

  /// My Clothes, newest first. Null until the first snapshot arrives.
  final Rxn<List<Map<String, dynamic>>> items =
      Rxn<List<Map<String, dynamic>>>();
  final RxInt unreadCount = 0.obs;

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _subscriptions
      ..add(
        _productService.getUserProducts(userId).listen((docs) {
          items.value = _newestFirst(docs);
          // A collection that no longer exists falls back to everything.
          final name = collectionName.value;
          if (name != null && !collectionsOf(items.value!).contains(name)) {
            collectionName.value = null;
          }
        }),
      )
      ..add(NotificationService().getUnreadCount().listen(unreadCount.call));
  }

  @override
  void onClose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.onClose();
  }

  static List<Map<String, dynamic>> _newestFirst(
    List<Map<String, dynamic>> docs,
  ) {
    final sorted = List<Map<String, dynamic>>.from(docs);
    sorted.sort((a, b) {
      final aTime = asDateTime(a['createdAt']);
      final bTime = asDateTime(b['createdAt']);
      if (aTime == null) return -1;
      if (bTime == null) return 1;
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  /// The pieces under the current collection filter.
  List<Map<String, dynamic>> get shownItems => piecesIn(
    items.value ?? const [],
    view: collectionView.value,
    name: collectionName.value,
  );

  void selectTab(int index) => selectedTab.value = index;

  void showAllCollections() {
    collectionName.value = null;
    collectionView.value = CollectionView.all;
  }

  void showUncollected() {
    collectionName.value = null;
    collectionView.value = CollectionView.uncollected;
  }

  void showCollection(String name) => collectionName.value = name;

  void openCart() => Get.toNamed<void>(AppRoutes.cart);

  void openNotifications() => Get.to<void>(() => const NotificationsPage());

  void openInsights() => Get.to<void>(() => const WardrobeInsightsPage());

  void openProduct(Map<String, dynamic> data) =>
      Get.to<void>(() => ProductDetailPage(productData: data));

  /// Moves a piece to a collection, or takes it out of one.
  Future<void> moveToCollection(Map<String, dynamic> data) async {
    final existing = await _productService.getUserProducts(userId).first;
    final context = Get.context;
    if (isClosed || context == null || !context.mounted) return;
    final chosen = await showChangeLookCategorySheet(
      context,
      existingCategories: collectionsOf(existing),
      currentCategory: collectionOf(data),
      noun: 'collection',
      subject: 'piece',
    );
    if (chosen == null) return;
    try {
      await _productService.setCollection(data['id'].toString(), chosen);
      AppToast.say(
        chosen.isEmpty ? 'Taken out of its collection.' : 'Moved to $chosen.',
      );
    } on Exception catch (error) {
      AppToast.say('Could not move it: $error');
    }
  }

  Future<void> markWorn(String itemId) async {
    try {
      await _productService.markUserProductWorn(itemId);
      AppToast.say('Noted: worn today.');
    } on PostgrestException catch (error) {
      AppToast.say('Could not save that: ${error.message}');
    }
  }
}
