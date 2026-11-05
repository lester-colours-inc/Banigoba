// Looks at a photo of a piece of clothing and suggests its tags (type, colour,
// style, weather, and so on) using Gemini's image understanding.
//
// Only the photo and a fixed question are sent, and the answer is cut down to
// the app's own vocabulary (see models/garment_tags.dart). It is a suggestion:
// the person can change anything, and every failure just means no suggestion.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/garment_tags.dart';

/// What the screens need; the real one asks Gemini, tests use a fake.
abstract interface class GarmentTagger {
  bool get isConfigured;

  /// Suggested tags for the photo, or null when none could be made.
  Future<GarmentTags?> tag(Uint8List photo, {String mimeType});
}

class GeminiGarmentTagger implements GarmentTagger {
  GeminiGarmentTagger({String? apiKey, http.Client? client, String? model})
    : _apiKey = apiKey ?? _compiledKey,
      _client = client ?? http.Client(),
      _model = model ?? defaultModel;

  static const String _compiledKey = String.fromEnvironment('GEMINI_API_KEY');

  /// A fast, cheap vision model: one small question per photo.
  static const String defaultModel = 'gemini-flash-latest';

  static const Duration _timeout = Duration(seconds: 25);
  static const int _maxBytes = 6 * 1024 * 1024;

  final String _apiKey;
  final http.Client _client;
  final String _model;

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  static String _list(Iterable<String> values) => values.join(', ');

  /// The fixed question. It names every allowed value, so the answer needs no
  /// interpreting, and it asks about the garment only, never a person.
  static String get prompt =>
      'This is a photo of one piece of clothing, footwear or an accessory. '
      'Describe only the item, never a person. Answer in JSON with: '
      'name (2 to 4 words, e.g. "Navy linen shirt"); '
      'category, one of: ${_list(kGarmentCategories.keys)}; '
      'subcategory, one of the following for that category, or empty: '
      '${kGarmentCategories.entries.where((e) => e.value.isNotEmpty).map((e) => '${e.key}: ${_list(e.value)}').join('; ')}; '
      'styleTag, one of: ${_list(kGarmentStyles)}; '
      'gender, one of: ${_list(kGarmentGenders)}; '
      'colours, up to $kMaxTaggedColours of: ${_list(kGarmentColours)}; '
      'weatherTags, the weather it suits, from: ${_list(kGarmentWeather)}; '
      'functionalTags, only if clearly true, from: ${_list(kGarmentFunctions)}. '
      'Use only those exact words.';

  static Map<String, Object?> get _schema => {
    'type': 'OBJECT',
    'properties': {
      'name': {'type': 'STRING'},
      'category': {'type': 'STRING'},
      'subcategory': {'type': 'STRING'},
      'styleTag': {'type': 'STRING'},
      'gender': {'type': 'STRING'},
      'colours': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
      'weatherTags': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
      'functionalTags': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
    },
  };

  @override
  Future<GarmentTags?> tag(
    Uint8List photo, {
    String mimeType = 'image/jpeg',
  }) async {
    if (!isConfigured || photo.isEmpty || photo.length > _maxBytes) return null;
    try {
      final response = await _client
          .post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/'
              '$_model:generateContent',
            ),
            headers: {
              'x-goog-api-key': _apiKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                    {
                      'inline_data': {
                        'mime_type': mimeType,
                        'data': base64Encode(photo),
                      },
                    },
                  ],
                },
              ],
              'generationConfig': {
                'responseMimeType': 'application/json',
                'responseSchema': _schema,
                'temperature': 0.2,
              },
            }),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        debugPrint('[GarmentTagger] HTTP ${response.statusCode}');
        return null;
      }
      return parseResponse(response.body);
    } on TimeoutException {
      return null;
    } on Exception catch (error) {
      debugPrint('[GarmentTagger] failed: $error');
      return null;
    }
  }

  /// Reads Gemini's reply body into tags, or null when it holds nothing usable.
  @visibleForTesting
  static GarmentTags? parseResponse(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final candidates = decoded['candidates'];
      if (candidates is! List || candidates.isEmpty) return null;
      final parts = (candidates.first as Map)['content']?['parts'];
      if (parts is! List || parts.isEmpty) return null;
      final text = (parts.first as Map)['text']?.toString() ?? '';
      final json = jsonDecode(text);
      if (json is! Map<String, dynamic>) return null;
      final tags = GarmentTags.fromJson(json);
      return tags.isEmpty ? null : tags;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
