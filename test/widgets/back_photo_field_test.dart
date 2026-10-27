// Verifies the shop's optional back photo field.
import 'package:banigoba/ui/widgets/back_photo_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  String existing = '',
  VoidCallback? onPick,
  VoidCallback? onRemove,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BackPhotoField(
          picked: null,
          existingUrl: existing,
          onPick: onPick ?? () {},
          onRemove: onRemove ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('with no photo it offers Add and no remove button', (
    tester,
  ) async {
    var picked = false;
    await _pump(tester, onPick: () => picked = true);

    expect(find.text('Back photo (optional)'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.byKey(const ValueKey('back_photo_remove')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('back_photo_pick')));
    expect(picked, isTrue);
  });

  testWidgets('with a saved photo it offers Change and Remove', (tester) async {
    var removed = false;
    await _pump(
      tester,
      existing: 'https://example.com/back.jpg',
      onRemove: () => removed = true,
    );

    expect(find.text('Change'), findsOneWidget);
    expect(find.textContaining('accurate back'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('back_photo_remove')));
    expect(removed, isTrue);
  });
}
