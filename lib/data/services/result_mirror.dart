// Keeps a copy of a generated image in our own storage.
//
// FASHN returns a temporary link on its own host. Saving that link means the
// look breaks when it expires, and browsers refuse to draw it at all because
// the host sends no CORS header. Copying the picture into our storage first
// fixes both. If the copy cannot be made the original link is kept, so a
// result is never lost to a failed copy.
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'storage_service.dart';

typedef ImageFetcher = Future<Uint8List> Function(String url);
typedef ImageKeeper = Future<String> Function(Uint8List bytes, String userId);

class ResultMirror {
  ResultMirror({ImageFetcher? fetch, ImageKeeper? upload})
    : _fetch = fetch ?? _download,
      _upload = upload ?? StorageService().uploadTryOnResultBytes;

  final ImageFetcher _fetch;
  final ImageKeeper _upload;

  static const Duration _timeout = Duration(seconds: 30);

  static Future<Uint8List> _download(String url) async {
    final response = await http.get(Uri.parse(url)).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Download failed (${response.statusCode}).');
    }
    return response.bodyBytes;
  }

  /// Returns the address of our own copy of [url], or [url] itself when it is
  /// already ours or the copy fails.
  Future<String> keep(String url, String userId) async {
    if (_isOurs(url)) return url;
    try {
      return await _upload(await _fetch(url), userId);
    } on Exception catch (error) {
      debugPrint('Could not keep a copy of the result: $error');
      return url;
    }
  }

  static bool _isOurs(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    return host.contains('firebasestorage') || host.endsWith('.appspot.com');
  }
}
