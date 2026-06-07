// Fetches current weather data used to produce location-aware outfit suggestions.
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  static const String _apiKey = 'b09dedf4fc27439bb1c103122241504';
  static const String _baseUrl = 'https://api.weatherapi.com/v1';

  /// Fetches weather data for a given location (city name or lat,long)
  Future<Weather> fetchWeather(String location) async {
    final url = Uri.parse('$_baseUrl/current.json?key=$_apiKey&q=$location&aqi=no');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Weather.fromJson(data);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather: $e');
    }
  }

  /// Helper to get recommendations based on current weather
  Future<String> getRecommendation(String location) async {
    try {
      final weather = await fetchWeather(location);
      return weather.clothingRecommendation;
    } catch (e) {
      return "Unable to get weather-based recommendations at this time.";
    }
  }
}
