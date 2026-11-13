// The marketplace search and filters as the arguments of the `shop_products`,
// `shop_products_count` and `shop_facets` database functions
// (supabase/migrations/20261113000002_shop_products_page.sql), which do the
// same searching, filtering and sorting as shop_filters.dart but one page at a
// time. A pure function, so the argument rules can be unit tested.
library;

import 'package:banigoba/modules/shop/models/shop_filters.dart';

/// How many products the All Products grid asks for at a time.
const int kShopPageSize = 30;

/// One page of the marketplace, with how many products match in all.
typedef ShopProductsPage = ({List<Map<String, dynamic>> products, int total});

/// The search and filter arguments shared by `shop_products` and
/// `shop_products_count`. Lists are lower-cased (sizes upper-cased) and
/// sorted, as the filter chips hold them.
Map<String, dynamic> shopQueryParams({
  required String query,
  required ShopFilters filters,
}) {
  List<String> lower(Set<String> values) =>
      [for (final value in values) value.trim().toLowerCase()]..sort();
  return {
    'p_query': query.trim().toLowerCase(),
    'p_categories': lower(filters.categories),
    'p_genders': lower(filters.genders),
    'p_styles': lower(filters.styles),
    'p_sizes': [for (final size in filters.sizes) size.trim().toUpperCase()]
      ..sort(),
    'p_colours': lower(filters.colours),
    'p_min_price': filters.minPrice,
    'p_max_price': filters.maxPrice,
    'p_in_stock': filters.inStockOnly,
    'p_new_only': filters.newOnly,
  };
}

/// The arguments of `shop_products`: the search and filters, the sort, whose
/// pieces "For you" puts first, and which page to return.
Map<String, dynamic> shopPageParams({
  required String query,
  required ShopFilters filters,
  required String? viewerGender,
  required int offset,
  int limit = kShopPageSize,
}) => {
  ...shopQueryParams(query: query, filters: filters),
  'p_sort': filters.sort.name,
  'p_viewer_gender': viewerGender,
  'p_limit': limit,
  'p_offset': offset,
};
