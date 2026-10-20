// Verifies people search matches names, and emails only in full.
import 'package:banigoba/ui/screens/main/search_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tariro = {
    'displayName': 'Tariro Muzaya',
    'email': 'tariro@example.com',
  };

  test('matches any part of the name', () {
    expect(matchesPersonSearch(tariro, 'tari'), isTrue);
    expect(matchesPersonSearch(tariro, 'muzaya'), isTrue);
  });

  test('matches an email only when typed in full', () {
    expect(matchesPersonSearch(tariro, 'tariro@example.com'), isTrue);
    expect(matchesPersonSearch(tariro, 'example.com'), isFalse);
    expect(matchesPersonSearch(tariro, '@'), isFalse);
  });

  test('an empty search matches nobody', () {
    expect(matchesPersonSearch(tariro, ''), isFalse);
  });
}
