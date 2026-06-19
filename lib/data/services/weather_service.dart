// Fetches current weather data used to produce location-aware outfit suggestions.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather.dart';

class WeatherFetchException implements Exception {
  WeatherFetchException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => statusCode == null
      ? 'WeatherFetchException: $message'
      : 'WeatherFetchException: $message ($statusCode)';
}

class WeatherService {
  static const String _apiKey = 'b09dedf4fc27439bb1c103122241504';
  static const String _baseUrl = 'https://api.weatherapi.com/v1';
  static const Duration _requestTimeout = Duration(seconds: 8);

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Fetches weather data for a given location (city name or lat,long)
  Future<Weather> fetchWeather(String location) async {
    final url = Uri.parse(
      '$_baseUrl/current.json',
    ).replace(queryParameters: {'key': _apiKey, 'q': location, 'aqi': 'no'});

    try {
      final response = await _client.get(url).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Weather.fromJson(data);
      }

      throw WeatherFetchException(
        'Failed to load weather data',
        statusCode: response.statusCode,
      );
    } on WeatherFetchException {
      rethrow;
    } on TimeoutException catch (e) {
      throw WeatherFetchException('Weather request timed out: $e');
    } catch (e) {
      throw WeatherFetchException('Error fetching weather: $e');
    }
  }

  /// Weather is a nice-to-have signal; callers can use this to fall back quietly.
  Future<Weather?> fetchOptionalWeather(String location) async {
    try {
      return await fetchWeather(location);
    } catch (_) {
      return null;
    }
  }

  /// Helper to get recommendations based on current weather
  Future<String> getRecommendation(String location) async {
    final weather = await fetchOptionalWeather(location);
    return weather?.clothingRecommendation ??
        "Unable to get weather-based recommendations at this time.";
  }
}
