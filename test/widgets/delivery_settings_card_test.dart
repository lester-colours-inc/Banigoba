import 'package:banigoba/data/models/delivery.dart';
import 'package:banigoba/ui/widgets/delivery_settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  DeliverySettings initial = const DeliverySettings(),
  Future<void> Function(DeliverySettings)? onSave,
}) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DeliverySettingsCard(
            initial: initial,
            onSave: onSave ?? (_) async {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('starts off, with no fields until the shop delivers', (
    tester,
  ) async {
    await _pump(tester);

    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const ValueKey('delivers_switch')))
          .value,
      isFalse,
    );
    expect(find.byKey(const ValueKey('delivery_fee')), findsNothing);
    expect(find.byKey(const ValueKey('delivery_areas')), findsNothing);
  });

  testWidgets('shows what the shop saved before', (tester) async {
    await _pump(
      tester,
      initial: const DeliverySettings(
        delivers: true,
        fee: 3.5,
        areas: ['Avondale', 'Borrowdale'],
        note: 'Same day',
      ),
    );

    expect(find.widgetWithText(TextField, '3.50'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Avondale, Borrowdale'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, 'Same day'), findsOneWidget);
  });

  testWidgets('saves what was typed, cleaned', (tester) async {
    DeliverySettings? saved;
    await _pump(tester, onSave: (settings) async => saved = settings);

    await tester.tap(find.byKey(const ValueKey('delivers_switch')));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('delivery_fee')), '2,5');
    await tester.enterText(
      find.byKey(const ValueKey('delivery_areas')),
      ' Avondale, avondale ,Borrowdale,, ',
    );
    await tester.tap(find.byKey(const ValueKey('save_delivery')));
    await tester.pumpAndSettle();

    expect(saved?.delivers, isTrue);
    expect(saved?.fee, 2.5);
    expect(saved?.areas, ['Avondale', 'Borrowdale']);
  });

  testWidgets('a blank fee means free delivery', (tester) async {
    DeliverySettings? saved;
    await _pump(tester, onSave: (settings) async => saved = settings);

    await tester.tap(find.byKey(const ValueKey('delivers_switch')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save_delivery')));
    await tester.pumpAndSettle();

    expect(saved?.fee, 0);
    expect(saved?.areas, isEmpty);
  });

  testWidgets('a fee that is not a number is refused, nothing saved', (
    tester,
  ) async {
    var saves = 0;
    await _pump(tester, onSave: (_) async => saves += 1);

    await tester.tap(find.byKey(const ValueKey('delivers_switch')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('delivery_fee')),
      'two dollars',
    );
    await tester.tap(find.byKey(const ValueKey('save_delivery')));
    await tester.pump();

    expect(saves, 0);
    expect(find.textContaining('Enter the fee'), findsOneWidget);
  });

  testWidgets('switching delivery off saves it as off', (tester) async {
    DeliverySettings? saved;
    await _pump(
      tester,
      initial: const DeliverySettings(
        delivers: true,
        fee: 3,
        areas: ['Avondale'],
      ),
      onSave: (settings) async => saved = settings,
    );

    await tester.tap(find.byKey(const ValueKey('delivers_switch')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save_delivery')));
    await tester.pumpAndSettle();

    expect(saved?.delivers, isFalse);
  });

  testWidgets('says when saving failed', (tester) async {
    await _pump(tester, onSave: (_) async => throw Exception('offline'));

    await tester.tap(find.byKey(const ValueKey('save_delivery')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not save'), findsOneWidget);
  });
}
