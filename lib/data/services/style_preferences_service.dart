// Stores the optional style preferences asked after sign-up.
//
// `preferencesPrompted` records that the user has seen the question, whether
// they answered or skipped, so it is asked once and never nags.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/style_preferences.dart';

class StylePreferencesService {
  StylePreferencesService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String promptedField = 'preferencesPrompted';

  /// Whether the post-sign-up preferences step still needs to be shown.
  static bool needsPrompt(Map<String, dynamic> userData) =>
      userData[promptedField] != true;

  /// Reads saved answers from a user document.
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
    return _users.doc(userId).set({
      promptedField: true,
      'stylePreferences': preferences.styles,
      // The single legacy field still drives the feed card's style label.
      if (preferences.styles.isNotEmpty)
        'stylePreference': preferences.styles.first.toLowerCase(),
      'makeoverFocus': preferences.focus?.value,
      'preferencesUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> skip(String userId) {
    return _users.doc(userId).set({
      promptedField: true,
    }, SetOptions(merge: true));
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
}
