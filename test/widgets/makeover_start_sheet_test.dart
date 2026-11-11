// Verifies the first makeover question: hairstyle, or outfit & more.
import 'package:banigoba/modules/makeover/views/makeover_start_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<MakeoverStart?> _choose(WidgetTester tester, String key) async {
  MakeoverStart? picked;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              picked = await showModalBottomSheet<MakeoverStart>(
                context: context,
                builder: (_) => const MakeoverStartSheet(),
              ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(find.text('Hairstyle'), findsOneWidget);
  expect(find.text('Outfit & more'), findsOneWidget);
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
  return picked;
}

void main() {
  testWidgets('offers hairstyle and returns it', (tester) async {
    expect(
      await _choose(tester, 'makeover_start_hairstyle'),
      MakeoverStart.hairstyle,
    );
  });

  testWidgets('offers outfit & more and returns it', (tester) async {
    expect(
      await _choose(tester, 'makeover_start_outfit'),
      MakeoverStart.outfit,
    );
  });
}
