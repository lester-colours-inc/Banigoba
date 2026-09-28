import 'package:banigoba/data/models/style_preferences.dart';
import 'package:banigoba/data/services/style_preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('needsPrompt', () {
    test('is true for a user who has never seen the question', () {
      expect(StylePreferencesService.needsPrompt({}), isTrue);
    });

    test('is false once answered or skipped', () {
      expect(
        StylePreferencesService.needsPrompt({'preferencesPrompted': true}),
        isFalse,
      );
    });
  });

  group('fromUserData', () {
    test('reads saved styles and focus', () {
      final preferences = StylePreferencesService.fromUserData({
        'stylePreferences': ['Smart', 'Sporty'],
        'makeoverFocus': 'full_look',
      });

      expect(preferences.styles, ['Smart', 'Sporty']);
      expect(preferences.focus, MakeoverFocus.fullLook);
    });

    test('tolerates missing and malformed fields', () {
      final preferences = StylePreferencesService.fromUserData({
        'stylePreferences': 'not a list',
        'makeoverFocus': 'unknown',
      });

      expect(preferences.isEmpty, isTrue);
    });
  });
}
