// A user's personal profile details: three photos (face, full body, hand), their sizes and their body
// measurements.
//
// Used by the eFitting Room (trying clothes on while shopping) so items are
// shown at the user's real size, and by Fashion Idol and Style twin makeovers
// so the look is fitted to the user's own face and build (September 2026
// request). Every detail is optional.
//
// These details are private. They are stored under the user's private
// subcollection, never on the public user document; see BodyProfileService.
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'body_profile.freezed.dart';

/// A body measurement the user can record, stored in [unit].
enum BodyMeasurement {
  height('height', 'Height', 'cm', 50, 250, 'Stand straight, without shoes.'),
  weight('weight', 'Weight', 'kg', 20, 300, 'Your usual weight.'),
  shoulders(
    'shoulders',
    'Shoulders',
    'cm',
    20,
    80,
    'Across your back, from one shoulder edge to the other.',
  ),
  waist(
    'waist',
    'Waist',
    'cm',
    40,
    200,
    'Around the narrowest part of your waist.',
  ),
  tummy(
    'tummy',
    'Tummy',
    'cm',
    40,
    220,
    'Around the fullest part of your tummy, level with your belly button.',
  ),
  chest(
    'chest',
    'Chest / bust',
    'cm',
    50,
    200,
    'Around the fullest part of your chest.',
  ),
  hips('hips', 'Hips', 'cm', 50, 220, 'Around the fullest part of your hips.'),
  insideLeg(
    'insideLeg',
    'Inside leg',
    'cm',
    40,
    110,
    'From the top of your inner thigh to the floor, without shoes.',
  );

  const BodyMeasurement(
    this.key,
    this.label,
    this.unit,
    this.min,
    this.max,
    this.howToMeasure,
  );

  /// Field name in the stored data.
  final String key;
  final String label;
  final String unit;
  final double min;
  final double max;
  final String howToMeasure;

  /// Asked for by name in the request, shown first.
  static const List<BodyMeasurement> requested = [
    height,
    weight,
    shoulders,
    waist,
    tummy,
  ];

  /// "Any other": useful for fit, tucked under "More measurements".
  static const List<BodyMeasurement> extra = [chest, hips, insideLeg];

  bool accepts(double value) => value >= min && value <= max;

  /// The value typed in [input], or null when blank or invalid.
  double? parse(String input) {
    final value = double.tryParse(input.trim().replaceAll(',', '.'));
    return value != null && accepts(value) ? value : null;
  }

  /// An error for [input], or null when it is blank or valid.
  String? validate(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null) return 'Enter a number';
    if (!accepts(value)) {
      return 'Between ${formatNumber(min)} and ${formatNumber(max)} $unit';
    }
    return null;
  }

  /// How the value reads in a sentence, e.g. "waist 80 cm".
  String describe(double value) => switch (this) {
    height => '${formatNumber(value)} cm tall',
    weight => '${formatNumber(value)} kg',
    _ => '${label.toLowerCase()} ${formatNumber(value)} $unit',
  };
}

/// Which of the two profile photos.
/// Hand: for trying on rings, bracelets, watches and nail looks.
enum BodyPhoto { face, fullBody, hand }

/// "80" rather than "80.0"; keeps a real decimal such as "80.5".
String formatNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

// copyWith stays hand-written: it freezes the measurements map.
@Freezed(copyWith: false)
abstract class BodyProfile with _$BodyProfile {
  const BodyProfile._();

  const factory BodyProfile({
    @Default('') String facePhotoUrl,
    @Default('') String fullBodyPhotoUrl,
    @Default('') String handPhotoUrl,
    @Default('') String clothingSize,

    /// UK size, e.g. "8" or "8.5".
    @Default('') String shoeSize,
    @Default({}) Map<BodyMeasurement, double> measurements,

    /// "Any other" details, in the user's own words.
    @Default('') String notes,
  }) = _BodyProfile;

  /// Offered as choices; the same labels sellers use for stock.
  static const List<String> clothingSizes = [
    'XXS',
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'XXXL',
  ];

  /// The details asked for by name: three photos (face, full body, hand), height, weight, clothing
  /// size, shoe size, shoulders, waist and tummy.
  static const int requestedDetailCount = 10;

  /// An error for a typed UK shoe size, or null when blank or valid.
  static String? validateShoeSize(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(_sizeKey(text, true).replaceAll(',', '.'));
    return value != null && value >= 1 && value <= 16
        ? null
        : 'Enter a UK size, e.g. 8';
  }

  /// "UK 8,5" → "8.5". Call only on input that passed [validateShoeSize].
  static String normalizeShoeSize(String input) =>
      _sizeKey(input, true).replaceAll(',', '.');

  double? operator [](BodyMeasurement measurement) => measurements[measurement];

  factory BodyProfile.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const BodyProfile();
    final rawMeasurements = data['measurements'];
    final measurements = <BodyMeasurement, double>{};
    if (rawMeasurements is Map) {
      for (final measurement in BodyMeasurement.values) {
        final value = _asDouble(rawMeasurements[measurement.key]);
        if (value != null && measurement.accepts(value)) {
          measurements[measurement] = value;
        }
      }
    }
    return BodyProfile(
      facePhotoUrl: _asString(data['facePhotoUrl']),
      fullBodyPhotoUrl: _asString(data['fullBodyPhotoUrl']),
      handPhotoUrl: _asString(data['handPhotoUrl']),
      clothingSize: _asString(data['clothingSize']).toUpperCase(),
      shoeSize: _asString(data['shoeSize']),
      measurements: Map.unmodifiable(measurements),
      notes: _asString(data['notes']),
    );
  }

  Map<String, dynamic> toMap() => {
    'facePhotoUrl': facePhotoUrl,
    'fullBodyPhotoUrl': fullBodyPhotoUrl,
    'handPhotoUrl': handPhotoUrl,
    'clothingSize': clothingSize,
    'shoeSize': shoeSize,
    'measurements': {
      for (final entry in measurements.entries) entry.key.key: entry.value,
    },
    'notes': notes,
  };

  BodyProfile copyWith({
    String? facePhotoUrl,
    String? fullBodyPhotoUrl,
    String? handPhotoUrl,
    String? clothingSize,
    String? shoeSize,
    Map<BodyMeasurement, double>? measurements,
    String? notes,
  }) => BodyProfile(
    facePhotoUrl: facePhotoUrl ?? this.facePhotoUrl,
    fullBodyPhotoUrl: fullBodyPhotoUrl ?? this.fullBodyPhotoUrl,
    handPhotoUrl: handPhotoUrl ?? this.handPhotoUrl,
    clothingSize: clothingSize ?? this.clothingSize,
    shoeSize: shoeSize ?? this.shoeSize,
    measurements: measurements == null
        ? this.measurements
        : Map.unmodifiable(measurements),
    notes: notes ?? this.notes,
  );

  String photoUrl(BodyPhoto photo) => switch (photo) {
    BodyPhoto.face => facePhotoUrl,
    BodyPhoto.fullBody => fullBodyPhotoUrl,
    BodyPhoto.hand => handPhotoUrl,
  };

  BodyProfile withPhoto(BodyPhoto photo, String url) => switch (photo) {
    BodyPhoto.face => copyWith(facePhotoUrl: url),
    BodyPhoto.fullBody => copyWith(fullBodyPhotoUrl: url),
    BodyPhoto.hand => copyWith(handPhotoUrl: url),
  };

  bool get isEmpty =>
      facePhotoUrl.isEmpty &&
      fullBodyPhotoUrl.isEmpty &&
      handPhotoUrl.isEmpty &&
      clothingSize.isEmpty &&
      shoeSize.isEmpty &&
      measurements.isEmpty &&
      notes.trim().isEmpty;

  /// How many of the [requestedDetailCount] details are filled in.
  int get detailsAdded => [
    facePhotoUrl.isNotEmpty,
    fullBodyPhotoUrl.isNotEmpty,
    handPhotoUrl.isNotEmpty,
    clothingSize.isNotEmpty,
    shoeSize.isNotEmpty,
    for (final measurement in BodyMeasurement.requested)
      measurements.containsKey(measurement),
  ].where((added) => added).length;

  /// Short labels for a summary row, e.g. ["172 cm", "Size M", "Shoe 8"].
  List<String> get highlights => [
    if (this[BodyMeasurement.height] case final height?)
      '${formatNumber(height)} cm',
    if (clothingSize.isNotEmpty) 'Size $clothingSize',
    if (shoeSize.isNotEmpty) 'Shoe $shoeSize',
    if (this[BodyMeasurement.waist] case final waist?)
      'Waist ${formatNumber(waist)} cm',
  ];

  /// Size and build in plain words, for an image model. Empty when nothing
  /// about size is known (photos alone say nothing about fit).
  String get fitSummary {
    const build = [BodyMeasurement.height, BodyMeasurement.weight];
    final facts = [
      for (final measurement in build)
        if (this[measurement] case final value?) measurement.describe(value),
      if (clothingSize.isNotEmpty) 'usually wears clothing size $clothingSize',
      if (shoeSize.isNotEmpty) 'UK shoe size $shoeSize',
      for (final measurement in BodyMeasurement.values)
        if (!build.contains(measurement))
          if (this[measurement] case final value?) measurement.describe(value),
    ];
    final note = notes.trim();
    if (facts.isEmpty && note.isEmpty) return '';
    return [
      facts.join(', '),
      if (note.isNotEmpty) 'they also noted: "$note"',
    ].where((part) => part.isNotEmpty).join('; ');
  }

  /// Instruction for the eFitting Room: show the item at the user's real
  /// size, and in [selectedSize] when they picked one.
  String tryOnFitNote({String selectedSize = ''}) {
    final summary = fitSummary;
    if (summary.isEmpty) return '';
    final size = selectedSize.trim();
    return [
      'The person is $summary.',
      if (size.isNotEmpty)
        'They chose size $size. Show how size $size would really fit '
            'someone of this size, tighter or looser as it would be in real '
            'life.'
      else
        'Show how the items would really fit someone of this size.',
      'Use this only for how the clothes fit; never change their body shape.',
    ].join(' ');
  }

  /// The label in [available] that matches the user's size, or null.
  String? sizeToSelect(Iterable<String> available, {required bool footwear}) {
    final wanted = _sizeKey(footwear ? shoeSize : clothingSize, footwear);
    if (wanted.isEmpty) return null;
    for (final label in available) {
      if (_sizeKey(label, footwear) == wanted) return label;
    }
    return null;
  }

  static String _sizeKey(String label, bool footwear) {
    final key = label.trim().toUpperCase();
    return footwear ? key.replaceFirst(RegExp(r'^UK\s*'), '') : key;
  }

  static String _asString(Object? value) => (value ?? '').toString().trim();

  static double? _asDouble(Object? value) => switch (value) {
    num() => value.toDouble(),
    String() => double.tryParse(value.trim().replaceAll(',', '.')),
    _ => null,
  };
}
