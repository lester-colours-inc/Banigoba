import 'package:banigoba/shared/widgets/double_back_to_exit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/toast_pump.dart';
import 'package:toastification/toastification.dart';

Future<List<int>> _pump(WidgetTester tester) async {
  final exits = <int>[];
  final scaffoldKey = GlobalKey<ScaffoldState>();
  await tester.pumpWidget(
    ToastificationWrapper(
      child: MaterialApp(
        home: DoubleBackToExit(
          onExit: () => exits.add(1),
          onBackFirst: () {
            final scaffold = scaffoldKey.currentState;
            if (scaffold == null || !scaffold.isDrawerOpen) return false;
            scaffold.closeDrawer();
            return true;
          },
          child: Scaffold(
            key: scaffoldKey,
            drawer: const Drawer(child: Text('Drawer')),
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                child: const Text('Open drawer'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return exits;
}

Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump();
}

void main() {
  testWidgets('first back press only shows a hint', (tester) async {
    final exits = await _pump(tester);

    await _back(tester);

    expect(exits, isEmpty);
    await tester.pumpToast();
    expect(find.text(kPressBackAgainToExit), findsOneWidget);
  });

  testWidgets('second back press within the window exits', (tester) async {
    final exits = await _pump(tester);

    await _back(tester);
    await tester.pump(const Duration(seconds: 1));
    await _back(tester);

    expect(exits, hasLength(1));
    // Let the hint's exit animation finish.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a second press after the window shows the hint again', (
    tester,
  ) async {
    final exits = await _pump(tester);

    await _back(tester);
    await tester.pump(const Duration(seconds: 3));
    await _back(tester);

    expect(exits, isEmpty);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('back closes an open drawer without arming exit', (tester) async {
    final exits = await _pump(tester);
    await tester.tap(find.text('Open drawer'));
    await tester.pumpAndSettle();

    await _back(tester);
    await tester.pumpAndSettle();

    expect(find.text('Drawer'), findsNothing);
    expect(find.text(kPressBackAgainToExit), findsNothing);
    expect(exits, isEmpty);
  });
}
