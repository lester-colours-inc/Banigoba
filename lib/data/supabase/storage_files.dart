// Uploads, downloads and deletes files in Supabase Storage, and turns object
// paths into the public URLs the app stores and shows.
//
// Buckets are public to read and writable only inside the signed-in user's
// own folder (the first path segment is their user id). Names are random, so
// a file cannot be found by guessing.
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../../core/supabase/supabase_config.dart';

/// The buckets the app uses.
class Buckets {
  static const String productImages = 'product-images';
  static const String events = 'events';
  static const String userImages = 'user-images';
  static const String aiMakeovers = 'ai-makeovers';
  static const String hairstyles = 'hairstyles';
}

final Random _random = Random.secure();

/// A random file name, e.g. `3f9a…c1.jpg`.
String randomFileName([String extension = 'jpg']) {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '$hex.$extension';
}

/// A bucket and object path inside it.
class StoragePath {
  const StoragePath(this.bucket, this.path);
  final String bucket;
  final String path;
}

class StorageFiles {
  /// Uploads [bytes] to `bucket/path` and returns the public URL.
  static Future<String> upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    await supabase.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );
    return supabase.storage.from(bucket).getPublicUrl(path);
  }

  /// The bucket and path a public URL of ours points at, or null for any
  /// other address.
  static StoragePath? parse(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    const marker = '/storage/v1/object/public/';
    final at = uri.path.indexOf(marker);
    if (at < 0) return null;
    final rest = uri.path.substring(at + marker.length);
    final slash = rest.indexOf('/');
    if (slash <= 0) return null;
    return StoragePath(
      rest.substring(0, slash),
      Uri.decodeComponent(rest.substring(slash + 1)),
    );
  }

  /// The file at [url] (ours through the API, anything else over HTTP), or
  /// null if it cannot be fetched.
  static Future<Uint8List?> download(String url) async {
    try {
      final located = parse(url);
      if (located != null) {
        return await supabase.storage
            .from(located.bucket)
            .download(located.path);
      }
      final response = await http.get(Uri.parse(url));
      return response.statusCode == 200 ? response.bodyBytes : null;
    } on Object catch (error) {
      debugPrint('[StorageFiles] Download failed: $error');
      return null;
    }
  }

  /// Deletes the file at [url] if it is one of ours.
  static Future<void> deleteByUrl(String url) async {
    final located = parse(url);
    if (located == null) return;
    await supabase.storage.from(located.bucket).remove([located.path]);
  }
}
