// Verifies the home screen's labelled makeover button.
import 'package:banigoba/ui/widgets/makeover_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_test/flutter_test.dart';

Widget _host({
  required VoidCallback onPressed,
  bool reduceMotion = false,
  bool isExtended = true,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(
        floatingActionButton: MakeoverFab(
          color: const Color(0xFF0D0140),
          isExtended: isExtended,
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

  testWidgets('folds to the sparkle alone, still named and tappable', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(_host(onPressed: () {}));
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('home_makeover_button'));
    final extendedWidth = tester.getSize(button).width;

    await tester.pumpWidget(
      _host(onPressed: () => opened = true, isExtended: false),
    );
    await tester.pumpAndSettle();

    final folded = tester.getSize(button);
    expect(folded.width, lessThan(extendedWidth / 3));
    expect(folded.width, closeTo(folded.height, 1));
    expect(find.text(kMakeoverFabLabel), findsNothing);
    expect(find.bySemanticsLabel(kMakeoverFabLabel), findsOneWidget);
    await tester.tap(button);
    expect(opened, isTrue);
  });

  group('folding while the feed scrolls', () {
    test('folds as soon as the feed scrolls down, even from the top', () {
      expect(
        makeoverFabExtendedAfter(
          ScrollDirection.reverse,
          wasExtended: true,
          offset: 0,
        ),
        isFalse,
      );
    });

    test('unfolds when the feed scrolls back up', () {
      expect(
        makeoverFabExtendedAfter(
          ScrollDirection.forward,
          wasExtended: false,
          offset: 800,
        ),
        isTrue,
      );
    });

    test('stays folded when scrolling stops part way down', () {
      expect(
        makeoverFabExtendedAfter(
          ScrollDirection.idle,
          wasExtended: false,
          offset: 800,
        ),
        isFalse,
      );
    });

    test('unfolds when scrolling stops at the top', () {
      expect(
        makeoverFabExtendedAfter(
          ScrollDirection.idle,
          wasExtended: false,
          offset: 0,
        ),
        isTrue,
      );
    });
  });
}
