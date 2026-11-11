// Optional style preferences a user gives after sign-up.
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'style_preferences.freezed.dart';

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
@freezed
abstract class StylePreferences with _$StylePreferences {
  const StylePreferences._();

  const factory StylePreferences({
    @Default([]) List<String> styles,
    MakeoverFocus? focus,
  }) = _StylePreferences;

  bool get isEmpty => styles.isEmpty && focus == null;
}
