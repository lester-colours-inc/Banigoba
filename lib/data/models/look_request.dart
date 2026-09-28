// What a single makeover asks for: which part of the person to change (scope)
// and where the idea comes from (source).
//
// Phase 3 of the work plan. People see themselves first and buy afterwards,
// so no source here is a product catalogue.
//
// A look is built one item at a time (September 2026 feedback): the scope
// expands into [LookPart]s, and each part is generated, shown and kept or
// redone before the next one starts. See look_session.dart.
import 'package:flutter/foundation.dart';

import 'body_profile.dart';
import 'style_preferences.dart';

/// One item a makeover step changes. Steps run in declaration order.
enum LookPart {
  hair('Hair', 'the hair', 'Styling your hair'),
  outfit(
    'Clothes',
    'the clothes (top and bottom, or a dress), but not the shoes',
    'Changing your clothes',
  ),
  top('Top', 'the top half of the outfit', 'Changing your top'),
  bottom(
    'Bottom',
    'the bottom half of the outfit (trousers, skirt or shorts)',
    'Changing your bottoms',
  ),
  shoes('Shoes', 'the shoes', 'Choosing your shoes'),
  accessories(
    'Accessories',
    'the accessories, such as glasses, a hat, jewellery or a bag',
    'Adding accessories',
  );

  const LookPart(this.label, this.promptPhrase, this.progressLabel);

  final String label;

  /// How the part reads inside a generation prompt.
  final String promptPhrase;

  /// Shown while this part is being generated.
  final String progressLabel;

  bool get isHair => this == hair;
}

/// Which part of the person a makeover may change.
//
// UNCLEAR: the plan listed both "Full body" and "Outfit + hair". They describe
// the same change, so they are one option here ("Full look"). Confirm with
// the stakeholder whether "Full body" was meant to include shoes and
// accessories as a separate, bigger option.
enum LookScope {
  fullLook('Full look', [
    LookPart.hair,
    LookPart.outfit,
    LookPart.shoes,
    LookPart.accessories,
  ]),
  outfit('Outfit only', [
    LookPart.outfit,
    LookPart.shoes,
    LookPart.accessories,
  ]),
  hair('Hair only', [LookPart.hair]),
  top('Top only', [LookPart.top]),
  bottom('Bottom only', [LookPart.bottom]);

  const LookScope(this.label, this.parts);

  final String label;

  /// The items this scope changes, one step each, in order.
  final List<LookPart> parts;

  bool get changesHair => parts.any((part) => part.isHair);

  bool get changesClothing => parts.any((part) => !part.isHair);

  /// The default scope for a user's saved makeover preference.
  static LookScope fromFocus(MakeoverFocus? focus) => switch (focus) {
    MakeoverFocus.hair => LookScope.hair,
    MakeoverFocus.outfit => LookScope.outfit,
    MakeoverFocus.fullLook || null => LookScope.fullLook,
  };
}

/// A named style direction, offered under "Style idol" when the user has no
/// particular person in mind.
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

/// Where the idea for a look comes from.
sealed class LookSource {
  const LookSource();

  /// True when the source has enough input to generate from.
  bool get isComplete;

  /// Images the model sees after the person's photo.
  List<String> get referenceImageUrls => const [];

  /// Whether this idea says anything about [part]. Parts it does not speak
  /// to are left out of the step-by-step run.
  bool appliesTo(LookPart part) => true;
}

/// The user describes the look in their own words.
final class DescribeSource extends LookSource {
  const DescribeSource(this.description);

  final String description;

  @override
  bool get isComplete => description.trim().isNotEmpty;
}

/// Dressed the way someone the user admires dresses. Either a person they
/// name themselves, or a style archetype when they have nobody in mind.
final class IdolSource extends LookSource {
  const IdolSource({this.idolName = '', this.archetype});

  final String idolName;
  final StyleArchetype? archetype;

  @override
  bool get isComplete => idolName.trim().isNotEmpty || archetype != null;
}

/// Copies a look the user has seen: a friend's post, a community post or a
/// photo from their gallery.
final class TwinSource extends LookSource {
  const TwinSource({this.imageUrl = ''});

  final String imageUrl;

  @override
  bool get isComplete => imageUrl.isNotEmpty;

  @override
  List<String> get referenceImageUrls => isComplete ? [imageUrl] : const [];
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

  /// A hair trend only changes hair; a clothing trend never touches it.
  @override
  bool appliesTo(LookPart part) =>
      (trend?.isHair ?? false) ? part.isHair : !part.isHair;
}

/// Everything needed to generate a look.
@immutable
class LookRequest {
  const LookRequest({
    required this.photoUrl,
    required this.scope,
    required this.source,
    this.extraNote = '',
    this.body = const BodyProfile(),
  });

  final String photoUrl;
  final LookScope scope;
  final LookSource source;

  /// Optional extra words the user adds to any non-describe source.
  final String extraNote;

  /// The user's profile details: clothes are fitted to their real size, and
  /// a Fashion Idol or Style twin look keeps their face from the face photo.
  final BodyProfile body;

  /// The steps this request runs, in order.
  List<LookPart> get parts =>
      scope.parts.where(source.appliesTo).toList(growable: false);

  /// Idol and twin looks borrow from someone else, so they are the ones at
  /// risk of drifting from the user's face; the face photo anchors it.
  bool get usesFacePhoto =>
      body.facePhotoUrl.isNotEmpty &&
      (source is IdolSource || source is TwinSource);

  /// Images the model sees after the person's photo, in prompt order: the
  /// source's references, then the face photo.
  List<String> get referenceImageUrls => [
    ...source.referenceImageUrls,
    if (usesFacePhoto) body.facePhotoUrl,
  ];

  bool get isReady =>
      photoUrl.isNotEmpty && source.isComplete && parts.isNotEmpty;

  /// A short caption for the saved post, e.g. "Afro-Chic look".
  String get caption => switch (source) {
    DescribeSource() => 'My new look',
    IdolSource(:final idolName, :final archetype) =>
      idolName.trim().isNotEmpty
          ? 'Inspired by ${idolName.trim()}'
          : '${archetype?.name ?? 'Style'} look',
    TwinSource() => 'My style twin look',
    WeatherSource() => "Today's weather look",
    TrendSource(:final trend) => '${trend?.name ?? 'Trending'} look',
  };
}

/// Builds the instruction for one step: change [part] only.
///
/// [tweak] carries the user's own words when they redo or edit a step.
///
/// Scoped so generation cannot wander into identity: the spec forbids
/// unsolicited changes to body shape, skin tone, facial structure or
/// protected characteristics.
String buildLookPrompt(
  LookRequest request, {
  required LookPart part,
  String tweak = '',
}) {
  final source = request.source;
  final hasReference = source.referenceImageUrls.isNotEmpty;
  final hasFace = request.usesFacePhoto;
  final note = request.extraNote.trim();
  final change = tweak.trim();
  final fit = part.isHair ? '' : request.body.fitSummary;

  return [
    if (hasReference)
      'The first image is a photo of a person. The second image shows a '
          'look they want to copy.'
    else if (hasFace)
      'The first image is a photo of a person.'
    else
      'The image is a photo of a person.',
    if (hasFace)
      'The ${hasReference ? 'third' : 'second'} image is a close-up of the '
          "same person's face; the face in the result must match it.",
    _idea(source, part),
    if (note.isNotEmpty) 'Also: "$note".',
    if (change.isNotEmpty) 'For this change they asked: "$change".',
    if (fit.isNotEmpty)
      'Fit the clothes to their real size: $fit. Use this only for how the '
          'clothes fit; never change their body shape.',
    'Change only ${part.promptPhrase}; leave everything else exactly as it '
        'is in ${hasReference || hasFace ? 'the first image' : 'the photo'}.',
    if (!part.isHair) 'Do not change the hair.',
    'Preserve the face, skin tone, body shape, pose, identity and background '
        'exactly. Generate one photorealistic image with natural lighting, '
        'sharp detail and no text or watermarks.',
  ].join(' ');
}

String _idea(LookSource source, LookPart part) => switch (source) {
  DescribeSource(:final description) =>
    'The person asked for: "${description.trim()}".',
  IdolSource(:final idolName, :final archetype) => [
    if (idolName.trim().isNotEmpty)
      'Take inspiration from the signature fashion style of '
          '${idolName.trim()}: how they dress and style themselves, never '
          'their face or body.',
    if (archetype != null)
      'Style it in the "${archetype.name}" direction: '
          '${archetype.promptHint}.',
  ].join(' '),
  TwinSource() =>
    'Copy the ${part.label.toLowerCase()} from the second image as closely '
        'as possible, fitted naturally to this person. Never copy the face, '
        'body or identity of the person in the second image.',
  WeatherSource(:final temperatureC, :final condition) =>
    'Make it practical and stylish for today\'s weather: '
        '${_weatherPhrase(temperatureC, condition)}.',
  TrendSource(:final trend) =>
    'Follow this current trend: ${trend?.name} (${trend?.promptHint}).',
};

String _weatherPhrase(double? temperatureC, String condition) {
  final parts = [
    if (temperatureC != null) '${temperatureC.round()}°C',
    if (condition.trim().isNotEmpty) condition.trim().toLowerCase(),
  ];
  return parts.isEmpty ? 'mild conditions' : parts.join(', ');
}
