import 'package:banigoba/data/utils/stock_status.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _p({num? stock, Map<String, dynamic>? sizes}) => {
  'stock': ?stock,
  'sizeInventory': ?sizes,
};

void main() {
  reachTests();
  group('totalStock', () {
    test('adds up the sizes', () {
      expect(totalStock(_p(sizes: {'S': 2, 'M': 3})), 5);
    });

    test('uses the single count for a one-size piece', () {
      expect(totalStock(_p(stock: 4)), 4);
    });

    test('is zero when nothing is recorded', () {
      expect(totalStock(_p()), 0);
    });
  });

  group('stockLevelOf', () {
    test('is sold out at zero', () {
      expect(stockLevelOf(_p(stock: 0)), StockLevel.soldOut);
      expect(stockLevelOf(_p(sizes: {'M': 0, 'L': 0})), StockLevel.soldOut);
    });

    test('is low at two or fewer', () {
      expect(stockLevelOf(_p(stock: 2)), StockLevel.low);
      expect(stockLevelOf(_p(sizes: {'M': 1, 'L': 1})), StockLevel.low);
    });

    test('is in stock above that', () {
      expect(stockLevelOf(_p(stock: 3)), StockLevel.inStock);
    });
  });

  group('summarizeStock', () {
    final products = [
      _p(stock: 0),
      _p(stock: 1),
      _p(stock: 9),
      _p(sizes: {'M': 0}),
    ];

    test('counts every product, the sold out and the low ones', () {
      final summary = summarizeStock(products);

      expect(summary.total, 4);
      expect(summary.soldOut, 2);
      expect(summary.low, 1);
    });

    test('filters by level, and "all" keeps everything', () {
      expect(filterByStock(products, null), hasLength(4));
      expect(filterByStock(products, StockLevel.soldOut), hasLength(2));
      expect(filterByStock(products, StockLevel.low), hasLength(1));
    });
  });
}

void reachTests() {
  group('reachLabel', () {
    test('says how many followers a piece was shown to', () {
      expect(reachLabel(reach: 4, followers: 9), 'Shown to 4 of 9 followers');
      expect(reachLabel(reach: 1, followers: 1), 'Shown to 1 of 1 follower');
    });

    test('says so when no follower suited it yet', () {
      expect(reachLabel(reach: 0, followers: 9), 'No follower matched it yet');
    });

    test('says so when the shop has no followers', () {
      expect(reachLabel(reach: 0, followers: 0), 'No followers yet');
    });

    test('says nothing for a piece listed before this existed', () {
      expect(reachLabel(reach: null, followers: null), isNull);
    });
  });
}
