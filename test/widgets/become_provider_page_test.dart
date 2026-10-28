import 'package:banigoba/data/models/provider_roles.dart';
import 'package:banigoba/ui/screens/provider/become_provider_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {List<ProviderRole> held = const []}) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      home: BecomeProviderPage(held: held, suggestedName: 'Glow'),
    ),
  );
}

void main() {
  testWidgets('offers shop, designer and salon', (tester) async {
    await _pump(tester);

    for (final role in ProviderRole.values) {
      expect(find.byKey(ValueKey('role_${role.key}')), findsOneWidget);
    }
  });

  testWidgets('asks for at least one role before starting', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('start_provider')));
    await tester.pump();

    expect(find.text('Tick at least one thing you offer.'), findsOneWidget);
  });

  testWidgets('asks for a business name', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('role_shop')));
    await tester.enterText(find.byKey(const ValueKey('business_name')), '  ');
    await tester.tap(find.byKey(const ValueKey('start_provider')));
    await tester.pump();

    expect(find.text('Enter your business name.'), findsOneWidget);
  });

  testWidgets('shows a role already held as set up and locked', (tester) async {
    await _pump(tester, held: [ProviderRole.designer]);

    expect(find.text('Already set up'), findsOneWidget);
    final tile = tester.widget<CheckboxListTile>(
      find.byKey(const ValueKey('role_designer')),
    );
    expect(tile.value, isTrue);
    expect(tile.onChanged, isNull);
  });

  testWidgets('starts with the name the user already goes by', (tester) async {
    await _pump(tester);

    expect(find.text('Glow'), findsOneWidget);
  });
}
