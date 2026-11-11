// Looks at a photo of a piece of clothing and suggests its tags (type, colour,
// style, weather, and so on) using Gemini's image understanding.
//
// Only the photo and a fixed question are sent, through our `tag-garment`
// Edge Function (the Gemini key stays on the server), and the answer is cut
// down to the app's own vocabulary (see models/garment_tags.dart). It is a
// suggestion: the person can change anything, and every failure just means no
// suggestion.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/modules/wardrobe/models/garment_tags.dart';

/// What the screens need; the real one asks the server, tests use a fake.
abstract interface class GarmentTagger {
  bool get isConfigured;

  /// Suggested tags for the photo, or null when none could be made.
  Future<GarmentTags?> tag(Uint8List photo, {String mimeType});
}

/// Calls the `tag-garment` function with a request body; returns its reply.
typedef TagFunction = Future<Object?> Function(Map<String, Object?> body);

class ServerGarmentTagger implements GarmentTagger {
  ServerGarmentTagger({TagFunction? call}) : _call = call ?? _invoke;

  static Future<Object?> _invoke(Map<String, Object?> body) async =>
      (await supabase.functions.invoke('tag-garment', body: body)).data;

  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxBytes = 6 * 1024 * 1024;

  final TagFunction _call;

  @override
  bool get isConfigured => true;

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
    if (photo.isEmpty || photo.length > _maxBytes) return null;
    try {
      final reply = await _call({
        'image': base64Encode(photo),
        'mimeType': mimeType,
        'prompt': prompt,
        'schema': _schema,
      }).timeout(_timeout);
      return parseReply(reply);
    } on TimeoutException {
      return null;
    } on Exception catch (error) {
      debugPrint('[GarmentTagger] failed: $error');
      return null;
    }
  }

  /// Reads the function's reply (`{tags: {...}}`) into tags, or null when it
  /// holds nothing usable.
  @visibleForTesting
  static GarmentTags? parseReply(Object? reply) {
    final decoded = reply is String ? _decode(reply) : reply;
    if (decoded is! Map) return null;
    final json = decoded['tags'];
    if (json is! Map) return null;
    try {
      final tags = GarmentTags.fromJson(Map<String, dynamic>.from(json));
      return tags.isEmpty ? null : tags;
    } on TypeError {
      return null;
    }
  }

  static Object? _decode(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }
}
