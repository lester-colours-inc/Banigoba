import 'package:banigoba/ui/widgets/near_me_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  String city = 'Harare',
  bool nearMe = true,
  ValueChanged<bool>? onChanged,
  VoidCallback? onSetCity,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NearMeBar(
          city: city,
          nearMe: nearMe,
          onChanged: onChanged ?? (_) {},
          onSetCity: onSetCity ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('names the city on the Near me chip', (tester) async {
    await _pump(tester);

    expect(find.text('Near me · Harare'), findsOneWidget);
    expect(find.text('Everyone'), findsOneWidget);
    expect(find.byKey(const ValueKey('add_city')), findsNothing);
  });

  testWidgets('switches between Near me and Everyone', (tester) async {
    final chosen = <bool>[];
    await _pump(tester, onChanged: chosen.add);

    await tester.tap(find.byKey(const ValueKey('everyone_chip')));
    await tester.tap(find.byKey(const ValueKey('near_me_chip')));

    expect(chosen, [false, true]);
  });

  testWidgets('asks for a city instead of guessing one', (tester) async {
    var asked = false;
    await _pump(tester, city: '  ', onSetCity: () => asked = true);

    expect(find.text('Near me'), findsOneWidget);
    expect(find.textContaining('Add your city'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add_city')));

    expect(asked, isTrue);
  });
}
