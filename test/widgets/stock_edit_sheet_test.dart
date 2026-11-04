// Verifies changing the stock of a piece without the full form (K-1).
import 'package:banigoba/ui/widgets/stock_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<StockEdit?> _run(
  WidgetTester tester,
  Map<String, dynamic> product,
  Future<void> Function() act,
) async {
  StockEdit? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async =>
                  result = await showStockEditSheet(context, product),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await act();
  return result;
}

void main() {
  testWidgets('a sized piece shows a stepper per size and saves counts', (
    tester,
  ) async {
    final result = await _run(
      tester,
      {
        'name': 'Dress',
        'sizeInventory': {'M': 2, 'L': 0},
      },
      () async {
        expect(find.byKey(const ValueKey('stock_M')), findsOneWidget);
        expect(find.byKey(const ValueKey('stock_L')), findsOneWidget);
        // Sold one M, and restocked two L.
        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('stock_M')),
            matching: find.byIcon(Icons.remove_circle_outline),
          ),
        );
        for (var i = 0; i < 2; i++) {
          await tester.tap(
            find.descendant(
              of: find.byKey(const ValueKey('stock_L')),
              matching: find.byIcon(Icons.add_circle_outline),
            ),
          );
        }
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('stock_save')));
        await tester.pumpAndSettle();
      },
    );

    expect(result?.sizes, {'M': 1, 'L': 2});
    expect(result?.stock, isNull);
  });

  testWidgets('a one-size piece edits a single count and never goes negative', (
    tester,
  ) async {
    final result = await _run(tester, {'name': 'Scarf', 'stock': 1}, () async {
      final minus = find.descendant(
        of: find.byKey(const ValueKey('stock_one')),
        matching: find.byIcon(Icons.remove_circle_outline),
      );
      await tester.tap(minus);
      await tester.pump();
      // At zero the minus button is switched off.
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(of: minus, matching: find.byType(IconButton)),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('stock_save')));
      await tester.pumpAndSettle();
    });

    expect(result?.stock, 0);
    expect(result?.sizes, isNull);
  });
}
