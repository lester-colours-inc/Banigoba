// Optional style preferences a user gives after sign-up.
import 'package:flutter/foundation.dart';

/// What the user wants a makeover to change by default.
enum MakeoverFocus {
  fullLook('full_look', 'Full look'),
  outfit('outfit', 'Outfit only'),
  hair('hair', 'Hair only');

  const MakeoverFocus(this.value, this.label);

  final String value;
  final String label;

  static MakeoverFocus? fromValue(Object? value) {
    for (final focus in MakeoverFocus.values) {
      if (focus.value == value) return focus;
    }
    return null;
  }
}

/// The answers collected by [StylePreferencesScreen].
@immutable
class StylePreferences {
  const StylePreferences({this.styles = const [], this.focus});

  final List<String> styles;
  final MakeoverFocus? focus;

  bool get isEmpty => styles.isEmpty && focus == null;
}
