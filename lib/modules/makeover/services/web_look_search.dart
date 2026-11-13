// Web look search: pictures of a look found on the internet, through our
// `search-looks` Edge Function (the search key stays on the server), and the
// copy of a chosen picture into the user's own style references, so the
// preview and the AI job never depend on someone else's site staying up.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import 'package:banigoba/core/services/storage_service.dart';
import 'package:banigoba/core/supabase/supabase_config.dart';

/// One picture found on the web.
@immutable
class WebLook {
  const WebLook({
    required this.imageUrl,
    required this.thumbnailUrl,
    this.title = '',
    this.source = '',
    this.pageUrl = '',
  });

  final String imageUrl;
  final String thumbnailUrl;
  final String title;

  /// The site it comes from, e.g. "vogue.com".
  final String source;
  final String pageUrl;

  @override
  bool operator ==(Object other) =>
      other is WebLook && other.imageUrl == imageUrl;

  @override
  int get hashCode => imageUrl.hashCode;
}

/// A search that could not be answered; [message] is safe to show.
class WebLookSearchException implements Exception {
  const WebLookSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads the function's answer; anything unexpected is left out.
List<WebLook> parseWebLooks(Object? data) {
  final raw = data is Map ? data['looks'] : null;
  if (raw is! List) return const [];
  String text(Map<Object?, Object?> map, String key) =>
      (map[key] ?? '').toString().trim();
  return List.unmodifiable([
    for (final item in raw)
      if (item is Map)
        if (text(item, 'imageUrl') case final image
            when image.startsWith('https://'))
          WebLook(
            imageUrl: image,
            thumbnailUrl: text(item, 'thumbnailUrl').startsWith('https://')
                ? text(item, 'thumbnailUrl')
                : image,
            title: text(item, 'title'),
            source: text(item, 'source'),
            pageUrl: text(item, 'pageUrl'),
          ),
  ]);
}

/// The search words for a style idol's looks, or '' when there is no name.
String idolLookQuery(String idolName) {
  final name = idolName.trim();
  return name.isEmpty ? '' : '$name outfit';
}

/// What the screens need; the real one asks the server, tests use a fake.
abstract interface class WebLookSearch {
  Future<List<WebLook>> search(String query);

  /// Copies [look] into the user's style references and returns its new
  /// address, or null when neither the picture nor its thumbnail can be used.
  Future<String?> keep(WebLook look);
}

class ServerWebLookSearch implements WebLookSearch {
  ServerWebLookSearch({
    required this.userId,
    StorageService? storage,
    http.Client? client,
  }) : _storage = storage ?? StorageService(),
       _client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 15);
  static const int _minBytes = 1024;
  static const int _maxBytes = 12 * 1024 * 1024;

  final String userId;
  final StorageService _storage;
  final http.Client _client;

  @override
  Future<List<WebLook>> search(String query) async {
    try {
      final result = await supabase.functions
          .invoke('search-looks', body: {'query': query.trim()})
          .timeout(_timeout);
      return parseWebLooks(result.data);
    } on FunctionException catch (error) {
      final details = error.details;
      final message = details is Map ? details['error'] : null;
      throw WebLookSearchException(
        message is String && message.isNotEmpty
            ? message
            : 'Web search is not available right now.',
      );
    } on TimeoutException {
      throw const WebLookSearchException(
        'Web search took too long. Try again.',
      );
    }
  }

  @override
  Future<String?> keep(WebLook look) async {
    if (userId.isEmpty) return null;
    for (final url in {look.imageUrl, look.thumbnailUrl}) {
      final bytes = await _download(url);
      if (bytes == null) continue;
      return _storage.uploadStyleReferenceBytes(bytes, userId);
    }
    return null;
  }

  Future<Uint8List?> _download(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return null;
    try {
      final response = await _client.get(uri).timeout(_timeout);
      final type = response.headers['content-type'] ?? '';
      final bytes = response.bodyBytes;
      final usable =
          response.statusCode == 200 &&
          type.startsWith('image/') &&
          bytes.length >= _minBytes &&
          bytes.length <= _maxBytes;
      return usable ? bytes : null;
    } on TimeoutException {
      return null;
    } on http.ClientException catch (error) {
      debugPrint('Web look download failed: $error');
      return null;
    }
  }
}
