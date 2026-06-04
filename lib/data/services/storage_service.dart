
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Service to handle all Firebase Storage operations for user and product images
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _userImagesDir = 'userImages';
  static const String _fullBodyDir = 'fullBody';
  static const String _selfieDir = 'selfie';
  static const String _productImagesDir = 'productImages';

  /// Uploads a full-body image to userImages/{userId}/fullBody/ directory
  /// Returns the download URL of the uploaded image
  Future<String> uploadFullBodyImageBytes(Uint8List imageBytes, String userId, {String? filename}) async {
    return await _uploadUserImageBytes(imageBytes, userId, _fullBodyDir, filename: filename);
  }

  /// Downloads an image from Firebase Storage using its download URL.
  Future<Uint8List?> downloadImageBytes(String downloadUrl, {int maxSize = 10 * 1024 * 1024}) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      return await ref.getData(maxSize);
    } catch (e) {
      debugPrint('Error downloading image bytes: $e');
      return null;
    }
  }

  /// Uploads a selfie image to userImages/{userId}/selfie/ directory
  /// Returns the download URL of the uploaded image
  Future<String> uploadSelfieImageBytes(Uint8List imageBytes, String userId, {String? filename}) async {
    return await _uploadUserImageBytes(imageBytes, userId, _selfieDir, filename: filename);
  }

  /// Retrieves the latest full-body image URL for a user if it exists in storage
  Future<String?> getLatestFullBodyImageUrl(String userId) async {
    try {
      final ref = _storage.ref().child(_userImagesDir).child(userId).child(_fullBodyDir);
      final result = await ref.listAll();
      if (result.items.isEmpty) {
        return null;
      }

      final latestItem = result.items
          .where((item) => item.name.endsWith('.jpg') || item.name.endsWith('.png'))
          .toList()
        ..sort((a, b) {
          final aTimestamp = int.tryParse(a.name.split('.').first) ?? 0;
          final bTimestamp = int.tryParse(b.name.split('.').first) ?? 0;
          return bTimestamp.compareTo(aTimestamp);
        });

      if (latestItem.isEmpty) {
        return null;
      }

      return await latestItem.first.getDownloadURL();
    } catch (e) {
      debugPrint('Error retrieving latest full-body image URL: $e');
      return null;
    }
  }

  /// Uploads a product image to productImages/ directory
  /// Returns the download URL of the uploaded image
  Future<String> uploadProductImageBytes(Uint8List imageBytes, String userId, {String? filename}) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalName = filename ?? '$timestamp.jpg';
      final ref = _storage.ref().child(_productImagesDir).child(userId).child(finalName);

      await ref.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
      final downloadUrl = await ref.getDownloadURL();

      debugPrint('Product image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading product image: $e');
      throw Exception('Failed to upload product image: $e');
    }
  }

  /// Helper method to upload user images (fullBody or selfie)
  Future<String> _uploadUserImageBytes(Uint8List imageBytes, String userId, String subDir, {String? filename}) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalName = filename ?? '$timestamp.jpg';
      final ref = _storage
          .ref()
          .child(_userImagesDir)
          .child(userId)
          .child(subDir)
          .child(finalName);

      await ref.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
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
        ref = _storage.ref().child(_userImagesDir).child(_fullBodyDir).child(userId);
      } else if (imageType == 'selfie') {
        ref = _storage.ref().child(_userImagesDir).child(_selfieDir).child(userId);
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
