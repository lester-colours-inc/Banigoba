import 'package:banigoba/data/models/body_profile.dart';
import 'package:banigoba/data/models/look_request.dart';
import 'package:banigoba/data/models/style_preferences.dart';
import 'package:banigoba/data/style/style_catalogue.dart';
import 'package:flutter_test/flutter_test.dart';

const _photo = 'https://example.com/me.jpg';
const _twinLook = 'https://example.com/twin.jpg';

LookRequest _request(LookSource source, {LookScope scope = LookScope.hair}) =>
    LookRequest(photoUrl: _photo, scope: scope, source: source);

String _prompt(
  LookSource source, {
  LookPart part = LookPart.hair,
  String tweak = '',
}) => buildLookPrompt(_request(source), part: part, tweak: tweak);

void main() {
  group('LookScope', () {
    test('defaults from the saved makeover preference', () {
      expect(LookScope.fromFocus(MakeoverFocus.hair), LookScope.hair);
      expect(LookScope.fromFocus(MakeoverFocus.outfit), LookScope.outfit);
      expect(LookScope.fromFocus(MakeoverFocus.fullLook), LookScope.fullLook);
      expect(LookScope.fromFocus(null), LookScope.fullLook);
    });

    test('a full look runs hair, clothes, shoes, then accessories', () {
      expect(LookScope.fullLook.parts, [
        LookPart.hair,
        LookPart.outfit,
        LookPart.shoes,
        LookPart.accessories,
      ]);
    });

    test('single-item scopes run a single step', () {
      expect(LookScope.hair.parts, [LookPart.hair]);
      expect(LookScope.top.parts, [LookPart.top]);
      expect(LookScope.bottom.parts, [LookPart.bottom]);
    });

    test('hair-only never changes clothing, clothing scopes never hair', () {
      expect(LookScope.hair.changesClothing, isFalse);
      for (final scope in [LookScope.outfit, LookScope.top, LookScope.bottom]) {
        expect(scope.changesHair, isFalse, reason: scope.name);
      }
      expect(LookScope.fullLook.changesHair, isTrue);
      expect(LookScope.fullLook.changesClothing, isTrue);
    });
  });

  group('LookRequest', () {
    test('needs a photo', () {
      const request = LookRequest(
        photoUrl: '',
        scope: LookScope.hair,
        source: DescribeSource('low haircut'),
      );
      expect(request.isReady, isFalse);
    });

    test('needs a complete source', () {
      expect(_request(const DescribeSource('  ')).isReady, isFalse);
      expect(_request(const IdolSource()).isReady, isFalse);
      expect(_request(const IdolSource(idolName: '  ')).isReady, isFalse);
      expect(_request(const TwinSource()).isReady, isFalse);
      expect(_request(const TrendSource(null)).isReady, isFalse);
      expect(_request(const WeatherSource()).isReady, isFalse);
      expect(_request(const DescribeSource('low haircut')).isReady, isTrue);
      expect(_request(const IdolSource(idolName: 'Winky D')).isReady, isTrue);
      expect(
        _request(IdolSource(archetype: styleArchetypes.first)).isReady,
        isTrue,
      );
      expect(_request(const TwinSource(imageUrl: _twinLook)).isReady, isTrue);
      expect(_request(const WeatherSource(temperatureC: 24)).isReady, isTrue);
    });

    test('a hair trend only runs the hair step of a full look', () {
      final hairTrend = curatedTrends.firstWhere((trend) => trend.isHair);
      final request = _request(
        TrendSource(hairTrend),
        scope: LookScope.fullLook,
      );
      expect(request.parts, [LookPart.hair]);
    });

    test('a clothing trend leaves the hair out of a full look', () {
      final clothingTrend = curatedTrends.firstWhere((trend) => !trend.isHair);
      final request = _request(
        TrendSource(clothingTrend),
        scope: LookScope.fullLook,
      );
      expect(request.parts, isNot(contains(LookPart.hair)));
      expect(request.parts, contains(LookPart.outfit));
    });

    test('only a style twin sends a reference image', () {
      expect(const TwinSource(imageUrl: _twinLook).referenceImageUrls, [
        _twinLook,
      ]);
      expect(const TwinSource().referenceImageUrls, isEmpty);
      expect(const DescribeSource('x').referenceImageUrls, isEmpty);
    });
  });

  group('buildLookPrompt', () {
    test('quotes what the user described', () {
      expect(
        _prompt(const DescribeSource('I want a low haircut')),
        contains('"I want a low haircut"'),
      );
    });

    test('always protects identity', () {
      expect(
        _prompt(const DescribeSource('x')),
        contains('Preserve the face, skin tone, body shape'),
      );
    });

    test('changes only the part for this step', () {
      final prompt = _prompt(
        const DescribeSource('linen outfit'),
        part: LookPart.shoes,
      );
      expect(prompt, contains('Change only the shoes'));
      expect(prompt, contains('Do not change the hair.'));
    });

    test('does not tell the model to keep the hair when changing it', () {
      expect(
        _prompt(const DescribeSource('braids')),
        isNot(contains('Do not change the hair.')),
      );
    });

    test('includes the tweak the user asked for', () {
      expect(
        _prompt(const DescribeSource('braids'), tweak: 'make them shorter'),
        contains('"make them shorter"'),
      );
    });

    test('a style idol borrows their clothes style, never their likeness', () {
      final prompt = _prompt(
        const IdolSource(idolName: 'Winky D'),
        part: LookPart.outfit,
      );
      expect(prompt, contains('Winky D'));
      expect(prompt, contains('never their face or body'));
    });

    test('a style idol can be a vibe instead of a person', () {
      final archetype = styleArchetypes.first;
      expect(
        _prompt(IdolSource(archetype: archetype)),
        contains(archetype.promptHint),
      );
    });

    test('a style twin copies the part from the second image only', () {
      final prompt = _prompt(
        const TwinSource(imageUrl: _twinLook),
        part: LookPart.outfit,
      );
      expect(prompt, contains('The second image shows a look'));
      expect(prompt, contains('Copy the clothes from the second image'));
      expect(prompt, contains('Never copy the face'));
    });

    test('describes the trend and weather sources', () {
      final trend = curatedTrends.first;
      expect(_prompt(TrendSource(trend)), contains(trend.promptHint));
      expect(
        _prompt(const WeatherSource(temperatureC: 31.6, condition: 'Sunny')),
        contains('32°C, sunny'),
      );
    });

    group('with profile details', () {
      const face = 'https://example.com/face.jpg';
      const body = BodyProfile(
        facePhotoUrl: face,
        clothingSize: 'M',
        measurements: {BodyMeasurement.height: 172},
      );

      LookRequest withBody(LookSource source) => LookRequest(
        photoUrl: _photo,
        scope: LookScope.outfit,
        source: source,
        body: body,
      );

      test('a style twin sends the face photo after the look to copy', () {
        final request = withBody(const TwinSource(imageUrl: _twinLook));
        expect(request.referenceImageUrls, [_twinLook, face]);

        final prompt = buildLookPrompt(request, part: LookPart.outfit);
        expect(prompt, contains('The third image is a close-up'));
      });

      test('a style idol sends the face photo as the second image', () {
        final request = withBody(const IdolSource(idolName: 'Winky D'));
        expect(request.referenceImageUrls, [face]);

        final prompt = buildLookPrompt(request, part: LookPart.outfit);
        expect(prompt, contains('The first image is a photo of a person.'));
        expect(prompt, contains('The second image is a close-up'));
        expect(prompt, contains('exactly as it is in the first image'));
      });

      test('other sources never send the face photo', () {
        expect(withBody(const DescribeSource('x')).referenceImageUrls, isEmpty);
      });

      test('fits clothes to the real size, but not hair', () {
        final request = withBody(const DescribeSource('linen'));
        expect(
          buildLookPrompt(request, part: LookPart.outfit),
          contains('Fit the clothes to their real size: 172 cm tall'),
        );
        expect(
          buildLookPrompt(request, part: LookPart.hair),
          isNot(contains('Fit the clothes')),
        );
      });
    });

    test('never mentions a provider or product', () {
      final prompt = _prompt(const DescribeSource('x')).toLowerCase();
      expect(prompt, isNot(contains('gemini')));
      expect(prompt, isNot(contains('product')));
    });
  });

  group('captions', () {
    test('name the idea the look came from', () {
      expect(
        _request(IdolSource(archetype: styleArchetypes.first)).caption,
        '${styleArchetypes.first.name} look',
      );
      expect(
        _request(const IdolSource(idolName: ' Winky D ')).caption,
        'Inspired by Winky D',
      );
      expect(
        _request(const TwinSource(imageUrl: _twinLook)).caption,
        'My style twin look',
      );
      expect(_request(const DescribeSource('x')).caption, 'My new look');
    });
  });

  group('style catalogue', () {
    test('ids are unique', () {
      final archetypeIds = styleArchetypes.map((item) => item.id).toList();
      final trendIds = curatedTrends.map((item) => item.id).toList();
      expect(archetypeIds.toSet(), hasLength(archetypeIds.length));
      expect(trendIds.toSet(), hasLength(trendIds.length));
    });

    test('every scope has at least one fitting trend', () {
      for (final scope in LookScope.values) {
        expect(
          curatedTrends.where((trend) => trend.fitsScope(scope)),
          isNotEmpty,
          reason: scope.name,
        );
      }
    });

    test('hair trends are hidden when the hair is kept', () {
      final hairTrends = curatedTrends.where((trend) => trend.isHair);
      expect(hairTrends, isNotEmpty);
      for (final trend in hairTrends) {
        expect(trend.fitsScope(LookScope.outfit), isFalse);
      }
    });
  });
}
