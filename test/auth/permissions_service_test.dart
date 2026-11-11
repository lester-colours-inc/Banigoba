// Verifies the permission summary used by the post-authentication gate.
import 'package:flutter_test/flutter_test.dart';
import 'package:banigoba/core/services/permissions_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  test('returns true when every tracked permission is granted', () {
    expect(
      PermissionsService.areAllPermissionsGranted({
        'camera': true,
        'location': true,
        'photos': true,
        'notifications': true,
      }),
      isTrue,
    );
  });

  test('returns false when a tracked permission is missing', () {
    expect(
      PermissionsService.areAllPermissionsGranted({
        'camera': true,
        'location': false,
        'photos': true,
        'notifications': true,
      }),
      isFalse,
    );
  });

  test('ignores invalid extra permission keys when valid keys are granted', () {
    expect(
      PermissionsService.areAllPermissionsGranted({
        'camera': true,
        'location': true,
        'photos': true,
        'notifications': true,
        'microphone': false,
      }),
      isTrue,
    );
  });

  test('returns false for empty permission values', () {
    expect(PermissionsService.areAllPermissionsGranted({}), isFalse);
  });

  test('treats limited photo access as accepted', () {
    expect(
      PermissionsService.isAcceptedStatus(PermissionStatus.limited),
      isTrue,
    );
  });

  test('does not treat denied photo access as accepted', () {
    expect(
      PermissionsService.isAcceptedStatus(PermissionStatus.denied),
      isFalse,
    );
  });
}
