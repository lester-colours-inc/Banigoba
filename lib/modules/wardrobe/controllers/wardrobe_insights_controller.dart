// Loads the wardrobe once and analyses it for the insights page.
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/shop/services/product_service.dart';
import 'package:banigoba/modules/wardrobe/models/wardrobe_insights.dart';

/// Where the page reads the wardrobe from; a fake in tests.
typedef LoadWardrobe = Future<List<Map<String, dynamic>>> Function();

Future<List<Map<String, dynamic>>> _loadOwnWardrobe() {
  final userId = AppAuth.instance.currentUser?.uid ?? '';
  return ProductService().getUserProducts(userId).first;
}

class WardrobeInsightsController extends GetxController {
  WardrobeInsightsController({LoadWardrobe? load, DateTime? now})
    : _load = load ?? _loadOwnWardrobe,
      _now = now;

  final LoadWardrobe _load;
  final DateTime? _now;

  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxList<Map<String, dynamic>> wardrobe = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final loaded = await _load();
      if (isClosed) return;
      wardrobe.assignAll(loaded);
    } catch (_) {
      if (isClosed) return;
      hasError.value = true;
    }
    isLoading.value = false;
  }

  List<Insight> get insights =>
      analyzeWardrobe(wardrobe, now: _now ?? DateTime.now());

  String get headline => wardrobeHeadline(wardrobe, insights);

  Map<String, String> get names => {
    for (final piece in wardrobe)
      piece['id'].toString(): (piece['name'] ?? '').toString(),
  };
}
