import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:banigoba/modules/makeover/widgets/before_after_view.dart';

void main() {
  Widget wrap({VoidCallback? onTapAfter}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          child: BeforeAfterView(
            beforeImageUrl: 'https://example.com/avatar.jpg',
            afterImageUrl: 'https://example.com/look.jpg',
            onTapAfter: onTapAfter,
          ),
        ),
      ),
    ),
  );

  double labelOpacity(WidgetTester tester, String label) {
    final animated = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    return animated.opacity;
  }

  testWidgets('shows both labels at the default centre split', (tester) async {
    await tester.pumpWidget(wrap());

    expect(labelOpacity(tester, 'BEFORE'), 1);
    expect(labelOpacity(tester, 'AFTER'), 1);
  });

  testWidgets('dragging the handle left hides the before label', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());

    await tester.drag(find.byType(BeforeAfterView), const Offset(-120, 0));
    await tester.pumpAndSettle();

    expect(labelOpacity(tester, 'BEFORE'), 0);
    expect(labelOpacity(tester, 'AFTER'), 1);
  });

  testWidgets('dragging the handle right hides the after label', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());

    await tester.drag(find.byType(BeforeAfterView), const Offset(120, 0));
    await tester.pumpAndSettle();

    expect(labelOpacity(tester, 'BEFORE'), 1);
    expect(labelOpacity(tester, 'AFTER'), 0);
  });

  testWidgets('tapping the comparison opens the full-screen callback', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(wrap(onTapAfter: () => taps++));

    await tester.tap(find.byType(BeforeAfterView));
    await tester.pump();

    expect(taps, 1);
  });
}
