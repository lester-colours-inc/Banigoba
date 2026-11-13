// Marketplace filters and sorting for the Shops & Boutiques page.
//
// Pure functions over product maps so the rules can be unit tested without
// Supabase. Filter options are derived from the loaded catalogue, so chips
// only offer values that actually exist.
library;

/// How the product grid is ordered.
enum ShopSort {
  /// Pieces for the viewer's gender first, then unisex, then the rest.
  forYou('For you'),
  newest('Newest'),
  priceLowHigh('Price: low to high'),
  priceHighLow('Price: high to low'),
  nameAZ('Name: A to Z');

  const ShopSort(this.label);
  final String label;
}

/// How the boutique list is ordered.
enum BoutiqueSort {
  mostProducts('Most products'),
  newestArrivals('Newest arrivals'),
  nameAZ('Name: A to Z');

  const BoutiqueSort(this.label);
  final String label;
}

/// Products created within this window get a "New" badge.
const Duration kNewArrivalWindow = Duration(days: 14);

/// At or below this many pieces a product shows "Only N left".
const int kLowStockThreshold = 3;

/// Immutable filter selection. Empty sets mean "any".
class ShopFilters {
  const ShopFilters({
    this.categories = const {},
    this.genders = const {},
    this.sizes = const {},
    this.colours = const {},
    this.styles = const {},
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = false,
    this.newOnly = false,
    this.sort = ShopSort.forYou,
  });

  final Set<String> categories;
  final Set<String> genders;
  final Set<String> sizes;
  final Set<String> colours;
  final Set<String> styles;
  final double? minPrice;
  final double? maxPrice;
  final bool inStockOnly;
  final bool newOnly;
  final ShopSort sort;

  /// Number of active filter groups (sort is not a filter).
  int get activeCount => [
    categories.isNotEmpty,
    genders.isNotEmpty,
    sizes.isNotEmpty,
    colours.isNotEmpty,
    styles.isNotEmpty,
    minPrice != null || maxPrice != null,
    inStockOnly,
    newOnly,
  ].where((active) => active).length;

  bool get isEmpty => activeCount == 0;

  ShopFilters copyWith({
    Set<String>? categories,
    Set<String>? genders,
    Set<String>? sizes,
    Set<String>? colours,
    Set<String>? styles,
    double? Function()? minPrice,
    double? Function()? maxPrice,
    bool? inStockOnly,
    bool? newOnly,
    ShopSort? sort,
  }) => ShopFilters(
    categories: categories ?? this.categories,
    genders: genders ?? this.genders,
    sizes: sizes ?? this.sizes,
    colours: colours ?? this.colours,
    styles: styles ?? this.styles,
    minPrice: minPrice == null ? this.minPrice : minPrice(),
    maxPrice: maxPrice == null ? this.maxPrice : maxPrice(),
    inStockOnly: inStockOnly ?? this.inStockOnly,
    newOnly: newOnly ?? this.newOnly,
    sort: sort ?? this.sort,
  );

  /// Clears every filter but keeps the chosen sort.
  ShopFilters cleared() => ShopFilters(sort: sort);
}

/// Returns a new set with [value] added or removed.
Set<String> toggled(Set<String> set, String value) =>
    set.contains(value) ? ({...set}..remove(value)) : {...set, value};

// ── Field readers ────────────────────────────────────────────────────────

String _lower(Object? value) => (value ?? '').toString().trim().toLowerCase();

String productCategory(Map<String, dynamic> p) => _lower(p['category']);
String productGender(Map<String, dynamic> p) => _lower(p['gender']);
String productStyle(Map<String, dynamic> p) => _lower(p['styleTag']);

double productPrice(Map<String, dynamic> p) =>
    (p['price'] as num?)?.toDouble() ?? 0;

Set<String> productColours(Map<String, dynamic> p) =>
    {for (final c in p['colours'] as List? ?? const []) _lower(c)}..remove('');

/// Sizes with at least one piece in stock, or the single `size` field.
Set<String> productSizes(Map<String, dynamic> p) {
  final inventory = p['sizeInventory'];
  if (inventory is Map && inventory.isNotEmpty) {
    return {
      for (final entry in inventory.entries)
        if (((entry.value as num?) ?? 0) > 0)
          entry.key.toString().trim().toUpperCase(),
    }..remove('');
  }
  final size = (p['size'] ?? '').toString().trim().toUpperCase();
  return size.isEmpty ? {} : {size};
}

/// Pieces available, summing per-size stock when present.
int productStock(Map<String, dynamic> p) {
  final inventory = p['sizeInventory'];
  if (inventory is Map && inventory.isNotEmpty) {
    return inventory.values.fold<int>(
      0,
      (sum, v) => sum + ((v as num?)?.toInt() ?? 0),
    );
  }
  return (p['stock'] as num?)?.toInt() ?? 0;
}

DateTime? productCreatedAt(Map<String, dynamic> p) =>
    DateTime.tryParse((p['createdAt'] ?? '').toString());

bool isNewArrival(Map<String, dynamic> p, {DateTime? now}) {
  final created = productCreatedAt(p);
  if (created == null) return false;
  return (now ?? DateTime.now()).difference(created) <= kNewArrivalWindow;
}

// ── Filtering and sorting ────────────────────────────────────────────────

bool productMatchesFilters(
  Map<String, dynamic> p,
  ShopFilters f, {
  DateTime? now,
}) {
  if (f.categories.isNotEmpty && !f.categories.contains(productCategory(p))) {
    return false;
  }
  // Unisex pieces suit anyone, so they pass any gender filter.
  final gender = productGender(p);
  if (f.genders.isNotEmpty &&
      gender != 'unisex' &&
      !f.genders.contains(gender)) {
    return false;
  }
  if (f.styles.isNotEmpty && !f.styles.contains(productStyle(p))) {
    return false;
  }
  if (f.sizes.isNotEmpty && productSizes(p).intersection(f.sizes).isEmpty) {
    return false;
  }
  if (f.colours.isNotEmpty &&
      productColours(p).intersection(f.colours).isEmpty) {
    return false;
  }
  final price = productPrice(p);
  if (f.minPrice != null && price < f.minPrice!) return false;
  if (f.maxPrice != null && price > f.maxPrice!) return false;
  if (f.inStockOnly && productStock(p) <= 0) return false;
  if (f.newOnly && !isNewArrival(p, now: now)) return false;
  return true;
}

/// Filters then sorts [products]. Does not mutate the input.
List<Map<String, dynamic>> applyShopFilters(
  Iterable<Map<String, dynamic>> products,
  ShopFilters filters, {
  DateTime? now,
  String? viewerGender,
}) {
  final result = [
    for (final p in products)
      if (productMatchesFilters(p, filters, now: now)) p,
  ];
  result.sort(_comparatorFor(filters.sort, viewerGender));
  return result;
}

/// 0 for the viewer's own gender, 1 for unisex, 2 for everything else.
int genderRank(Map<String, dynamic> p, String? viewerGender) {
  if (viewerGender == null) return 0;
  final gender = productGender(p);
  if (gender == viewerGender) return 0;
  return gender == 'unisex' || gender.isEmpty ? 1 : 2;
}

int Function(Map<String, dynamic>, Map<String, dynamic>) _comparatorFor(
  ShopSort sort,
  String? viewerGender,
) {
  switch (sort) {
    case ShopSort.forYou:
      final newest = _comparatorFor(ShopSort.newest, null);
      return (a, b) {
        final byGender = genderRank(
          a,
          viewerGender,
        ).compareTo(genderRank(b, viewerGender));
        return byGender != 0 ? byGender : newest(a, b);
      };
    case ShopSort.newest:
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      return (a, b) => (productCreatedAt(b) ?? epoch).compareTo(
        productCreatedAt(a) ?? epoch,
      );
    case ShopSort.priceLowHigh:
      return (a, b) => productPrice(a).compareTo(productPrice(b));
    case ShopSort.priceHighLow:
      return (a, b) => productPrice(b).compareTo(productPrice(a));
    case ShopSort.nameAZ:
      return (a, b) => _lower(a['name']).compareTo(_lower(b['name']));
  }
}

// ── Options derived from the catalogue ───────────────────────────────────

/// The values present in the catalogue, used to build filter chips.
class ShopFilterOptions {
  const ShopFilterOptions({
    required this.categories,
    required this.genders,
    required this.sizes,
    required this.colours,
    required this.styles,
    required this.priceCeiling,
  });

  factory ShopFilterOptions.from(Iterable<Map<String, dynamic>> products) {
    final categories = <String>{};
    final genders = <String>{};
    final sizes = <String>{};
    final colours = <String>{};
    final styles = <String>{};
    var ceiling = 0.0;
    for (final p in products) {
      categories.add(productCategory(p));
      genders.add(productGender(p));
      sizes.addAll(productSizes(p));
      colours.addAll(productColours(p));
      styles.add(productStyle(p));
      final price = productPrice(p);
      if (price > ceiling) ceiling = price;
    }
    for (final set in [categories, genders, styles]) {
      set.remove('');
    }
    genders.remove('unisex');
    return ShopFilterOptions(
      categories: categories.toList()..sort(),
      genders: genders.toList()..sort(),
      sizes: sortSizes(sizes),
      colours: colours.toList()..sort(),
      styles: styles.toList()..sort(),
      priceCeiling: ceiling <= 0 ? 0 : (ceiling / 10).ceil() * 10.0,
    );
  }

  final List<String> categories;
  final List<String> genders;
  final List<String> sizes;
  final List<String> colours;
  final List<String> styles;

  /// Highest price rounded up to the next 10, for the price slider.
  final double priceCeiling;
}

const List<String> _apparelSizeOrder = [
  'XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL', '2XL', 'XXXL', '3XL', '4XL', //
];

/// Apparel letters in natural order, then numeric sizes ascending, then the
/// rest alphabetically.
List<String> sortSizes(Iterable<String> sizes) {
  int rank(String s) {
    final apparel = _apparelSizeOrder.indexOf(s);
    if (apparel >= 0) return apparel;
    return num.tryParse(s) != null ? 100 : 200;
  }

  return sizes.toList()..sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    final na = num.tryParse(a);
    final nb = num.tryParse(b);
    if (na != null && nb != null) return na.compareTo(nb);
    return a.compareTo(b);
  });
}

/// "outerwear" → "Outerwear", "smart-casual" → "Smart casual".
String filterLabel(String value) {
  final text = value.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}
