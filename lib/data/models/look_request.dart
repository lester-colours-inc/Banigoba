// What a single makeover asks for: which part of the person to change (scope)
// and where the idea comes from (source).
//
// Phase 3 of the work plan. People see themselves first and buy afterwards,
// so no source here is a product catalogue.
import 'package:flutter/foundation.dart';

import 'style_preferences.dart';

/// Which part of the person a makeover may change.
//
// UNCLEAR: the plan listed both "Full body" and "Outfit + hair". They describe
// the same change, so they are one option here ("Full look"). Confirm with
// the stakeholder whether "Full body" was meant to include shoes and
// accessories as a separate, bigger option.
enum LookScope {
  fullLook('Full look', 'the hair and the whole outfit, including shoes'),
  outfit('Outfit only', 'the whole outfit, including shoes'),
  hair('Hair only', 'the hair only'),
  top('Top only', 'the top half of the outfit only'),
  bottom('Bottom only', 'the bottom half of the outfit only');

  const LookScope(this.label, this.promptPhrase);

  final String label;

  /// How the scope reads inside a generation prompt.
  final String promptPhrase;

  bool get changesHair => this == fullLook || this == hair;

  bool get changesClothing => this != hair;

  /// The default scope for a user's saved makeover preference.
  static LookScope fromFocus(MakeoverFocus? focus) => switch (focus) {
    MakeoverFocus.hair => LookScope.hair,
    MakeoverFocus.outfit => LookScope.outfit,
    MakeoverFocus.fullLook || null => LookScope.fullLook,
  };
}

/// A named style direction offered under "Style icon".
@immutable
class StyleArchetype {
  const StyleArchetype({
    required this.id,
    required this.name,
    required this.tagline,
    required this.promptHint,
  });

  final String id;
  final String name;

  /// One short line shown under the name.
  final String tagline;

  /// How the archetype is described to the image model.
  final String promptHint;
}

/// A trend offered under "Trending".
@immutable
class StyleTrend {
  const StyleTrend({
    required this.id,
    required this.name,
    required this.tagline,
    required this.promptHint,
    this.isHair = false,
  });

  final String id;
  final String name;
  final String tagline;
  final String promptHint;

  /// Hair trends are offered only when the scope changes hair; clothing
  /// trends only when it changes clothing.
  final bool isHair;

  bool fitsScope(LookScope scope) =>
      isHair ? scope.changesHair : scope.changesClothing;
}

/// Where the idea for a look comes from. One of four, per the meeting.
sealed class LookSource {
  const LookSource();

  /// True when the source has enough input to generate from.
  bool get isComplete;
}

/// The user describes the look in their own words.
final class DescribeSource extends LookSource {
  const DescribeSource(this.description);

  final String description;

  @override
  bool get isComplete => description.trim().isNotEmpty;
}

/// Based on a style archetype (a stand-in for fashion icons, see catalogue).
final class ArchetypeSource extends LookSource {
  const ArchetypeSource(this.archetype);

  final StyleArchetype? archetype;

  @override
  bool get isComplete => archetype != null;
}

/// Suited to the weather where the user is now.
final class WeatherSource extends LookSource {
  const WeatherSource({this.temperatureC, this.condition = ''});

  final double? temperatureC;
  final String condition;

  @override
  bool get isComplete => temperatureC != null || condition.trim().isNotEmpty;
}

/// Following a current trend.
final class TrendSource extends LookSource {
  const TrendSource(this.trend);

  final StyleTrend? trend;

  @override
  bool get isComplete => trend != null;
}

/// Everything needed to generate one look.
@immutable
class LookRequest {
  const LookRequest({
    required this.photoUrl,
    required this.scope,
    required this.source,
    this.extraNote = '',
  });

  final String photoUrl;
  final LookScope scope;
  final LookSource source;

  /// Optional extra words the user adds to any non-describe source.
  final String extraNote;

  bool get isReady => photoUrl.isNotEmpty && source.isComplete;

  /// A short caption for the saved post, e.g. "Afro-Chic look".
  String get caption => switch (source) {
    DescribeSource() => 'My new look',
    ArchetypeSource(:final archetype) => '${archetype?.name ?? 'Style'} look',
    WeatherSource() => "Today's weather look",
    TrendSource(:final trend) => '${trend?.name ?? 'Trending'} look',
  };
}

/// Builds the instruction sent to the image model.
///
/// Scoped so generation cannot wander into identity: the spec forbids
/// unsolicited changes to body shape, skin tone, facial structure or
/// protected characteristics.
String buildLookPrompt(LookRequest request) {
  final scope = request.scope;
  final idea = switch (request.source) {
    DescribeSource(:final description) =>
      'The person asked for: "${description.trim()}".',
    ArchetypeSource(:final archetype) =>
      'Style it in the "${archetype?.name}" direction: '
          '${archetype?.promptHint}.',
    WeatherSource(:final temperatureC, :final condition) =>
      'Make it practical and stylish for today\'s weather: '
          '${_weatherPhrase(temperatureC, condition)}.',
    TrendSource(:final trend) =>
      'Follow this current trend: ${trend?.name} (${trend?.promptHint}).',
  };
  final note = request.extraNote.trim();

  return [
    'The image is a photo of a person.',
    idea,
    if (note.isNotEmpty) 'Also: "$note".',
    'Change only ${scope.promptPhrase}; leave everything else exactly as '
        'photographed.',
    if (!scope.changesHair) 'Do not change the hair.',
    'Preserve the face, skin tone, body shape, pose, identity and background '
        'exactly. Generate one photorealistic image with natural lighting, '
        'sharp detail and no text or watermarks.',
  ].join(' ');
}

String _weatherPhrase(double? temperatureC, String condition) {
  final parts = [
    if (temperatureC != null) '${temperatureC.round()}°C',
    if (condition.trim().isNotEmpty) condition.trim().toLowerCase(),
  ];
  return parts.isEmpty ? 'mild conditions' : parts.join(', ');
}
