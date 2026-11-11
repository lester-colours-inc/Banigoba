// Converts weather API responses into values and clothing recommendations used by the UI.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather.freezed.dart';

@freezed
abstract class Weather with _$Weather {
  const Weather._();

  const factory Weather({
    required double temperatureC,
    required String condition,
    required String iconUrl,
    required String locationName,
  }) = _Weather;

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperatureC: json['current']['temp_c'].toDouble(),
      condition: json['current']['condition']['text'],
      iconUrl: 'https:${json['current']['condition']['icon']}',
      locationName: json['location']['name'],
    );
  }

  /// Returns recommendation based on temperature
  String get clothingRecommendation {
    if (temperatureC < 10) {
      return "It's cold! Wear a heavy coat, scarf, and gloves.";
    } else if (temperatureC < 20) {
      return "It's a bit chilly. A light jacket or sweater would be good.";
    } else if (temperatureC < 30) {
      return "The weather is pleasant. A t-shirt or a light shirt is fine.";
    } else {
      return "It's hot! Wear breathable, light clothing.";
    }
  }

  /// Maps current weather to product tags for filtering
  List<String> get weatherTags {
    List<String> tags = [];
    if (temperatureC < 10) {
      tags.add('cold');
    } else if (temperatureC < 20) {
      tags.add('cool');
    } else if (temperatureC < 25) {
      tags.add('mild');
    } else {
      tags.add('hot');
    }

    if (condition.toLowerCase().contains('rain') ||
        condition.toLowerCase().contains('drizzle')) {
      tags.add('rainy');
    }
    return tags;
  }
}
