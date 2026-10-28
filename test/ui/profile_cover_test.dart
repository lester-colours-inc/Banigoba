// Verifies the profile cover: who it shows, and that only your own photo
// can be changed from it.
import 'package:banigoba/ui/screens/social/widgets/profile_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  testWidgets('shows the name, handle and your own email', (tester) async {
    await tester.pumpWidget(
      _host(
        const ProfileCover(
          name: 'Tariro Muzaya',
          photoUrl: '',
          username: 'tariro',
          email: 'tariro@example.com',
        ),
      ),
    );

    expect(find.text('Tariro Muzaya'), findsOneWidget);
    expect(find.text('@tariro'), findsOneWidget);
    expect(find.text('tariro@example.com'), findsOneWidget);
    // No photo yet: the first letter of the name stands in.
    expect(find.text('T'), findsOneWidget);
  });

  testWidgets('leaves out the handle and email when there are none', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const ProfileCover(name: 'Rudo', photoUrl: '')),
    );

    expect(find.byKey(const ValueKey('profile_username')), findsNothing);
    expect(find.textContaining('@'), findsNothing);
  });

  testWidgets('your own photo can be tapped to change it', (tester) async {
    var changes = 0;
    await tester.pumpWidget(
      _host(
        ProfileCover(
          name: 'Tariro',
          photoUrl: '',
          onChangePhoto: () => changes++,
        ),
      ),
    );

    expect(find.bySemanticsLabel('Change profile photo'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('profile_change_photo')));
    expect(changes, 1);
  });

  testWidgets('someone else\'s photo cannot be changed', (tester) async {
    await tester.pumpWidget(
      _host(const ProfileCover(name: 'Rudo', photoUrl: '')),
    );

    expect(find.byKey(const ValueKey('profile_change_photo')), findsNothing);
    expect(find.byIcon(Icons.photo_camera_outlined), findsNothing);
  });

  testWidgets('the photo overlaps the bottom edge of the banner', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const ProfileCover(name: 'Rudo', photoUrl: '')),
    );

    final banner = tester.getRect(find.byType(ClipRRect).first);
    final photo = tester.getRect(find.byType(ClipOval));
    expect(photo.top, lessThan(banner.bottom));
    expect(photo.bottom, greaterThan(banner.bottom));
  });
}
