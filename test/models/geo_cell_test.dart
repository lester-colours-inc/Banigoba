import 'package:banigoba/data/models/geo_cell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeoCell.fromLatLng', () {
    test('puts nearby points in the same cell', () {
      // Two spots in Harare, a few km apart.
      final a = GeoCell.fromLatLng(-17.8292, 31.0522);
      final b = GeoCell.fromLatLng(-17.8100, 31.0600);

      expect(a, b);
    });

    test('floors negative coordinates instead of rounding towards zero', () {
      expect(GeoCell.fromLatLng(-0.01, -0.01), const GeoCell(-1, -1));
      expect(GeoCell.fromLatLng(0.01, 0.01), const GeoCell(0, 0));
    });

    test('is about 22 km wide', () {
      expect(kCellDegrees, closeTo(0.2, 0.0001));
    });
  });

  group('key and parse', () {
    test('round-trip, including negative cells', () {
      const cell = GeoCell(-90, 155);

      expect(cell.key, '-90:155');
      expect(GeoCell.tryParse(cell.key), cell);
    });

    test('rejects anything that is not a cell', () {
      expect(GeoCell.tryParse(null), isNull);
      expect(GeoCell.tryParse(''), isNull);
      expect(GeoCell.tryParse('harare'), isNull);
      expect(GeoCell.tryParse('1:2:3'), isNull);
      expect(GeoCell.tryParse('a:b'), isNull);
    });
  });

  group('isNear', () {
    test('the same cell and the eight around it are near', () {
      const home = GeoCell(10, 10);

      for (var dx = -1; dx <= 1; dx += 1) {
        for (var dy = -1; dy <= 1; dy += 1) {
          expect(home.isNear(GeoCell(10 + dx, 10 + dy)), isTrue);
        }
      }
    });

    test('two cells away is not near', () {
      const home = GeoCell(10, 10);

      expect(home.isNear(const GeoCell(12, 10)), isFalse);
      expect(home.isNear(const GeoCell(10, 8)), isFalse);
    });

    test('Harare and Bulawayo are not near; Harare and its suburbs are', () {
      final harare = GeoCell.fromLatLng(-17.8292, 31.0522);

      expect(harare.isNear(GeoCell.fromLatLng(-20.1325, 28.6265)), isFalse);
      expect(harare.isNear(GeoCell.fromLatLng(-17.7600, 31.1100)), isTrue);
    });
  });
}
