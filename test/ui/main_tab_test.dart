// The five consumer destinations are a spec commitment (BNG SRS 001), so
// their identity and order are asserted rather than left to layout drift.
import 'package:banigoba/core/main_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MainTab', () {
    test('is exactly Home, Discover, Create, Wardrobe, Profile in order', () {
      expect(MainTab.values.map((tab) => tab.label), [
        'Home',
        'Discover',
        'Create',
        'Wardrobe',
        'Profile',
      ]);
    });

    test('places Create in the centre', () {
      expect(MainTab.create.position, 2);
      expect(MainTab.values.length, 5);
    });

    test('position matches declaration order', () {
      for (var index = 0; index < MainTab.values.length; index += 1) {
        expect(MainTab.values[index].position, index);
      }
    });

    test('fromIndex round-trips every tab', () {
      for (final tab in MainTab.values) {
        expect(MainTab.fromIndex(tab.position), tab);
      }
    });

    test('fromIndex falls back to Home rather than throwing', () {
      expect(MainTab.fromIndex(-1), MainTab.home);
      expect(MainTab.fromIndex(99), MainTab.home);
    });

    test('Notifications is not a destination', () {
      expect(
        MainTab.values.map((tab) => tab.label),
        isNot(contains('Notifications')),
      );
    });
  });
}
