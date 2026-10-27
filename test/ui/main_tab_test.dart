// The consumer destinations are a product commitment, so their identity and
// order are asserted rather than left to layout drift. Create was removed as a
// tab in the September 2026 review: a makeover starts from Home's floating
// Makeover button instead.
import 'package:banigoba/core/main_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MainTab', () {
    test('is exactly Home, Discover, Wardrobe, Profile in order', () {
      expect(MainTab.values.map((tab) => tab.label), [
        'Home',
        'Discover',
        'Wardrobe',
        'Profile',
      ]);
    });

    test('Create is not a destination', () {
      expect(MainTab.values.map((tab) => tab.label), isNot(contains('Create')));
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
