import 'dart:io';
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
    if (Platform.isIOS) {
      permissions.addAll([
        Permission.photos,
        Permission.photosAddOnly,
      ]);
    } else if (Platform.isAndroid) {
      permissions.addAll([
        Permission.storage,
        Permission.readMediaImages,
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
    if (Platform.isIOS) {
      final photos = await Permission.photos.status;
      photoStatus = photos.isGranted;
    } else if (Platform.isAndroid) {
      final storage = await Permission.storage.status;
      final mediaImages = await Permission.readMediaImages.status;
      photoStatus = storage.isGranted || mediaImages.isGranted;
    }

    return cameraStatus.isGranted && photoStatus.isGranted && locationStatus.isGranted;
  }

  /// Get summary of permission statuses for UI display
  static Future<Map<String, bool>> getPermissionsSummary() async {
    return {
      'camera': (await Permission.camera.status).isGranted,
      'location': (await Permission.location.status).isGranted,
      'photos': Platform.isIOS
          ? (await Permission.photos.status).isGranted
          : (await Permission.storage.status).isGranted || (await Permission.readMediaImages.status).isGranted,
      'notifications': (await Permission.notification.status).isGranted,
    };
  }
}
