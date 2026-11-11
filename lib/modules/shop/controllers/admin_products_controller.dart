// The seller's Products & Inventory screen: the live list, the stock filter,
// how far each piece reached, and the quick stock / delete actions.
import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/core/utils/stock_status.dart';
import 'package:banigoba/modules/shop/services/product_service.dart';
import 'package:banigoba/modules/shop/views/quick_add_page.dart';
import 'package:banigoba/modules/shop/widgets/stock_edit_sheet.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

typedef PieceReach = ({int reach, int followers});

class AdminProductsController extends GetxController {
  AdminProductsController({ProductService? products})
    : _products = products ?? ProductService();

  final ProductService _products;
  final String userId = AppAuth.instance.currentUser?.uid ?? '';

  final RxList<Map<String, dynamic>> products = <Map<String, dynamic>>[].obs;
  final RxBool loaded = false.obs;
  final Rxn<StockLevel> stockFilter = Rxn<StockLevel>();

  /// How far each piece got in followers' feeds (product id -> counts).
  final RxMap<String, PieceReach> reach = <String, PieceReach>{}.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _products.getAdminProducts(userId).listen((rows) {
      products.assignAll(rows);
      loaded.value = true;
    });
    _loadReach();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> _loadReach() async {
    if (userId.isEmpty) return;
    try {
      final rows = await supabase
          .from('product_insights')
          .select()
          .eq('seller_id', userId);
      if (isClosed) return;
      reach.assignAll({
        for (final row in rows)
          row['product_id'].toString(): (
            reach: (row['reach'] as num?)?.toInt() ?? 0,
            followers: (row['followers'] as num?)?.toInt() ?? 0,
          ),
      });
    } on PostgrestException {
      // No numbers is fine: the label just does not show.
    }
  }

  void filterBy(StockLevel? level) => stockFilter.value = level;

  /// The products in the chosen stock group.
  List<Map<String, dynamic>> get filtered => [
    for (final doc in products)
      if (stockFilter.value == null || stockLevelOf(doc) == stockFilter.value)
        doc,
  ];

  StockSummary get summary => summarizeStock(products);

  void openQuickAdd() => Get.to<void>(() => const QuickAddPage());

  /// Saves a stock change chosen in the stock sheet.
  Future<void> applyStock(String id, StockEdit edit) async {
    try {
      await _products.updateStock(
        id,
        sizeInventory: edit.sizes,
        stock: edit.stock,
      );
      AppToast.say('Stock updated.');
    } on Exception catch (error) {
      AppToast.say('Could not update the stock: $error');
    }
  }

  /// Removes a catalog product and closes the confirm dialog.
  Future<void> delete(String id) async {
    await _products.deleteProduct(id);
    if (isClosed) return;
    Get.back<void>();
    AppToast.say('Product removed');
  }
}
