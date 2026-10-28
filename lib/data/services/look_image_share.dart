// Downloads a look's picture so it can be shared as a file rather than a link.
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const _downloadTimeout = Duration(seconds: 15);
const _fallbackMimeType = 'image/jpeg';

/// A look's picture, downloaded so it can be handed to another app as a file.
class LookImage {
  const LookImage({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;

  String get fileName {
    final extension = switch (mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    return 'banigoba_look.$extension';
  }
}

/// Downloads the picture at [imageUrl], or null when it can't be fetched.
Future<LookImage?> downloadLookImage(
  String imageUrl, {
  http.Client? client,
}) async {
  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient
        .get(Uri.parse(imageUrl))
        .timeout(_downloadTimeout);
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;
    return LookImage(
      bytes: response.bodyBytes,
      mimeType: _imageMimeType(response.headers['content-type']),
    );
  } on Exception {
    return null;
  } finally {
    if (client == null) httpClient.close();
  }
}

// Storage can answer with application/octet-stream; the receiving app only
// treats the file as a picture when the type says so.
String _imageMimeType(String? contentType) {
  final type = contentType?.split(';').first.trim().toLowerCase() ?? '';
  return type.startsWith('image/') ? type : _fallbackMimeType;
}
