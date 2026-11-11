import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/modules/notifications/widgets/notification_bell_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Stream<int> unread) => MaterialApp(
  routes: {AppRoutes.notifications: (_) => const Scaffold(body: Text('Inbox'))},
  home: Scaffold(
    appBar: AppBar(actions: [NotificationBellButton(unreadCount: unread)]),
  ),
);

void main() {
  testWidgets('shows the unread count on the bell', (tester) async {
    await tester.pumpWidget(_host(Stream.value(3)));
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('caps a large unread count at 9+', (tester) async {
    await tester.pumpWidget(_host(Stream.value(42)));
    await tester.pump();

    expect(find.text('9+'), findsOneWidget);
  });

  testWidgets('shows no badge when everything is read', (tester) async {
    await tester.pumpWidget(_host(Stream.value(0)));
    await tester.pump();

    expect(find.text('0'), findsNothing);
  });

  testWidgets('opens the notifications inbox when tapped', (tester) async {
    await tester.pumpWidget(_host(Stream.value(1)));
    await tester.pump();

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Inbox'), findsOneWidget);
  });
}
