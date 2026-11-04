// Verifies quick add (K-1): a trader adds a piece with a photo, a price and
// sizes, and can add another straight after.
import 'dart:typed_data';

import 'package:banigoba/data/models/quick_add.dart';
import 'package:banigoba/ui/screens/shop/quick_add_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class _FakeSaver implements QuickAddSaver {
  final saved = <QuickAddDraft>[];
  Object? failWith;

  @override
  Future<void> save(QuickAddDraft draft, Uint8List photo) async {
    if (failWith != null) throw failWith!;
    saved.add(draft);
  }
}

// A 1x1 transparent PNG, so Image.memory has something to decode.
final Uint8List _png = Uint8List.fromList([
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4, 0x89, 0x00, 0x00, 0x00,
  0x0d, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0d, 0x0a, 0x2d, 0xb4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
]);

Future<_FakeSaver> _open(WidgetTester tester, {_FakeSaver? saver}) async {
  // Tall enough that the whole form is on screen.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final fake = saver ?? _FakeSaver();
  await tester.pumpWidget(
    MaterialApp(
      home: QuickAddPage(saver: fake, pickPhoto: (_) async => _png),
    ),
  );
  return fake;
}

Future<void> _takePhoto(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('photo_area')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('photo_camera')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('asks for what is missing before saving', (tester) async {
    final saver = await _open(tester);

    await tester.tap(find.byKey(const ValueKey('quick_add_save')));
    await tester.pump();

    expect(find.text('Add a photo of the piece.'), findsOneWidget);
    expect(saver.saved, isEmpty);
  });

  testWidgets('a photo, a price and a size add the piece', (tester) async {
    final saver = await _open(tester);

    await _takePhoto(tester);
    await tester.enterText(find.byKey(const ValueKey('price_field')), '12.5');
    await tester.tap(find.byKey(const ValueKey('size_M')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('quick_add_save')));
    await tester.pumpAndSettle();

    expect(saver.saved, hasLength(1));
    expect(saver.saved.single.price, 12.5);
    expect(saver.saved.single.sizes, {'M': 1});
    expect(saver.saved.single.kind, QuickKind.tops);
    expect(find.textContaining('Add the next one'), findsOneWidget);
  });

  testWidgets('after saving the form clears and keeps the kind', (
    tester,
  ) async {
    await _open(tester);

    await tester.tap(find.byKey(const ValueKey('kind_shoes')));
    await tester.pump();
    await _takePhoto(tester);
    await tester.enterText(find.byKey(const ValueKey('price_field')), '20');
    await tester.tap(find.byKey(const ValueKey('size_UK 6')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('quick_add_save')));
    await tester.pumpAndSettle();

    expect(find.text('Quick add · 1 added'), findsOneWidget);
    final price = tester.widget<TextField>(
      find.byKey(const ValueKey('price_field')),
    );
    expect(price.controller!.text, isEmpty);
    // Still on shoes: its UK sizes are offered.
    expect(find.byKey(const ValueKey('size_UK 6')), findsOneWidget);
  });

  testWidgets('the size stepper changes how many', (tester) async {
    await _open(tester);

    await tester.tap(find.byKey(const ValueKey('size_L')));
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('count_L')),
        matching: find.byIcon(Icons.add_circle_outline),
      ),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('count_L')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('an accessory asks how many, not which size', (tester) async {
    await _open(tester);

    await tester.tap(find.byKey(const ValueKey('kind_accessories')));
    await tester.pump();

    expect(find.byKey(const ValueKey('count_one')), findsOneWidget);
    expect(find.byKey(const ValueKey('size_M')), findsNothing);
  });

  testWidgets('a failed save keeps what was typed', (tester) async {
    final saver = _FakeSaver()..failWith = Exception('offline');
    await _open(tester, saver: saver);

    await _takePhoto(tester);
    await tester.enterText(find.byKey(const ValueKey('price_field')), '9');
    await tester.tap(find.byKey(const ValueKey('size_S')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('quick_add_save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not add it'), findsOneWidget);
    expect(find.text('Quick add'), findsOneWidget);
  });
}
