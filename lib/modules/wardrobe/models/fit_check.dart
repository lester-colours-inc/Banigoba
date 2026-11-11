// The virtual fitting room's fit check (review item K-2): compare a garment's
// measurements with the user's saved measurements and say, in plain words,
// where it will be tight, snug or loose, and which size to choose.
//
// Garment measurements are what the shop enters in the size chart: the full
// distance around the garment (chest, waist, hips), shoulder seam to seam and
// the inseam of trousers, all in cm. The result is an estimate; it always
// shows the numbers it used.
import 'package:flutter/foundation.dart';

import 'package:banigoba/modules/profile_details/models/body_profile.dart';

/// The body parts a shop can give a garment measurement for.
const List<BodyMeasurement> kChartParts = [
  BodyMeasurement.shoulders,
  BodyMeasurement.chest,
  BodyMeasurement.waist,
  BodyMeasurement.hips,
  BodyMeasurement.insideLeg,
];

/// The size key used for a measurement that applies to every size, e.g. the
/// older single "shoulder measurement" field.
const String kAllSizes = '*';

enum FitVerdict { tight, snug, good, loose, short, long }

/// How a garment measurement compares with the body, in cm.
FitVerdict verdictFor(
  BodyMeasurement part, {
  required double garment,
  required double body,
}) {
  final difference = garment - body;
  return switch (part) {
    BodyMeasurement.shoulders =>
      difference < -1
          ? FitVerdict.tight
          : difference <= 3
          ? FitVerdict.good
          : FitVerdict.loose,
    BodyMeasurement.insideLeg =>
      difference < -5
          ? FitVerdict.short
          : difference <= 3
          ? FitVerdict.good
          : FitVerdict.long,
    _ =>
      // Chest, waist, hips: garment size minus body size is the "ease".
      difference < 0
          ? FitVerdict.tight
          : difference < 4
          ? FitVerdict.snug
          : difference < 14
          ? FitVerdict.good
          : FitVerdict.loose,
  };
}

/// "across the chest", "around the waist", "in the leg".
String placeOf(BodyMeasurement part) => switch (part) {
  BodyMeasurement.shoulders => 'across the shoulders',
  BodyMeasurement.chest => 'across the chest',
  BodyMeasurement.waist => 'around the waist',
  BodyMeasurement.hips => 'around the hips',
  BodyMeasurement.insideLeg => 'in the leg',
  _ => 'overall',
};

String _adjective(FitVerdict verdict) => switch (verdict) {
  FitVerdict.tight => 'tight',
  FitVerdict.snug => 'snug',
  FitVerdict.good => 'a good fit',
  FitVerdict.loose => 'loose',
  FitVerdict.short => 'short',
  FitVerdict.long => 'long',
};

/// How much a verdict counts against a size when choosing one.
int _penalty(FitVerdict verdict) => switch (verdict) {
  FitVerdict.tight || FitVerdict.short => 3,
  FitVerdict.snug || FitVerdict.loose || FitVerdict.long => 1,
  FitVerdict.good => 0,
};

double? _asCm(Object? value) {
  if (value is num) return value.toDouble();
  if (value == null) return null;
  final match = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(value.toString());
  return match == null ? null : double.tryParse(match[0]!.replaceAll(',', '.'));
}

String _sizeKey(String size) => size.trim().toUpperCase();

/// A shop's per-size garment measurements.
@immutable
class SizeChart {
  const SizeChart(this.sizes);

  final Map<String, Map<BodyMeasurement, double>> sizes;

  static const SizeChart empty = SizeChart({});

  bool get isEmpty => sizes.values.every((measures) => measures.isEmpty);

  /// Reads `sizeChart` ({"M": {"chest": 100, ...}}) from a product, falling
  /// back to the older single shoulder measurement for all sizes.
  factory SizeChart.fromProduct(Map<String, dynamic> data) {
    final sizes = <String, Map<BodyMeasurement, double>>{};
    if (data['sizeChart'] case final Map raw) {
      raw.forEach((size, measures) {
        if (measures is! Map) return;
        final parsed = <BodyMeasurement, double>{};
        for (final part in kChartParts) {
          if (_asCm(measures[part.key]) case final cm? when cm > 0) {
            parsed[part] = cm;
          }
        }
        if (parsed.isNotEmpty) sizes[_sizeKey(size.toString())] = parsed;
      });
    }
    if (sizes.isEmpty) {
      final shoulders = _asCm(data['shoulderMeasurement']);
      if (shoulders != null && shoulders > 0) {
        sizes[kAllSizes] = {BodyMeasurement.shoulders: shoulders};
      }
    }
    return SizeChart(Map.unmodifiable(sizes));
  }

  /// What the shop's form saves: only sizes with at least one measurement.
  Map<String, Map<String, double>> toMap() => {
    for (final entry in sizes.entries)
      if (entry.value.isNotEmpty)
        entry.key: {
          for (final measure in entry.value.entries)
            measure.key.key: measure.value,
        },
  };
}

/// One compared body part.
@immutable
class FitPart {
  const FitPart({
    required this.part,
    required this.garmentCm,
    required this.bodyCm,
    required this.verdict,
  });

  final BodyMeasurement part;
  final double garmentCm;
  final double bodyCm;
  final FitVerdict verdict;

  /// "tight around the waist".
  String get phrase => '${_adjective(verdict)} ${placeOf(part)}';

  /// "Waist: garment 84 cm, you 88 cm".
  String get numbers =>
      '${part.label}: garment ${formatNumber(garmentCm)} cm, you ${formatNumber(bodyCm)} cm';
}

@immutable
class FitCheck {
  const FitCheck({
    required this.size,
    required this.parts,
    this.recommendedSize,
  });

  /// The size compared, or '' when the chart covers every size.
  final String size;
  final List<FitPart> parts;

  /// The size that fits best across the chart, or null when unknown.
  final String? recommendedSize;

  static const FitCheck none = FitCheck(size: '', parts: []);

  bool get hasResult => parts.isNotEmpty;

  /// The most important finding: problems first, then "should fit well".
  /// Parts with the same verdict share one adjective: "Tight around the waist
  /// and hips".
  String get headline {
    if (parts.isEmpty) return '';
    for (final group in const [
      [FitVerdict.tight, FitVerdict.short],
      [FitVerdict.loose, FitVerdict.long],
      [FitVerdict.snug],
    ]) {
      final found = parts.where((part) => group.contains(part.verdict));
      if (found.isEmpty) continue;
      final first = found.first.verdict;
      final sameVerdict = found.where((part) => part.verdict == first).take(2);
      final text =
          '${_adjective(first)} '
          '${sameVerdict.map((part) => placeOf(part.part)).join(' and ')}';
      return '${text[0].toUpperCase()}${text.substring(1)}';
    }
    return 'Should fit you well';
  }

  /// True when nothing is tight or short.
  bool get isComfortable => parts.every(
    (part) =>
        part.verdict != FitVerdict.tight && part.verdict != FitVerdict.short,
  );

  /// For the try-on image model: how this garment really fits this person.
  String get tryOnNote => parts.isEmpty
      ? ''
      : 'Fit check for ${size.isEmpty ? 'this item' : 'size $size'}: '
            '${parts.map((part) => part.phrase).join(', ')}. Show exactly '
            'that fit; do not change their body shape.';

  /// Compares [chart] with [body] for [selectedSize]. Without a selected size
  /// it uses the user's usual size when the chart has it.
  factory FitCheck.of(
    SizeChart chart,
    BodyProfile body, {
    String selectedSize = '',
  }) {
    if (chart.isEmpty) return FitCheck.none;
    final chosen = _sizeKey(selectedSize);
    final usual = _sizeKey(body.clothingSize);
    final key = chart.sizes.containsKey(chosen)
        ? chosen
        : chart.sizes.containsKey(kAllSizes)
        ? kAllSizes
        : chart.sizes.containsKey(usual)
        ? usual
        : null;
    final recommended = recommendSize(chart, body);
    if (key == null) {
      return FitCheck(size: '', parts: const [], recommendedSize: recommended);
    }
    final garment = chart.sizes[key]!;
    final parts = <FitPart>[
      for (final part in kChartParts)
        if (garment[part] case final garmentCm?)
          if (body[part] case final bodyCm?)
            FitPart(
              part: part,
              garmentCm: garmentCm,
              bodyCm: bodyCm,
              verdict: verdictFor(part, garment: garmentCm, body: bodyCm),
            ),
    ];
    return FitCheck(
      size: key == kAllSizes ? '' : key,
      parts: List.unmodifiable(parts),
      recommendedSize: recommended,
    );
  }
}

/// The chart size with the least discomfort for [body], preferring the
/// user's usual size and then the larger size on a tie. Null when no size
/// can be compared.
String? recommendSize(SizeChart chart, BodyProfile body) {
  final usual = _sizeKey(body.clothingSize);
  String? best;
  var bestScore = 1 << 30;
  var comparable = false;
  for (final entry in chart.sizes.entries) {
    if (entry.key == kAllSizes) continue;
    var score = 0;
    var count = 0;
    for (final measure in entry.value.entries) {
      if (body[measure.key] case final bodyCm?) {
        score += _penalty(
          verdictFor(measure.key, garment: measure.value, body: bodyCm),
        );
        count += 1;
      }
    }
    if (count == 0) continue;
    comparable = true;
    final better =
        score < bestScore ||
        (score == bestScore && best != usual && entry.key == usual);
    if (better) {
      best = entry.key;
      bestScore = score;
    }
  }
  return comparable ? best : null;
}

const List<String> _letterSizes = [
  'XXS',
  'XS',
  'S',
  'M',
  'L',
  'XL',
  'XXL',
  'XXXL',
];

/// With no measurements to compare, how the chosen size label relates to the
/// size the user usually wears ("a size up"), or null if unknown or equal.
String? sizeLabelAdvice(String selectedSize, String usualSize) {
  final chosen = _letterSizes.indexOf(_sizeKey(selectedSize));
  final usual = _letterSizes.indexOf(_sizeKey(usualSize));
  if (chosen < 0 || usual < 0 || chosen == usual) return null;
  final steps = (chosen - usual).abs();
  final amount = steps == 1 ? 'a size' : '$steps sizes';
  return chosen > usual
      ? 'About $amount bigger than you usually wear (${_sizeKey(usualSize)}), so expect it roomier.'
      : 'About $amount smaller than you usually wear (${_sizeKey(usualSize)}), so expect it tighter.';
}
