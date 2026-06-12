// Provides platform-aware helpers for requesting and summarizing app permissions.
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  static const Map<String, bool> emptyPermissionsSummary = {
    'camera': false,
    'location': false,
    'photos': false,
    'notifications': false,
  };

  /// Request all required permissions
  static Future<Map<Permission, PermissionStatus>>
  requestAllPermissions() async {
    final statuses = <Permission, PermissionStatus>{};
    statuses.addAll(await requestCameraAndPhotosPermissions());
    statuses.addAll(await requestLocationPermission());
    statuses.addAll(await requestNotificationPermission());
    return statuses;
  }

  static Future<Map<Permission, PermissionStatus>>
  requestCameraAndPhotosPermissions() async {
    final List<Permission> permissions = [Permission.camera];

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      permissions.addAll([Permission.photos, Permission.photosAddOnly]);
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      permissions.addAll([Permission.storage, Permission.photos]);
    }

    return _requestPermissions(permissions);
  }

  static Future<Map<Permission, PermissionStatus>> requestLocationPermission() {
    return _requestPermissions([Permission.location]);
  }

  static Future<Map<Permission, PermissionStatus>>
  requestNotificationPermission() {
    return _requestPermissions([Permission.notification]);
  }

  static Future<Map<Permission, PermissionStatus>> _requestPermissions(
    List<Permission> permissions,
  ) async {
    final Map<Permission, PermissionStatus> statuses = {};
    for (final permission in permissions) {
      final currentStatus = await permission.status;
      final status = isAcceptedStatus(currentStatus)
          ? currentStatus
          : await permission.request();
      statuses[permission] = status;
    }
    return statuses;
  }

  static bool isAcceptedStatus(PermissionStatus status) {
    return status.isGranted || status.isLimited;
  }

  static bool areAllPermissionsGranted(Map<String, bool> statuses) {
    return emptyPermissionsSummary.keys.every(
      (permission) => statuses[permission] == true,
    );
  }

  /// Check if all critical permissions are granted (camera, location, photos)
  static Future<bool> areCriticalPermissionsGranted() async {
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;

    bool photoStatus = true;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final photos = await Permission.photos.status;
      final photosAddOnly = await Permission.photosAddOnly.status;
      photoStatus = isAcceptedStatus(photos) || isAcceptedStatus(photosAddOnly);
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final storage = await Permission.storage.status;
      final photos = await Permission.photos.status;
      photoStatus = isAcceptedStatus(storage) || isAcceptedStatus(photos);
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
      final photos = await Permission.photos.status;
      final photosAddOnly = await Permission.photosAddOnly.status;
      return isAcceptedStatus(photos) || isAcceptedStatus(photosAddOnly);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final storage = await Permission.storage.status;
      final photos = await Permission.photos.status;
      return isAcceptedStatus(storage) || isAcceptedStatus(photos);
    }
    return true;
  }
}
