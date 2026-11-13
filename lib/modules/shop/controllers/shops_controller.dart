// The customer marketplace: search, the Boutiques / All Products tabs, and
// the seller profiles used to show only admin-verified boutiques.
//
// All Products is paged on the server: the database searches, filters and sorts
// (shop_products) and the grid asks for the next page as it nears the end.
// Boutiques group every product by seller, so that tab still streams the whole
// catalogue, and only while it is showing.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/core/utils/garment_taxonomy.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/settings/services/private_account_service.dart';
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

  /// 'male' / 'female' from the viewer's profile, or null. Drives "For you".
  final RxnString viewerGender = RxnString();
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

  // ── All Products: one page at a time from the database ──────────────────

  final RxList<Map<String, dynamic>> pageProducts =
      <Map<String, dynamic>>[].obs;

  /// How many products match the search and filters in all.
  final RxInt pageTotal = 0.obs;

  /// True once the first page of the current search has arrived.
  final RxBool pageLoaded = false.obs;

  /// A first page is on its way (the old one stays on screen until then).
  final RxBool pageLoading = false.obs;
  final RxBool pageLoadingMore = false.obs;
  final RxBool pageHasMore = false.obs;
  final RxBool pageFailed = false.obs;
  final RxBool pageMoreFailed = false.obs;

  /// The chip values on offer, from the database. Until they arrive the
  /// loaded catalogue (if any) supplies them.
  final Rxn<ShopFilterOptions> facets = Rxn<ShopFilterOptions>();

  /// Bumped whenever the search or filters change, so an answer to an older
  /// question is dropped instead of replacing the newer one.
  int _pageRun = 0;
  bool _pageStarted = false;

  @override
  void onInit() {
    super.onInit();
    if (tab.value == 0) _startCatalogue();
    ever(tab, (_) => _showTab());
    ever(query, (_) => _loadMissingSellers());
    debounce(
      query,
      (_) => _reloadPageIfStarted(),
      time: const Duration(milliseconds: 300),
    );
    ever(filters, (_) => _reloadPageIfStarted());
    ever(viewerGender, (_) => _reloadPageIfStarted());
    _loadFacets();
    // "For you" needs the viewer's gender, so the first page waits for it.
    _loadViewerGender().whenComplete(() {
      if (!isClosed && tab.value == 1 && !_pageStarted) reloadPage();
    });
  }

  /// The Boutiques tab groups every product by seller, so it needs them all.
  void _startCatalogue() {
    if (_sub != null) return;
    _sub = _productService.getProducts().listen((rows) {
      failed.value = false;
      allProducts.assignAll(rows);
      loaded.value = true;
      _loadMissingSellers();
    }, onError: (Object _) => failed.value = true);
  }

  void _showTab() {
    if (tab.value == 0) {
      _startCatalogue();
    } else if (!_pageStarted) {
      reloadPage();
    }
  }

  void _reloadPageIfStarted() {
    if (_pageStarted) reloadPage();
  }

  Future<void> _loadFacets() async {
    try {
      final options = await _productService.shopFilterOptions();
      if (!isClosed) facets.value = options;
    } on Object catch (error) {
      debugPrint('Unable to load shop filter options: $error');
    }
  }

  /// Starts the All Products list again from the first page for the current
  /// search and filters (also what pull-to-refresh does).
  Future<void> reloadPage() async {
    _pageStarted = true;
    final run = ++_pageRun;
    pageFailed.value = false;
    pageMoreFailed.value = false;
    pageLoadingMore.value = false;
    pageLoading.value = true;
    try {
      final page = await _productService.shopProductsPage(
        query: query.value,
        filters: filters.value,
        viewerGender: viewerGender.value,
        offset: 0,
      );
      if (isClosed || run != _pageRun) return;
      pageProducts.assignAll(page.products);
      pageTotal.value = page.total;
      pageHasMore.value = page.products.length < page.total;
      pageLoaded.value = true;
    } on Object catch (error) {
      debugPrint('Unable to load products: $error');
      if (!isClosed && run == _pageRun) pageFailed.value = true;
    } finally {
      if (!isClosed && run == _pageRun) pageLoading.value = false;
    }
  }

  /// Adds the next page below what is on screen. Safe to call on every
  /// scroll: it does nothing while a page is loading or when there is no more.
  Future<void> loadMorePage() async {
    if (!pageHasMore.value ||
        pageLoading.value ||
        pageLoadingMore.value ||
        pageMoreFailed.value) {
      return;
    }
    final run = _pageRun;
    pageLoadingMore.value = true;
    try {
      final page = await _productService.shopProductsPage(
        query: query.value,
        filters: filters.value,
        viewerGender: viewerGender.value,
        offset: pageProducts.length,
      );
      if (isClosed || run != _pageRun) return;
      // A product added meanwhile can push one into the next page twice.
      final known = {for (final p in pageProducts) p['id']};
      pageProducts.addAll([
        for (final p in page.products)
          if (!known.contains(p['id'])) p,
      ]);
      pageTotal.value = page.total;
      pageHasMore.value =
          page.products.isNotEmpty && pageProducts.length < page.total;
    } on Object catch (error) {
      debugPrint('Unable to load more products: $error');
      if (!isClosed && run == _pageRun) pageMoreFailed.value = true;
    } finally {
      if (!isClosed && run == _pageRun) pageLoadingMore.value = false;
    }
  }

  /// Tries the page that failed again.
  void retryMore() {
    pageMoreFailed.value = false;
    loadMorePage();
  }

  /// How many products would match [candidate] with the current search, for
  /// the filter sheet's "Show N results".
  Future<int> countFor(ShopFilters candidate) =>
      _productService.shopProductCount(query: query.value, filters: candidate);

  Future<void> _loadViewerGender() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) return;
    try {
      final details = await PrivateAccountService().details(user.uid);
      if (!isClosed) viewerGender.value = details.shopsFor;
    } on Object {
      // Ordering just falls back to newest first.
    }
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
  List<Map<String, dynamic>> get filtered => applyShopFilters(
    matching,
    filters.value,
    viewerGender: viewerGender.value,
  );

  /// Chip values present in the whole marketplace (not narrowed by search, so
  /// options don't vanish while typing).
  ShopFilterOptions get filterOptions =>
      facets.value ?? ShopFilterOptions.from(allProducts);

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
    String imageUrl = '',
  }) => Get.to<void>(
    () => BoutiqueDetailPage(
      sellerId: sellerId,
      shopName: shopName,
      description: description,
      imageUrl: imageUrl,
      // The whole boutique, so its own filters start from everything.
      products: [
        for (final p in allProducts)
          if (sellerOf(p) == sellerId) p,
      ],
    ),
  );

  void openProduct(Map<String, dynamic> product) => Get.to<void>(
    () => ProductDetailPage(
      productId: product['id']?.toString(),
      productData: product,
    ),
  );
}
