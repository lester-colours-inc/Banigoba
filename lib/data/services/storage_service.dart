// Uploads user images to Firebase Storage and records their URLs in Firestore.
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Service to handle all Firebase Storage operations for user and product images
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _userImagesDir = 'userImages';
  static const String _fullBodyDir = 'fullBody';
  static const String _selfieDir = 'selfie';
  static const String _profileDir = 'profile';
  static const String _handDir = 'hand';
  static const String _hairInspirationDir = 'hairInspiration';
  static const String _tryOnResultsDir = 'tryOnResults';
  static const String _styleReferencesDir = 'styleReferences';
  static const String _productImagesDir = 'productImages';

  /// Uploads a full-body image to userImages/{userId}/fullBody/ directory
  /// Returns the download URL of the uploaded image
  Future<String> uploadFullBodyImageBytes(
    Uint8List imageBytes,
    String userId, {
    String? filename,
  }) async {
    return await _uploadUserImageBytes(
      imageBytes,
      userId,
      _fullBodyDir,
      filename: filename,
    );
  }

  /// Uploads a generated try-on image to userImages/{userId}/tryOnResults/
  ///
  /// Gemini hands back raw bytes rather than a hosted URL, so results have to
  /// be stored before they can be shown or saved to an outfit.
  Future<String> uploadTryOnResultBytes(
    Uint8List imageBytes,
    String userId, {
    String? filename,
  }) async {
    return await _uploadUserImageBytes(
      imageBytes,
      userId,
      _tryOnResultsDir,
      filename: filename,
    );
  }

  /// Uploads a look the user wants to copy (Style twin) to
  /// userImages/{userId}/styleReferences/.
  ///
  /// Kept apart from fullBody so a reference photo is never mistaken for the
  /// user's own photo by [getLatestFullBodyImageUrl].
  Future<String> uploadStyleReferenceBytes(
    Uint8List imageBytes,
    String userId,
  ) {
    return _uploadUserImageBytes(imageBytes, userId, _styleReferencesDir);
  }

  /// Downloads an image from Firebase Storage using its download URL.
  Future<Uint8List?> downloadImageBytes(
    String downloadUrl, {
    int maxSize = 10 * 1024 * 1024,
  }) async {
    debugPrint(
      '[StorageService] Download starting: ${describeDownloadUrl(downloadUrl)}, maxSize=$maxSize',
    );
    try {
      final ref = _storage.refFromURL(downloadUrl);
      debugPrint('[StorageService] Resolved object path: ${ref.fullPath}');
      final bytes = await ref.getData(maxSize);
      debugPrint(
        '[StorageService] Download completed: ${bytes?.length ?? 0} bytes',
      );
      return bytes;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint(
        '[StorageService] Firebase download failed: code=${e.code}, message=${e.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
      return null;
    } catch (e, stackTrace) {
      debugPrint('[StorageService] Download failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  /// Logs whether Firebase Storage can resolve and read metadata for an image.
  Future<void> debugImageAccess(String downloadUrl) async {
    if (!kDebugMode) return;

    debugPrint(
      '[StorageService] Checking image access: ${describeDownloadUrl(downloadUrl)}',
    );
    try {
      final ref = _storage.refFromURL(downloadUrl);
      debugPrint(
        '[StorageService] Reference resolved: bucket=${ref.bucket}, path=${ref.fullPath}',
      );
      final metadata = await ref.getMetadata();
      debugPrint(
        '[StorageService] Metadata loaded: size=${metadata.size}, contentType=${metadata.contentType}, updated=${metadata.updated}',
      );
    } on FirebaseException catch (e, stackTrace) {
      debugPrint(
        '[StorageService] Metadata access failed: code=${e.code}, message=${e.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
    } catch (e, stackTrace) {
      debugPrint('[StorageService] Image access check failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Removes query parameters so Firebase download tokens are not written to logs.
  static String describeDownloadUrl(String downloadUrl) {
    final uri = Uri.tryParse(downloadUrl);
    if (uri == null) return 'invalid URL (${downloadUrl.length} characters)';
    return '${uri.scheme}://${uri.host}${uri.path}';
  }

  /// Uploads a selfie image to userImages/{userId}/selfie/ directory
  /// Returns the download URL of the uploaded image
  Future<String> uploadSelfieImageBytes(
    Uint8List imageBytes,
    String userId, {
    String? filename,
  }) async {
    return await _uploadUserImageBytes(
      imageBytes,
      userId,
      _selfieDir,
      filename: filename,
    );
  }

  /// Uploads a hand photo (for jewellery and nail try-ons) to
  /// userImages/{userId}/hand/.
  Future<String> uploadHandImageBytes(Uint8List imageBytes, String userId) {
    return _uploadUserImageBytes(imageBytes, userId, _handDir);
  }

  /// Uploads a hairstyle the user likes (My Hair Stylists) to
  /// userImages/{userId}/hairInspiration/.
  Future<String> uploadHairInspirationBytes(
    Uint8List imageBytes,
    String userId,
  ) {
    return _uploadUserImageBytes(imageBytes, userId, _hairInspirationDir);
  }

  Future<String> uploadProfileImageBytes(Uint8List imageBytes, String userId) {
    return _uploadUserImageBytes(imageBytes, userId, _profileDir);
  }

  /// Retrieves the latest full-body image URL for a user if it exists in storage
  Future<String?> getLatestFullBodyImageUrl(String userId) async {
    final directoryPath = '$_userImagesDir/$userId/$_fullBodyDir';
    debugPrint('[StorageService] Listing full-body images: $directoryPath');
    try {
      final ref = _storage
          .ref()
          .child(_userImagesDir)
          .child(userId)
          .child(_fullBodyDir);
      final result = await ref.listAll();
      debugPrint(
        '[StorageService] Storage listing returned ${result.items.length} file(s)',
      );
      if (result.items.isEmpty) {
        return null;
      }

      final latestItem =
          result.items
              .where(
                (item) =>
                    item.name.endsWith('.jpg') || item.name.endsWith('.png'),
              )
              .toList()
            ..sort((a, b) {
              final aTimestamp = int.tryParse(a.name.split('.').first) ?? 0;
              final bTimestamp = int.tryParse(b.name.split('.').first) ?? 0;
              return bTimestamp.compareTo(aTimestamp);
            });

      if (latestItem.isEmpty) {
        debugPrint(
          '[StorageService] No supported .jpg or .png files found in $directoryPath',
        );
        return null;
      }

      final latestRef = latestItem.first;
      final downloadUrl = await latestRef.getDownloadURL();
      debugPrint(
        '[StorageService] Latest full-body image: ${latestRef.fullPath}',
      );
      return downloadUrl;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint(
        '[StorageService] Storage listing failed: code=${e.code}, message=${e.message}, path=$directoryPath',
      );
      debugPrintStack(stackTrace: stackTrace);
      return null;
    } catch (e, stackTrace) {
      debugPrint('[StorageService] Storage listing failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  /// Uploads a product image to productImages/ directory
  /// Returns the download URL of the uploaded image
  Future<String> uploadProductImageBytes(
    Uint8List imageBytes,
    String userId, {
    String? filename,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalName = filename ?? '$timestamp.jpg';
      final ref = _storage
          .ref()
          .child(_productImagesDir)
          .child(userId)
          .child(finalName);

      await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await ref.getDownloadURL();

      debugPrint('Product image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading product image: $e');
      throw Exception('Failed to upload product image: $e');
    }
  }

  /// Helper method to upload user images (fullBody or selfie)
  Future<String> _uploadUserImageBytes(
    Uint8List imageBytes,
    String userId,
    String subDir, {
    String? filename,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalName = filename ?? '$timestamp.jpg';
      final ref = _storage
          .ref()
          .child(_userImagesDir)
          .child(userId)
          .child(subDir)
          .child(finalName);

      await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await ref.getDownloadURL();

      debugPrint('User image uploaded to $subDir: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading user image: $e');
      throw Exception('Failed to upload user image to $subDir: $e');
    }
  }

  /// Uploads multiple images and returns a list of download URLs
  /// Useful for batch uploads of multiple photos
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

  /// Deletes an image from Firebase Storage by its download URL
  Future<void> deleteImageByUrl(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      debugPrint('Image deleted: $downloadUrl');
    } catch (e) {
      debugPrint('Error deleting image: $e');
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Deletes all images in a specific directory for a user
  Future<void> deleteUserImageDirectory(String userId, String imageType) async {
    try {
      late Reference ref;
      if (imageType == 'fullBody') {
        ref = _storage
            .ref()
            .child(_userImagesDir)
            .child(_fullBodyDir)
            .child(userId);
      } else if (imageType == 'selfie') {
        ref = _storage
            .ref()
            .child(_userImagesDir)
            .child(_selfieDir)
            .child(userId);
      } else if (imageType == 'product') {
        ref = _storage.ref().child(_productImagesDir).child(userId);
      } else {
        throw ArgumentError('Invalid image type: $imageType');
      }

      final items = await ref.listAll();
      for (final file in items.items) {
        await file.delete();
      }
      debugPrint('Deleted all $imageType images for user $userId');
    } catch (e) {
      debugPrint('Error deleting image directory: $e');
      throw Exception('Failed to delete image directory: $e');
    }
  }
}
