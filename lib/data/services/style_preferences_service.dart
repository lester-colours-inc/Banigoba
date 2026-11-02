// Stores the optional style preferences asked after sign-up.
//
// `preferencesPrompted` records that the user has seen the question, whether
// they answered or skipped, so it is asked once and never nags.
import '../models/style_preferences.dart';
import 'profile_service.dart';

class StylePreferencesService {
  StylePreferencesService({ProfileService? profiles})
    : _profiles = profiles ?? ProfileService();

  final ProfileService _profiles;

  static const String promptedField = 'preferencesPrompted';

  /// Whether the post-sign-up preferences step still needs to be shown.
  static bool needsPrompt(Map<String, dynamic> userData) =>
      userData[promptedField] != true;

  /// Reads saved answers from a profile.
  static StylePreferences fromUserData(Map<String, dynamic> userData) {
    final rawStyles = userData['stylePreferences'];
    return StylePreferences(
      styles: rawStyles is List
          ? rawStyles.map((style) => style.toString()).toList()
          : const [],
      focus: MakeoverFocus.fromValue(userData['makeoverFocus']),
    );
  }

  Future<void> save(String userId, StylePreferences preferences) {
    return _profiles.update(userId, {
      promptedField: true,
      'stylePreferences': preferences.styles,
      'makeoverFocus': preferences.focus?.value,
    });
  }

  Future<void> skip(String userId) =>
      _profiles.update(userId, {promptedField: true});
}
