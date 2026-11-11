// Verifies the fitting room's fit check (K-2).
import 'package:banigoba/modules/profile_details/models/body_profile.dart';
import 'package:banigoba/modules/wardrobe/models/fit_check.dart';
import 'package:flutter_test/flutter_test.dart';

const _body = BodyProfile(
  clothingSize: 'M',
  measurements: {
    BodyMeasurement.shoulders: 44,
    BodyMeasurement.chest: 96,
    BodyMeasurement.waist: 88,
    BodyMeasurement.hips: 100,
    BodyMeasurement.insideLeg: 78,
  },
);

SizeChart _chart(Map<String, Map<String, num>> sizeChart) =>
    SizeChart.fromProduct({'sizeChart': sizeChart});

void main() {
  group('verdictFor', () {
    test('circumferences: tight below the body, then snug, good, loose', () {
      FitVerdict v(double garment) =>
          verdictFor(BodyMeasurement.waist, garment: garment, body: 88);
      expect(v(84), FitVerdict.tight);
      expect(v(90), FitVerdict.snug);
      expect(v(98), FitVerdict.good);
      expect(v(110), FitVerdict.loose);
    });

    test('shoulders and leg length use their own tolerances', () {
      expect(
        verdictFor(BodyMeasurement.shoulders, garment: 42, body: 44),
        FitVerdict.tight,
      );
      expect(
        verdictFor(BodyMeasurement.shoulders, garment: 45, body: 44),
        FitVerdict.good,
      );
      expect(
        verdictFor(BodyMeasurement.shoulders, garment: 52, body: 44),
        FitVerdict.loose,
      );
      expect(
        verdictFor(BodyMeasurement.insideLeg, garment: 70, body: 78),
        FitVerdict.short,
      );
      expect(
        verdictFor(BodyMeasurement.insideLeg, garment: 80, body: 78),
        FitVerdict.good,
      );
      expect(
        verdictFor(BodyMeasurement.insideLeg, garment: 90, body: 78),
        FitVerdict.long,
      );
    });
  });

  group('FitCheck', () {
    final chart = _chart({
      'S': {'chest': 90, 'waist': 80, 'hips': 94},
      'M': {'chest': 104, 'waist': 86, 'hips': 108},
      'L': {'chest': 112, 'waist': 98, 'hips': 116},
    });

    test('says where it is tight, in words', () {
      final check = FitCheck.of(chart, _body, selectedSize: 'M');
      expect(check.size, 'M');
      expect(check.headline, 'Tight around the waist');
      expect(check.isComfortable, isFalse);
      expect(
        check.parts.first.numbers,
        startsWith('Chest / bust: garment 104 cm, you 96 cm'),
      );
    });

    test('a roomy size reports it loosely', () {
      final check = FitCheck.of(
        _chart({
          'L': {'chest': 120, 'waist': 108, 'hips': 118},
        }),
        _body,
        selectedSize: 'L',
      );
      expect(check.headline, 'Loose across the chest and around the waist');
      expect(check.isComfortable, isTrue);
    });

    test('everything comfortable reads "Should fit you well"', () {
      final check = FitCheck.of(
        _chart({
          'M': {'chest': 106, 'waist': 96, 'hips': 110},
        }),
        _body,
        selectedSize: 'M',
      );
      expect(check.headline, 'Should fit you well');
    });

    test('recommends the size with the least discomfort', () {
      expect(recommendSize(chart, _body), 'L');
    });

    test('a tie goes to the usual size', () {
      final tie = _chart({
        'M': {'waist': 98},
        'L': {'waist': 98},
      });
      expect(recommendSize(tie, _body), 'M');
    });

    test('without a selected size it uses the usual size', () {
      expect(FitCheck.of(chart, _body).size, 'M');
    });

    test('nothing to compare without saved measurements', () {
      final check = FitCheck.of(chart, const BodyProfile(), selectedSize: 'M');
      expect(check.hasResult, isFalse);
      expect(check.recommendedSize, isNull);
    });

    test('an empty chart gives no result', () {
      expect(FitCheck.of(SizeChart.empty, _body).hasResult, isFalse);
    });

    test('the try-on note carries the same findings', () {
      final note = FitCheck.of(chart, _body, selectedSize: 'M').tryOnNote;
      expect(note, contains('size M'));
      expect(note, contains('tight around the waist'));
    });
  });

  group('SizeChart', () {
    test('reads numbers and "45 cm" text, ignores bad values', () {
      final chart = SizeChart.fromProduct({
        'sizeChart': {
          'm': {'chest': '104 cm', 'waist': 'x', 'hips': 0},
        },
      });
      expect(chart.sizes['M'], {BodyMeasurement.chest: 104.0});
    });

    test('falls back to the older single shoulder measurement', () {
      final chart = SizeChart.fromProduct({'shoulderMeasurement': '45'});
      expect(chart.sizes[kAllSizes], {BodyMeasurement.shoulders: 45.0});
      final check = FitCheck.of(chart, _body, selectedSize: 'XL');
      expect(check.parts.single.verdict, FitVerdict.good);
    });

    test('saves only sizes that have measurements', () {
      final chart = SizeChart({
        'S': {BodyMeasurement.waist: 80},
        'M': const {},
      });
      expect(chart.toMap(), {
        'S': {'waist': 80.0},
      });
    });
  });

  group('sizeLabelAdvice', () {
    test('compares the size label with the usual size', () {
      expect(sizeLabelAdvice('L', 'M'), contains('bigger'));
      expect(sizeLabelAdvice('XS', 'M'), contains('2 sizes smaller'));
      expect(sizeLabelAdvice('M', 'M'), isNull);
      expect(sizeLabelAdvice('42', 'M'), isNull);
    });
  });
}
