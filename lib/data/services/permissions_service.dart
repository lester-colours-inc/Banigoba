// Provides platform-aware helpers for requesting and summarizing app permissions.
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  /// Request all required permissions
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final List<Permission> permissions = [
      Permission.camera,
      Permission.location,
      Permission.notification,
    ];

    // Add platform-specific photo/media permissions
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      permissions.addAll([
        Permission.photos,
        Permission.photosAddOnly,
      ]);
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      permissions.addAll([
        Permission.storage,
      ]);
    }

    final Map<Permission, PermissionStatus> statuses = {};
    for (final permission in permissions) {
      final status = await permission.request();
      statuses[permission] = status;
    }
    return statuses;
  }

  /// Check if all critical permissions are granted (camera, location, photos)
  static Future<bool> areCriticalPermissionsGranted() async {
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;

    bool photoStatus = true;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final photos = await Permission.photos.status;
      photoStatus = photos.isGranted;
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final storage = await Permission.storage.status;
      photoStatus = storage.isGranted;
    }

    return cameraStatus.isGranted && photoStatus && locationStatus.isGranted;
  }

  /// Get summary of permission statuses for UI display
  static Future<Map<String, bool>> getPermissionsSummary() async {
    return {
      'camera': (await Permission.camera.status).isGranted,
      'location': (await Permission.location.status).isGranted,
      'photos': await _arePhotosGranted(),
      'notifications': (await Permission.notification.status).isGranted,
    };
  }

  static Future<bool> _arePhotosGranted() async {
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return (await Permission.photos.status).isGranted;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final storage = await Permission.storage.status;
      return storage.isGranted;
    }
    return true;
  }
}
