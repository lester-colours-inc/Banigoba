// Verifies the home screen's labelled makeover button.
import 'package:banigoba/ui/widgets/makeover_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({required VoidCallback onPressed, bool reduceMotion = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(
        floatingActionButton: MakeoverFab(
          color: const Color(0xFF0D0140),
          onPressed: onPressed,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the full "Create My Fashion Makeover" label', (
    tester,
  ) async {
    await tester.pumpWidget(_host(onPressed: () {}));
    await tester.pumpAndSettle();

    expect(find.text('Create My Fashion Makeover'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });

  testWidgets('tapping opens the makeover', (tester) async {
    var opened = false;
    await tester.pumpWidget(_host(onPressed: () => opened = true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home_makeover_button')));
    expect(opened, isTrue);
  });

  testWidgets('pulses on open, then settles at normal size', (tester) async {
    await tester.pumpWidget(_host(onPressed: () {}));
    final scale = tester.widget<ScaleTransition>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('home_makeover_button')),
            matching: find.byType(ScaleTransition),
          )
          .first,
    );

    await tester.pump(const Duration(milliseconds: 350));
    expect(scale.scale.value, greaterThan(1.0));

    await tester.pumpAndSettle();
    expect(scale.scale.value, 1.0);
  });

  testWidgets('does not pulse when the system asks for reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(_host(onPressed: () {}, reduceMotion: true));
    await tester.pump(const Duration(milliseconds: 350));

    final scale = tester.widget<ScaleTransition>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('home_makeover_button')),
            matching: find.byType(ScaleTransition),
          )
          .first,
    );
    expect(scale.scale.value, 1.0);
  });
}
