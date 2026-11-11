// Verifies @username rules and suggestions.
import 'package:banigoba/modules/onboarding/models/username.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('usernameProblem', () {
    test('accepts letters, numbers, dots and underscores', () {
      for (final ok in ['tariro', 'tariro.m', 'rudo_99', '@Tariro.M ']) {
        expect(usernameProblem(ok), isNull, reason: ok);
      }
    });

    test('rejects bad length, characters and dots', () {
      expect(usernameProblem('ab'), contains('at least'));
      expect(usernameProblem('a' * 21), contains('or fewer'));
      expect(usernameProblem('tariro m'), contains('only letters'));
      expect(usernameProblem('.tariro'), contains('start or end'));
      expect(usernameProblem('tariro.'), contains('start or end'));
      expect(usernameProblem('tari..ro'), contains('two dots'));
    });

    test('rejects reserved names', () {
      expect(usernameProblem('Banigoba'), contains('reserved'));
    });
  });

  test('normalizes case, spaces and a leading @', () {
    expect(normalizeUsername('  @Tariro.M '), 'tariro.m');
  });

  group('usernameFromName', () {
    test('joins the words of a name with dots', () {
      expect(usernameFromName('Tariro Muzaya'), 'tariro.muzaya');
      expect(usernameFromName("Rudo O'Brien-Moyo"), 'rudo.obrienmoyo');
    });

    test('keeps within the length limit without a trailing dot', () {
      final name = usernameFromName('Tinotendaishe Chimbwanda Moyo');
      expect(name.length, lessThanOrEqualTo(kUsernameMaxLength));
      expect(usernameProblem(name), isNull);
    });

    test('falls back when the name has nothing usable', () {
      expect(usernameFromName('李'), 'user');
      expect(usernameFromName('Al'), 'user');
    });
  });

  test('suggestions are all valid and distinct, name first', () {
    final suggestions = usernameSuggestions('Tariro Muzaya');
    expect(suggestions.first, 'tariro.muzaya');
    expect(suggestions.toSet(), hasLength(suggestions.length));
    for (final suggestion in suggestions) {
      expect(usernameProblem(suggestion), isNull, reason: suggestion);
    }
  });
}
