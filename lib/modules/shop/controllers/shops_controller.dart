// The customer marketplace: search, the Boutiques / All Products tabs, and
// the seller profiles used to show only admin-verified boutiques.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/core/utils/garment_taxonomy.dart';
import 'package:banigoba/modules/shop/models/shop_filters.dart';
import 'package:banigoba/modules/shop/services/product_service.dart';
import 'package:banigoba/modules/shop/views/product_detail_page.dart';
import 'package:banigoba/modules/shop/views/shops_page.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';

/// Matches a lower-case search [query] against the product's name, shop,
/// category and garment group, so "bottoms" also finds trousers and skirts.
bool productMatchesQuery(Map<String, dynamic> product, String query) {
  if (query.isEmpty) return true;
  final haystack = [
    product['name'],
    product['shopName'],
    product['category'],
    product['subcategory'],
    garmentGroupOf(product),
  ].map((value) => (value ?? '').toString().toLowerCase()).join(' ');
  return haystack.contains(query);
}

class ShopsController extends GetxController {
  ShopsController({
    this.initialTab = 0,
    this.initialQuery = '',
    ProductService? products,
    ProfileService? profiles,
  }) : _productService = products ?? ProductService(),
       _profiles = profiles ?? ProfileService();

  final int initialTab;
  final String initialQuery;
  final ProductService _productService;
  final ProfileService _profiles;

  late final TextEditingController search = TextEditingController(
    text: initialQuery,
  );
  late final RxInt tab = initialTab.clamp(0, 1).obs;
  late final RxString query = initialQuery.trim().toLowerCase().obs;

  final Rx<ShopFilters> filters = const ShopFilters().obs;
  final Rx<BoutiqueSort> boutiqueSort = BoutiqueSort.mostProducts.obs;

  final RxList<Map<String, dynamic>> allProducts = <Map<String, dynamic>>[].obs;
  final RxBool loaded = false.obs;
  final RxBool failed = false.obs;

  /// Seller profiles by id. Products store uploader ids, so verification has
  /// to be checked against the seller profiles before listing publicly.
  final RxMap<String, Map<String, dynamic>> sellers =
      <String, Map<String, dynamic>>{}.obs;
  final Set<String> _requested = {};

  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _productService.getProducts().listen((rows) {
      failed.value = false;
      allProducts.assignAll(rows);
      loaded.value = true;
      _loadMissingSellers();
    }, onError: (Object _) => failed.value = true);
    ever(query, (_) => _loadMissingSellers());
  }

  @override
  void onClose() {
    _sub?.cancel();
    search.dispose();
    super.onClose();
  }

  /// Products that match the search.
  List<Map<String, dynamic>> get matching => allProducts
      .where((product) => productMatchesQuery(product, query.value))
      .toList();

  /// Products that match the search and the active filters, sorted.
  List<Map<String, dynamic>> get filtered =>
      applyShopFilters(matching, filters.value);

  /// Chip values present in the whole catalogue (not narrowed by search, so
  /// options don't vanish while typing).
  ShopFilterOptions get filterOptions => ShopFilterOptions.from(allProducts);

  void setFilters(ShopFilters value) => filters.value = value;

  void toggleCategory(String category) => filters.value = filters.value
      .copyWith(categories: toggled(filters.value.categories, category));

  void clearCategories() =>
      filters.value = filters.value.copyWith(categories: const {});

  void setSort(ShopSort sort) =>
      filters.value = filters.value.copyWith(sort: sort);

  void clearFilters() => filters.value = filters.value.cleared();

  void clearAll() {
    clearFilters();
    search.clear();
    query.value = '';
  }

  void setBoutiqueSort(BoutiqueSort sort) => boutiqueSort.value = sort;

  static String sellerOf(Map<String, dynamic> product) =>
      (product['uploaderId'] ?? '').toString();

  bool isVerified(String sellerId) {
    final user = sellers[sellerId] ?? const <String, dynamic>{};
    final shop = Map<String, dynamic>.from(user['shop'] as Map? ?? const {});
    return shop['verified'] == true;
  }

  void onSearchChanged(String value) =>
      query.value = value.trim().toLowerCase();

  void selectTab(int index) => tab.value = index;

  Future<void> _loadMissingSellers() async {
    final ids = matching
        .map(sellerOf)
        .where((id) => id.isNotEmpty && _requested.add(id))
        .toList();
    if (ids.isEmpty) return;
    final entries = await Future.wait(
      ids.map((id) async => MapEntry(id, await _profiles.get(id))),
    );
    if (isClosed) return;
    sellers.addEntries(entries);
  }

  /// True once every seller of [products] has a loaded profile.
  bool sellersReady(Iterable<Map<String, dynamic>> products) => products
      .map(sellerOf)
      .where((id) => id.isNotEmpty)
      .every(sellers.containsKey);

  void openCart() => Get.toNamed<void>(AppRoutes.cart);

  void openBoutique({
    required String sellerId,
    required String shopName,
    required String description,
    required List<Map<String, dynamic>> products,
  }) => Get.to<void>(
    () => BoutiqueDetailPage(
      sellerId: sellerId,
      shopName: shopName,
      description: description,
      products: products,
    ),
  );

  void openProduct(Map<String, dynamic> product) => Get.to<void>(
    () => ProductDetailPage(
      productId: product['id']?.toString(),
      productData: product,
    ),
  );
}
