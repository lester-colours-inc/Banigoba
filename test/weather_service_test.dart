import 'package:banigoba/data/services/weather_service.dart';
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
  });
}
