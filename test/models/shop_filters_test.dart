import 'package:flutter_test/flutter_test.dart';

import 'package:banigoba/modules/shop/models/shop_filters.dart';

final _now = DateTime.utc(2026, 11, 13);

Map<String, dynamic> _product({
  required String name,
  String category = 'tops',
  String gender = 'unisex',
  String style = 'casual',
  double price = 10,
  List<String> colours = const [],
  Map<String, int>? sizes,
  int stock = 5,
  int ageDays = 30,
}) => {
  'name': name,
  'category': category,
  'gender': gender,
  'styleTag': style,
  'price': price,
  'colours': colours,
  'stock': stock,
  'sizeInventory': ?sizes,
  'createdAt': _now.subtract(Duration(days: ageDays)).toIso8601String(),
};

void main() {
  forYouTests();
  final tee = _product(
    name: 'Tee',
    price: 12,
    colours: ['White'],
    sizes: {'S': 2, 'M': 0, 'L': 4},
    ageDays: 3,
  );
  final dress = _product(
    name: 'Dress',
    category: 'dresses',
    gender: 'female',
    style: 'formal',
    price: 60,
    colours: ['Navy', 'black'],
    sizes: {'M': 1},
  );
  final jeans = _product(
    name: 'Jeans',
    category: 'bottoms',
    gender: 'male',
    price: 35,
    colours: ['Blue'],
    stock: 0,
  );
  final all = [tee, dress, jeans];

  List<String> names(List<Map<String, dynamic>> list) => [
    for (final p in list) p['name'] as String,
  ];

  group('applyShopFilters', () {
    test('returns everything newest first with no filters', () {
      expect(names(applyShopFilters(all, const ShopFilters(), now: _now)), [
        'Tee',
        'Dress',
        'Jeans',
      ]);
    });

    test('filters by category', () {
      const f = ShopFilters(categories: {'dresses', 'bottoms'});
      expect(names(applyShopFilters(all, f, now: _now)), ['Dress', 'Jeans']);
    });

    test('gender filter keeps unisex pieces', () {
      const f = ShopFilters(genders: {'female'});
      expect(names(applyShopFilters(all, f, now: _now)), ['Tee', 'Dress']);
    });

    test('size filter ignores sizes that are out of stock', () {
      const f = ShopFilters(sizes: {'M'});
      expect(names(applyShopFilters(all, f, now: _now)), ['Dress']);
    });

    test('colour filter is case-insensitive', () {
      const f = ShopFilters(colours: {'black'});
      expect(names(applyShopFilters(all, f, now: _now)), ['Dress']);
    });

    test('price range is inclusive', () {
      const f = ShopFilters(minPrice: 12, maxPrice: 35);
      expect(names(applyShopFilters(all, f, now: _now)), ['Tee', 'Jeans']);
    });

    test('in stock only drops sold out pieces', () {
      const f = ShopFilters(inStockOnly: true);
      expect(names(applyShopFilters(all, f, now: _now)), ['Tee', 'Dress']);
    });

    test('new only keeps recent listings', () {
      const f = ShopFilters(newOnly: true);
      expect(names(applyShopFilters(all, f, now: _now)), ['Tee']);
    });

    test('sorts by price both ways and by name', () {
      expect(
        names(
          applyShopFilters(all, const ShopFilters(sort: ShopSort.priceLowHigh)),
        ),
        ['Tee', 'Jeans', 'Dress'],
      );
      expect(
        names(
          applyShopFilters(all, const ShopFilters(sort: ShopSort.priceHighLow)),
        ),
        ['Dress', 'Jeans', 'Tee'],
      );
      expect(
        names(applyShopFilters(all, const ShopFilters(sort: ShopSort.nameAZ))),
        ['Dress', 'Jeans', 'Tee'],
      );
    });

    test('does not mutate the input list', () {
      final input = [jeans, tee];
      applyShopFilters(input, const ShopFilters(sort: ShopSort.nameAZ));
      expect(names(input), ['Jeans', 'Tee']);
    });
  });

  group('ShopFilters', () {
    test('counts active groups and clears them but keeps sort', () {
      const f = ShopFilters(
        categories: {'tops'},
        maxPrice: 20,
        inStockOnly: true,
        sort: ShopSort.priceLowHigh,
      );
      expect(f.activeCount, 3);
      final cleared = f.cleared();
      expect(cleared.isEmpty, isTrue);
      expect(cleared.sort, ShopSort.priceLowHigh);
    });

    test('copyWith can reset a price bound to null', () {
      const f = ShopFilters(minPrice: 5);
      expect(f.copyWith(minPrice: () => null).minPrice, isNull);
      expect(f.copyWith(inStockOnly: true).minPrice, 5);
    });

    test('toggled adds and removes without mutating', () {
      const start = {'a'};
      expect(toggled(start, 'b'), {'a', 'b'});
      expect(toggled(start, 'a'), isEmpty);
      expect(start, {'a'});
    });
  });

  group('ShopFilterOptions', () {
    test('derives sorted options and drops unisex from genders', () {
      final options = ShopFilterOptions.from(all);
      expect(options.categories, ['bottoms', 'dresses', 'tops']);
      expect(options.genders, ['female', 'male']);
      expect(options.sizes, ['S', 'M', 'L']);
      expect(options.colours, ['black', 'blue', 'navy', 'white']);
      expect(options.priceCeiling, 60);
    });

    test('rounds the price ceiling up to the next ten', () {
      final options = ShopFilterOptions.from([_product(name: 'x', price: 61)]);
      expect(options.priceCeiling, 70);
    });
  });

  test('sortSizes orders letters, then numbers, then the rest', () {
    expect(sortSizes(['L', '42', 'One size', 'XS', '8', 'M']), [
      'XS',
      'M',
      'L',
      '8',
      '42',
      'One size',
    ]);
  });

  test('productStock prefers per-size inventory', () {
    expect(productStock(tee), 6);
    expect(productStock(jeans), 0);
  });

  test('filterLabel humanises values', () {
    expect(filterLabel('smart-casual'), 'Smart casual');
    expect(filterLabel('outerwear'), 'Outerwear');
  });
}

void forYouTests() {
  group('For you ordering', () {
    final maleTee = _product(name: 'M', gender: 'male', ageDays: 20);
    final unisexTee = _product(name: 'U', ageDays: 1);
    final femaleTop = _product(name: 'F', gender: 'female', ageDays: 2);
    final all = [femaleTop, unisexTee, maleTee];
    List<String> run(String? viewer) => [
      for (final p in applyShopFilters(
        all,
        const ShopFilters(),
        now: _now,
        viewerGender: viewer,
      ))
        p['name'] as String,
    ];

    test('male viewer sees male, then unisex, then female', () {
      expect(run('male'), ['M', 'U', 'F']);
    });

    test('female viewer sees female, then unisex, then male', () {
      expect(run('female'), ['F', 'U', 'M']);
    });

    test('unknown gender falls back to newest first', () {
      expect(run(null), ['U', 'F', 'M']);
    });
  });
}
