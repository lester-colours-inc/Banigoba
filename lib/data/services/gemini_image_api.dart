// Client for Gemini image editing (Nano Banana) via the Interactions API.
//
// Gemini is a general image editor: it takes the avatar plus every garment
// in a single call and returns raw image bytes rather than a hosted URL, so
// callers have to upload the result themselves.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// An image handed to Gemini as part of an edit request.
@immutable
class GeminiImage {
  const GeminiImage({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

/// A single image returned by Gemini.
@immutable
class GeminiImageResult {
  const GeminiImageResult({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

class GeminiApiException implements Exception {
  const GeminiApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'GeminiApiException($message)';
}

class GeminiImageApi {
  GeminiImageApi({
    required this.apiKey,
    this.model = defaultModel,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final http.Client _client;

  /// The versatile Nano Banana workhorse. `gemini-3-pro-image` trades cost for
  /// quality on harder composites; `gemini-3.1-flash-lite-image` is cheapest.
  static const String defaultModel = 'gemini-3.1-flash-image';

  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/interactions';

  /// Pins the response schema so a future breaking change cannot reshape
  /// `steps` underneath us.
  static const String _apiRevision = '2026-05-20';
  static const Duration _timeout = Duration(minutes: 2);
  static const int _maxImageBytes = 10 * 1024 * 1024;

  Map<String, String> get _headers => {
    'x-goog-api-key': apiKey,
    HttpHeaders.contentTypeHeader: 'application/json',
    'Api-Revision': _apiRevision,
  };

  /// Downloads an image so it can be inlined into a request.
  ///
  /// Gemini takes base64 image data rather than URLs, so every avatar and
  /// garment has to be fetched client-side first.
  static Future<GeminiImage> fetchImage(
    String imageUrl, {
    http.Client? client,
  }) async {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null || !uri.hasScheme) {
      throw GeminiApiException('Not a valid image URL: $imageUrl');
    }

    final response = await (client ?? http.Client()).get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw GeminiApiException(
        'Could not download image (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    if (response.bodyBytes.length > _maxImageBytes) {
      throw GeminiApiException(
        'Image is too large to send to Gemini '
        '(${response.bodyBytes.length} bytes).',
      );
    }

    final contentType = response.headers[HttpHeaders.contentTypeHeader];
    return GeminiImage(
      bytes: response.bodyBytes,
      mimeType: _normalizeMimeType(contentType),
    );
  }

  static String _normalizeMimeType(String? contentType) {
    if (contentType == null || contentType.isEmpty) return 'image/jpeg';
    final mimeType = contentType.split(';').first.trim().toLowerCase();
    return mimeType.startsWith('image/') ? mimeType : 'image/jpeg';
  }

  /// Edits [images] according to [prompt] and returns the generated image.
  Future<GeminiImageResult> editImage({
    required List<GeminiImage> images,
    required String prompt,
    String outputMimeType = 'image/jpeg',
    String? aspectRatio,
  }) async {
    if (images.isEmpty) {
      throw const GeminiApiException('At least one input image is required.');
    }

    final input = <Map<String, dynamic>>[
      for (final image in images)
        {
          'type': 'image',
          'mime_type': image.mimeType,
          'data': base64Encode(image.bytes),
        },
      {'type': 'text', 'text': prompt},
    ];

    final response = await _client
        .post(
          Uri.parse(_endpoint),
          headers: _headers,
          body: jsonEncode({
            'model': model,
            'input': input,
            'response_format': {
              'type': 'image',
              'mime_type': outputMimeType,
              'aspect_ratio': ?aspectRatio,
            },
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw GeminiApiException(
        'Gemini request failed: ${response.statusCode} '
        '${_errorMessage(response.body)}',
        statusCode: response.statusCode,
      );
    }

    return _firstImage(response.body);
  }

  String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        final error = decoded['error'] as Map;
        return (error['message'] ?? body).toString();
      }
    } on FormatException {
      // Fall through to the raw body.
    }
    return body;
  }

  /// Pulls the first image out of the interaction timeline.
  ///
  /// `output_image` is an SDK convenience only, so over REST the image has to
  /// be found by walking `steps[].content[]` for an `image` block.
  GeminiImageResult _firstImage(String body) {
    final Map<String, dynamic> decoded =
        jsonDecode(body) as Map<String, dynamic>;
    final steps = decoded['steps'];
    if (steps is! List) {
      throw const GeminiApiException('Gemini response had no steps.');
    }

    for (final step in steps.whereType<Map>()) {
      final content = step['content'];
      if (content is! List) continue;
      for (final block in content.whereType<Map>()) {
        if (block['type'] != 'image') continue;
        final data = block['data'];
        if (data is! String || data.isEmpty) continue;
        return GeminiImageResult(
          bytes: base64Decode(data),
          mimeType: _normalizeMimeType(block['mime_type']?.toString()),
        );
      }
    }

    throw GeminiApiException(
      'Gemini returned no image. ${_refusalText(steps) ?? ''}'.trim(),
    );
  }

  /// Surfaces the model's own words when it answers with text instead of an
  /// image — usually a content refusal, which is the useful thing to show.
  String? _refusalText(List<dynamic> steps) {
    for (final step in steps.whereType<Map>()) {
      final content = step['content'];
      if (content is! List) continue;
      for (final block in content.whereType<Map>()) {
        final text = block['text'];
        if (block['type'] == 'text' && text is String && text.isNotEmpty) {
          return text;
        }
      }
    }
    return null;
  }
}
