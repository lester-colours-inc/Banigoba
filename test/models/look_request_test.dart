import 'package:banigoba/data/models/look_request.dart';
import 'package:banigoba/data/models/style_preferences.dart';
import 'package:banigoba/data/style/style_catalogue.dart';
import 'package:flutter_test/flutter_test.dart';

const _photo = 'https://example.com/me.jpg';

LookRequest _request(LookSource source, {LookScope scope = LookScope.hair}) =>
    LookRequest(photoUrl: _photo, scope: scope, source: source);

void main() {
  group('LookScope', () {
    test('defaults from the saved makeover preference', () {
      expect(LookScope.fromFocus(MakeoverFocus.hair), LookScope.hair);
      expect(LookScope.fromFocus(MakeoverFocus.outfit), LookScope.outfit);
      expect(LookScope.fromFocus(MakeoverFocus.fullLook), LookScope.fullLook);
      expect(LookScope.fromFocus(null), LookScope.fullLook);
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

  group('LookRequest.isReady', () {
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
      expect(_request(const ArchetypeSource(null)).isReady, isFalse);
      expect(_request(const TrendSource(null)).isReady, isFalse);
      expect(_request(const WeatherSource()).isReady, isFalse);
      expect(_request(const DescribeSource('low haircut')).isReady, isTrue);
      expect(_request(const WeatherSource(temperatureC: 24)).isReady, isTrue);
    });
  });

  group('buildLookPrompt', () {
    test('quotes what the user described', () {
      final prompt = buildLookPrompt(
        _request(const DescribeSource('I want a low haircut')),
      );
      expect(prompt, contains('"I want a low haircut"'));
    });

    test('always protects identity', () {
      final prompt = buildLookPrompt(_request(const DescribeSource('x')));
      expect(prompt, contains('Preserve the face, skin tone, body shape'));
    });

    test('keeps the hair when the scope is clothing only', () {
      final prompt = buildLookPrompt(
        _request(const DescribeSource('linen shirt'), scope: LookScope.top),
      );
      expect(prompt, contains('the top half of the outfit only'));
      expect(prompt, contains('Do not change the hair.'));
    });

    test('does not tell the model to keep the hair when changing it', () {
      final prompt = buildLookPrompt(_request(const DescribeSource('braids')));
      expect(prompt, isNot(contains('Do not change the hair.')));
    });

    test('describes the archetype, trend and weather sources', () {
      final archetype = styleArchetypes.first;
      final trend = curatedTrends.first;

      expect(
        buildLookPrompt(_request(ArchetypeSource(archetype))),
        contains(archetype.promptHint),
      );
      expect(
        buildLookPrompt(_request(TrendSource(trend))),
        contains(trend.promptHint),
      );
      expect(
        buildLookPrompt(
          _request(const WeatherSource(temperatureC: 31.6, condition: 'Sunny')),
        ),
        contains('32°C, sunny'),
      );
    });

    test('never mentions a provider or product', () {
      final prompt = buildLookPrompt(_request(const DescribeSource('x')));
      expect(prompt.toLowerCase(), isNot(contains('gemini')));
      expect(prompt.toLowerCase(), isNot(contains('product')));
    });
  });

  group('captions', () {
    test('name the idea the look came from', () {
      expect(
        _request(ArchetypeSource(styleArchetypes.first)).caption,
        '${styleArchetypes.first.name} look',
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
