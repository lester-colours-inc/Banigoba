// Tests the WeatherService without making real HTTP requests.
//
// MockClient lets each test control the provider response so error handling,
// optional fallback behavior, and response parsing remain deterministic.
import 'package:banigoba/modules/home/services/weather_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('WeatherService', () {
    test('throws a typed exception for failed weather responses', () async {
      final service = WeatherService(
        client: MockClient((_) async => http.Response('Unavailable', 503)),
      );

      expect(
        () => service.fetchWeather('51.5,-0.12'),
        throwsA(
          isA<WeatherFetchException>().having(
            (error) => error.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
    });

    test(
      'returns null from optional weather when provider is unavailable',
      () async {
        final service = WeatherService(
          client: MockClient((_) async => http.Response('Unavailable', 503)),
        );

        final weather = await service.fetchOptionalWeather('51.5,-0.12');

        expect(weather, isNull);
      },
    );

    test(
      'encodes the location query and parses successful responses',
      () async {
        Uri? requestedUrl;
        final service = WeatherService(
          client: MockClient((request) async {
            requestedUrl = request.url;
            return http.Response('''
{
  "location": {"name": "London"},
  "current": {
    "temp_c": 18.0,
    "condition": {
      "text": "Partly cloudy",
      "icon": "//cdn.weatherapi.com/weather/64x64/day/116.png"
    }
  }
}
''', 200);
          }),
        );

        final weather = await service.fetchWeather('51.5,-0.12');

        expect(requestedUrl?.queryParameters['q'], '51.5,-0.12');
        expect(weather.locationName, 'London');
        expect(weather.temperatureC, 18);
      },
    );

    test('throws a typed exception for invalid weather JSON values', () async {
      final service = WeatherService(
        client: MockClient((_) async => http.Response('not-json', 200)),
      );

      expect(
        () => service.fetchWeather('London'),
        throwsA(isA<WeatherFetchException>()),
      );
    });

    test('returns a recommendation for valid weather values', () async {
      final service = WeatherService(
        client: MockClient(
          (_) async => http.Response('''
{
  "location": {"name": "Harare"},
  "current": {
    "temp_c": 28.0,
    "condition": {
      "text": "Sunny",
      "icon": "//cdn.weatherapi.com/weather/64x64/day/113.png"
    }
  }
}
''', 200),
        ),
      );

      final recommendation = await service.getRecommendation('Harare');

      expect(recommendation, isNot(contains('Unable to get')));
    });

    test(
      'returns a fallback recommendation for invalid weather values',
      () async {
        final service = WeatherService(
          client: MockClient((_) async => http.Response('Unavailable', 503)),
        );

        final recommendation = await service.getRecommendation('Harare');

        expect(
          recommendation,
          'Unable to get weather-based recommendations at this time.',
        );
      },
    );
  });
}
