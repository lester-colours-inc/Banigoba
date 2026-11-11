// Verifies the top-left control: back on a pushed page, menu on a root page.
import 'package:banigoba/shared/widgets/menu_or_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _page() => Scaffold(
  appBar: AppBar(leading: const MenuOrBackButton()),
  body: const Text('Page'),
);

void main() {
  testWidgets('a root page shows the menu and opens the drawer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: const Drawer(child: Text('Drawer')),
          // A tab page with its own Scaffold, inside the shell.
          body: _page(),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('app_back')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('app_menu')));
    await tester.pumpAndSettle();
    expect(find.text('Drawer'), findsOneWidget);
  });

  testWidgets('a pushed page shows a back arrow that goes back', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const Text('Home')),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => _page()),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('app_menu')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('app_back')));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
}
