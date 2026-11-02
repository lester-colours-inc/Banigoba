// Uploads user images to Supabase Storage and returns their public URLs.
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show SearchOptions, SortBy;

import '../../core/supabase/supabase_config.dart';
import '../supabase/storage_files.dart';

/// Service to handle all storage operations for user and product images.
///
/// Files sit in `user-images/{userId}/{kind}/` and `product-images/{userId}/`;
/// only the signed-in owner can write inside their own folder.
class StorageService {
  static const String _fullBodyDir = 'fullBody';
  static const String _selfieDir = 'selfie';
  static const String _profileDir = 'profile';
  static const String _handDir = 'hand';
  static const String _hairInspirationDir = 'hairInspiration';
  static const String _tryOnResultsDir = 'tryOnResults';
  static const String _styleReferencesDir = 'styleReferences';

  /// Uploads a full-body image. Returns the URL of the uploaded image.
  Future<String> uploadFullBodyImageBytes(
    Uint8List imageBytes,
    String userId, {
    String? filename,
  }) {
    return _uploadUserImageBytes(
      imageBytes,
      userId,
      _fullBodyDir,
      filename: filename,
    );
  }

  /// Uploads a generated try-on image.
  ///
  /// Gemini hands back raw bytes rather than a hosted URL, so results have to
  /// be stored before they can be shown or saved to an outfit.
  Future<String> uploadTryOnResultBytes(
    Uint8List imageBytes,
    String userId, {
    String? filename,
  }) {
    return _uploadUserImageBytes(
      imageBytes,
      userId,
      _tryOnResultsDir,
      filename: filename,
    );
  }

  /// Uploads a look the user wants to copy (Style twin).
  ///
  /// Kept apart from fullBody so a reference photo is never mistaken for the
  /// user's own photo by [getLatestFullBodyImageUrl].
  Future<String> uploadStyleReferenceBytes(
    Uint8List imageBytes,
    String userId,
  ) {
    return _uploadUserImageBytes(imageBytes, userId, _styleReferencesDir);
  }

  /// Downloads an image by its URL.
  Future<Uint8List?> downloadImageBytes(
    String downloadUrl, {
    int maxSize = 10 * 1024 * 1024,
  }) async {
    debugPrint(
      '[StorageService] Download starting: ${describeDownloadUrl(downloadUrl)}, maxSize=$maxSize',
    );
    final bytes = await StorageFiles.download(downloadUrl);
    if (bytes != null && bytes.length > maxSize) {
      debugPrint('[StorageService] Image larger than $maxSize bytes');
      return null;
    }
    debugPrint('[StorageService] Download completed: ${bytes?.length ?? 0}');
    return bytes;
  }

  /// Logs where an image lives, for debugging access problems.
  Future<void> debugImageAccess(String downloadUrl) async {
    if (!kDebugMode) return;
    final located = StorageFiles.parse(downloadUrl);
    debugPrint(
      '[StorageService] Image ${describeDownloadUrl(downloadUrl)}: '
      '${located == null ? 'not a Banigoba storage URL' : 'bucket=${located.bucket}, path=${located.path}'}',
    );
  }

  /// Drops the query string so tokens are not written to logs.
  static String describeDownloadUrl(String downloadUrl) {
    final uri = Uri.tryParse(downloadUrl);
    if (uri == null) return 'invalid URL (${downloadUrl.length} characters)';
    return '${uri.scheme}://${uri.host}${uri.path}';
  }

  /// Uploads a selfie image. Returns the URL of the uploaded image.
  Future<String> uploadSelfieImageBytes(
    Uint8List imageBytes,
    String userId, {
    String? filename,
  }) {
    return _uploadUserImageBytes(
      imageBytes,
      userId,
      _selfieDir,
      filename: filename,
    );
  }

  /// Uploads a hand photo (for jewellery and nail try-ons).
  Future<String> uploadHandImageBytes(Uint8List imageBytes, String userId) {
    return _uploadUserImageBytes(imageBytes, userId, _handDir);
  }

  /// Uploads a hairstyle the user likes (My Hair Stylists).
  Future<String> uploadHairInspirationBytes(
    Uint8List imageBytes,
    String userId,
  ) {
    return _uploadUserImageBytes(imageBytes, userId, _hairInspirationDir);
  }

  Future<String> uploadProfileImageBytes(Uint8List imageBytes, String userId) {
    return _uploadUserImageBytes(imageBytes, userId, _profileDir);
  }

  /// The newest full-body image URL for a user, or null if there is none.
  Future<String?> getLatestFullBodyImageUrl(String userId) async {
    final directory = '$userId/$_fullBodyDir';
    try {
      final files = await supabase.storage
          .from(Buckets.userImages)
          .list(
            path: directory,
            searchOptions: const SearchOptions(
              limit: 1,
              sortBy: SortBy(column: 'created_at', order: 'desc'),
            ),
          );
      final images = files.where(
        (file) => file.name.endsWith('.jpg') || file.name.endsWith('.png'),
      );
      if (images.isEmpty) return null;
      return supabase.storage
          .from(Buckets.userImages)
          .getPublicUrl('$directory/${images.first.name}');
    } on Object catch (e) {
      debugPrint('[StorageService] Storage listing failed: $e');
      return null;
    }
  }

  /// Uploads a product image. Returns the URL of the uploaded image.
  Future<String> uploadProductImageBytes(
    Uint8List imageBytes,
    String userId, {
    String? filename,
  }) async {
    try {
      return await StorageFiles.upload(
        bucket: Buckets.productImages,
        path: '$userId/${filename ?? randomFileName()}',
        bytes: imageBytes,
      );
    } catch (e) {
      debugPrint('Error uploading product image: $e');
      throw Exception('Failed to upload product image: $e');
    }
  }

  Future<String> _uploadUserImageBytes(
    Uint8List imageBytes,
    String userId,
    String subDir, {
    String? filename,
  }) async {
    try {
      return await StorageFiles.upload(
        bucket: Buckets.userImages,
        path: '$userId/$subDir/${filename ?? randomFileName()}',
        bytes: imageBytes,
      );
    } catch (e) {
      debugPrint('Error uploading user image: $e');
      throw Exception('Failed to upload user image to $subDir: $e');
    }
  }

  /// Uploads multiple images and returns a list of URLs.
  Future<List<String>> uploadMultipleImages(
    List<Uint8List> imageFiles,
    String userId,
    String imageType, // 'fullBody', 'selfie', or 'product'
  ) async {
    final urls = <String>[];

    for (final file in imageFiles) {
      try {
        late String url;
        if (imageType == 'fullBody') {
          url = await uploadFullBodyImageBytes(file, userId);
        } else if (imageType == 'selfie') {
          url = await uploadSelfieImageBytes(file, userId);
        } else if (imageType == 'product') {
          url = await uploadProductImageBytes(file, userId);
        } else {
          throw ArgumentError('Invalid image type: $imageType');
        }
        urls.add(url);
      } catch (e) {
        debugPrint('Error uploading image to $imageType: $e');
      }
    }

    return urls;
  }

  /// Deletes an image by its URL.
  Future<void> deleteImageByUrl(String downloadUrl) async {
    try {
      await StorageFiles.deleteByUrl(downloadUrl);
    } catch (e) {
      debugPrint('Error deleting image: $e');
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Deletes all images in a specific folder for a user.
  Future<void> deleteUserImageDirectory(String userId, String imageType) async {
    try {
      final (bucket, directory) = switch (imageType) {
        'fullBody' => (Buckets.userImages, '$userId/$_fullBodyDir'),
        'selfie' => (Buckets.userImages, '$userId/$_selfieDir'),
        'product' => (Buckets.productImages, userId),
        _ => throw ArgumentError('Invalid image type: $imageType'),
      };
      final files = await supabase.storage.from(bucket).list(path: directory);
      if (files.isEmpty) return;
      await supabase.storage.from(bucket).remove([
        for (final file in files) '$directory/${file.name}',
      ]);
    } catch (e) {
      debugPrint('Error deleting image directory: $e');
      throw Exception('Failed to delete image directory: $e');
    }
  }
}
