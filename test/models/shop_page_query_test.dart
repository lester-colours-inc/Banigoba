import 'package:banigoba/modules/shop/models/shop_filters.dart';
import 'package:banigoba/modules/shop/models/shop_page_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shopQueryParams', () {
    test('sends no filters as empty lists, null prices and false flags', () {
      final params = shopQueryParams(query: '', filters: const ShopFilters());

      expect(params, {
        'p_query': '',
        'p_categories': <String>[],
        'p_genders': <String>[],
        'p_styles': <String>[],
        'p_sizes': <String>[],
        'p_colours': <String>[],
        'p_min_price': null,
        'p_max_price': null,
        'p_in_stock': false,
        'p_new_only': false,
      });
    });

    test('lower-cases the search and the chips, upper-cases sizes', () {
      final params = shopQueryParams(
        query: '  Linen Shirt ',
        filters: const ShopFilters(
          categories: {'Tops', 'shoes'},
          genders: {'Female'},
          styles: {'Casual'},
          sizes: {'m', ' uk 8 ', 'XL'},
          colours: {'Black', 'white'},
          minPrice: 20,
          maxPrice: 80.5,
          inStockOnly: true,
          newOnly: true,
        ),
      );

      expect(params['p_query'], 'linen shirt');
      expect(params['p_categories'], ['shoes', 'tops']);
      expect(params['p_genders'], ['female']);
      expect(params['p_styles'], ['casual']);
      expect(params['p_sizes'], ['M', 'UK 8', 'XL']);
      expect(params['p_colours'], ['black', 'white']);
      expect(params['p_min_price'], 20);
      expect(params['p_max_price'], 80.5);
      expect(params['p_in_stock'], isTrue);
      expect(params['p_new_only'], isTrue);
    });
  });

  group('shopPageParams', () {
    test('adds the sort, the viewer and the page to the filters', () {
      final params = shopPageParams(
        query: 'bottoms',
        filters: const ShopFilters(sort: ShopSort.priceHighLow),
        viewerGender: 'male',
        offset: 60,
      );

      expect(params['p_query'], 'bottoms');
      expect(params['p_sort'], 'priceHighLow');
      expect(params['p_viewer_gender'], 'male');
      expect(params['p_offset'], 60);
      expect(params['p_limit'], kShopPageSize);
    });

    test('names every sort the way the database function reads it', () {
      final names = [
        for (final sort in ShopSort.values)
          shopPageParams(
            query: '',
            filters: ShopFilters(sort: sort),
            viewerGender: null,
            offset: 0,
          )['p_sort'],
      ];

      expect(names, [
        'forYou',
        'newest',
        'priceLowHigh',
        'priceHighLow',
        'nameAZ',
      ]);
    });

    test('sends no viewer gender when the viewer has none', () {
      final params = shopPageParams(
        query: '',
        filters: const ShopFilters(),
        viewerGender: null,
        offset: 0,
      );

      expect(params['p_viewer_gender'], isNull);
    });
  });

  group('ShopFilterOptions.fromFacets', () {
    test('sorts the chips and rounds the price up to the next 10', () {
      final options = ShopFilterOptions.fromFacets({
        'categories': ['tops', 'bottoms'],
        'genders': ['male', 'female'],
        'sizes': ['UK 10', 'XL', 'M', 'UK 4', 'XS'],
        'colours': ['white', 'black'],
        'styles': ['streetwear', 'casual'],
        'maxPrice': 110.49,
      });

      expect(options.categories, ['bottoms', 'tops']);
      expect(options.genders, ['female', 'male']);
      expect(options.sizes, ['XS', 'M', 'XL', 'UK 4', 'UK 10']);
      expect(options.colours, ['black', 'white']);
      expect(options.styles, ['casual', 'streetwear']);
      expect(options.priceCeiling, 120);
    });

    test('is empty for an empty marketplace', () {
      final options = ShopFilterOptions.fromFacets({});

      expect(options.categories, isEmpty);
      expect(options.sizes, isEmpty);
      expect(options.priceCeiling, 0);
    });
  });
}
