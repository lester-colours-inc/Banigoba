// What the app can say about a piece of clothing from its photo (the
// "AI auto-tag" for the Smart Wardrobe and quick add).
//
// The model only ever picks from the app's own vocabulary below. Anything it
// invents is dropped, so a stray word can never reach a product or filter.
import 'package:flutter/foundation.dart';

/// Category → the subcategories the app offers for it.
const Map<String, List<String>> kGarmentCategories = {
  'accessories': ['caps', 'glasses', 'hats'],
  'bottoms': ['jeans', 'joggers', 'leggings', 'shorts', 'skirts'],
  'dresses': <String>[],
  'outerwear': ['blazers', 'jackets'],
  'shoes': ['boots', 'flats', 'heels', 'sandals', 'sneakers'],
  'tops': [
    'hoodies',
    'polo shirts',
    'shirts',
    'sweatshirts',
    't-shirts',
    'tank tops',
  ],
  'other': <String>[],
};

const List<String> kGarmentColours = [
  'black',
  'white',
  'grey',
  'blue',
  'red',
  'green',
  'yellow',
  'orange',
  'pink',
  'purple',
  'brown',
  'beige',
];

const List<String> kGarmentStyles = [
  'casual',
  'afrochic',
  'corporate',
  'streetwear',
  'glamour',
];

const List<String> kGarmentWeather = ['hot', 'mild', 'cool', 'cold', 'rainy'];

const List<String> kGarmentFunctions = [
  'waterproof',
  'breathable',
  'insulated',
  'windproof',
];

const List<String> kGarmentGenders = ['male', 'female', 'unisex'];

/// How many colours a piece is tagged with at most.
const int kMaxTaggedColours = 3;

@immutable
class GarmentTags {
  const GarmentTags({
    this.name = '',
    this.category,
    this.subcategory,
    this.styleTag,
    this.gender,
    this.colours = const [],
    this.weatherTags = const [],
    this.functionalTags = const [],
  });

  /// A short name for the piece, e.g. "Navy linen shirt".
  final String name;
  final String? category;
  final String? subcategory;
  final String? styleTag;
  final String? gender;
  final List<String> colours;
  final List<String> weatherTags;
  final List<String> functionalTags;

  bool get isEmpty =>
      name.isEmpty &&
      category == null &&
      subcategory == null &&
      styleTag == null &&
      gender == null &&
      colours.isEmpty &&
      weatherTags.isEmpty &&
      functionalTags.isEmpty;

  /// Reads the model's answer, keeping only values the app knows.
  factory GarmentTags.fromJson(Map<String, dynamic> json) {
    String? pick(Object? value, Iterable<String> allowed) {
      final text = value?.toString().trim().toLowerCase() ?? '';
      return allowed.contains(text) ? text : null;
    }

    List<String> pickAll(Object? value, Iterable<String> allowed, [int? max]) {
      if (value is! Iterable) return const [];
      final seen = <String>[];
      for (final item in value) {
        final text = pick(item, allowed);
        if (text != null && !seen.contains(text)) seen.add(text);
        if (max != null && seen.length >= max) break;
      }
      return List.unmodifiable(seen);
    }

    final category = pick(json['category'], kGarmentCategories.keys);
    final subcategory = category == null
        ? null
        : pick(json['subcategory'], kGarmentCategories[category]!);
    final rawName = json['name']?.toString().trim() ?? '';
    return GarmentTags(
      name: rawName.length > 40 ? rawName.substring(0, 40).trim() : rawName,
      category: category,
      subcategory: subcategory,
      styleTag: pick(json['styleTag'], kGarmentStyles),
      gender: pick(json['gender'], kGarmentGenders),
      colours: pickAll(json['colours'], kGarmentColours, kMaxTaggedColours),
      weatherTags: pickAll(json['weatherTags'], kGarmentWeather),
      functionalTags: pickAll(json['functionalTags'], kGarmentFunctions),
    );
  }
}
