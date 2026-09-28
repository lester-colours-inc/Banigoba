import 'package:banigoba/data/models/body_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BodyMeasurement', () {
    test('accepts a blank value, since every detail is optional', () {
      expect(BodyMeasurement.height.validate(''), isNull);
      expect(BodyMeasurement.height.parse('  '), isNull);
    });

    test('parses numbers with a comma or a point', () {
      expect(BodyMeasurement.waist.parse('80,5'), 80.5);
      expect(BodyMeasurement.waist.parse(' 81 '), 81);
    });

    test('rejects text and values outside a human range', () {
      expect(BodyMeasurement.height.validate('tall'), 'Enter a number');
      expect(BodyMeasurement.height.validate('17'), 'Between 50 and 250 cm');
      expect(BodyMeasurement.weight.validate('900'), 'Between 20 and 300 kg');
      expect(BodyMeasurement.height.parse('17'), isNull);
    });
  });

  group('shoe size', () {
    test('accepts UK sizes with or without "UK" and halves', () {
      expect(BodyProfile.validateShoeSize(''), isNull);
      expect(BodyProfile.validateShoeSize('8'), isNull);
      expect(BodyProfile.validateShoeSize('uk 8,5'), isNull);
      expect(BodyProfile.normalizeShoeSize('uk 8,5'), '8.5');
    });

    test('rejects text and EU-range numbers', () {
      expect(BodyProfile.validateShoeSize('big'), 'Enter a UK size, e.g. 8');
      expect(BodyProfile.validateShoeSize('42'), 'Enter a UK size, e.g. 8');
    });
  });

  group('BodyProfile map', () {
    test('round-trips through Firestore data', () {
      const profile = BodyProfile(
        facePhotoUrl: 'https://example.com/face.jpg',
        fullBodyPhotoUrl: 'https://example.com/body.jpg',
        clothingSize: 'M',
        shoeSize: '8',
        measurements: {BodyMeasurement.height: 172, BodyMeasurement.waist: 80},
        notes: 'Long arms',
      );

      final restored = BodyProfile.fromMap(profile.toMap());

      expect(restored.facePhotoUrl, profile.facePhotoUrl);
      expect(restored.fullBodyPhotoUrl, profile.fullBodyPhotoUrl);
      expect(restored.clothingSize, 'M');
      expect(restored.shoeSize, '8');
      expect(restored[BodyMeasurement.height], 172);
      expect(restored[BodyMeasurement.waist], 80);
      expect(restored.notes, 'Long arms');
    });

    test('tolerates missing, malformed and out-of-range fields', () {
      final profile = BodyProfile.fromMap({
        'clothingSize': 42,
        'measurements': {'height': 'abc', 'waist': '79', 'weight': 5000},
      });

      expect(profile.clothingSize, '42');
      expect(profile[BodyMeasurement.height], isNull);
      expect(profile[BodyMeasurement.waist], 79);
      expect(profile[BodyMeasurement.weight], isNull);
      expect(BodyProfile.fromMap(null).isEmpty, isTrue);
    });
  });

  group('detailsAdded', () {
    test('counts the nine requested details, not the extras', () {
      const profile = BodyProfile(
        facePhotoUrl: 'https://example.com/face.jpg',
        clothingSize: 'L',
        measurements: {
          BodyMeasurement.height: 180,
          BodyMeasurement.hips: 100, // extra, not counted
        },
        notes: 'Prefers a loose fit', // extra, not counted
      );

      expect(profile.detailsAdded, 3);
      expect(BodyProfile.requestedDetailCount, 9);
    });
  });

  group('fitSummary', () {
    test('describes size and build in plain words', () {
      const profile = BodyProfile(
        clothingSize: 'M',
        shoeSize: '8',
        measurements: {
          BodyMeasurement.height: 172,
          BodyMeasurement.weight: 68.5,
          BodyMeasurement.waist: 80,
        },
        notes: 'Long arms',
      );

      expect(
        profile.fitSummary,
        '172 cm tall, 68.5 kg, usually wears clothing size M, UK shoe size '
        '8, waist 80 cm; they also noted: "Long arms"',
      );
    });

    test('is empty when nothing about size is known', () {
      const photosOnly = BodyProfile(
        facePhotoUrl: 'https://example.com/face.jpg',
      );
      expect(photosOnly.fitSummary, isEmpty);
    });
  });

  group('sizeToSelect', () {
    const profile = BodyProfile(clothingSize: 'm', shoeSize: '8');

    test('picks the profile clothing size when it is in stock', () {
      expect(profile.sizeToSelect(['S', 'M', 'L'], footwear: false), 'M');
    });

    test('matches shoe sizes written with or without "UK"', () {
      expect(profile.sizeToSelect(['UK 7', 'UK 8'], footwear: true), 'UK 8');
      expect(profile.sizeToSelect(['7', '8'], footwear: true), '8');
    });

    test('returns null when the size is not available', () {
      expect(profile.sizeToSelect(['S', 'L'], footwear: false), isNull);
      expect(const BodyProfile().sizeToSelect(['M'], footwear: false), isNull);
    });
  });

  group('tryOnFitNote', () {
    test('asks for a realistic fit of the chosen size', () {
      const profile = BodyProfile(
        clothingSize: 'M',
        measurements: {BodyMeasurement.height: 172},
      );

      final note = profile.tryOnFitNote(selectedSize: 'L');

      expect(note, contains('172 cm tall'));
      expect(note, contains('size L'));
      expect(note, contains('never change their body shape'));
    });

    test('is empty with no profile and no chosen size', () {
      expect(const BodyProfile().tryOnFitNote(), isEmpty);
    });
  });
}
