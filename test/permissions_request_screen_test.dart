import 'package:banigoba/ui/screens/permissions/permissions_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
