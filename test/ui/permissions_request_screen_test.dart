// Verifies the permission onboarding screen only asks for missing permissions.
import 'package:banigoba/ui/screens/permissions/permissions_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the camera page for valid camera or photos permissions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PermissionsRequestScreen(
          requiredPermissions: const {'photos'},
          onPermissionsComplete: (_) async {},
        ),
      ),
    );

    expect(find.text('CAMERA'), findsOneWidget);
    expect(find.text('ADD YOUR LOCATION'), findsNothing);
    expect(find.text('DON’T MISS OUT'), findsNothing);
  });

  testWidgets('shows only the ungranted permission page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PermissionsRequestScreen(
          requiredPermissions: const {'location'},
          onPermissionsComplete: (_) async {},
        ),
      ),
    );

    expect(find.text('ADD YOUR LOCATION'), findsOneWidget);
    expect(find.text('CAMERA'), findsNothing);
    expect(find.text('DON’T MISS OUT'), findsNothing);
  });

  testWidgets('ignores invalid unknown permission values', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PermissionsRequestScreen(
          requiredPermissions: const {'microphone'},
          onPermissionsComplete: (_) async {},
        ),
      ),
    );

    expect(find.text('CAMERA'), findsNothing);
    expect(find.text('ADD YOUR LOCATION'), findsNothing);
    expect(find.text('DON’T MISS OUT'), findsNothing);
  });
}
