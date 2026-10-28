import 'package:banigoba/ui/widgets/near_me_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  String city = 'Harare',
  bool nearMe = true,
  ValueChanged<bool>? onChanged,
  VoidCallback? onSetCity,
  bool hasLocation = false,
  VoidCallback? onUseLocation,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NearMeBar(
          city: city,
          nearMe: nearMe,
          onChanged: onChanged ?? (_) {},
          onSetCity: onSetCity ?? () {},
          hasLocation: hasLocation,
          onUseLocation: onUseLocation ?? () {},
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
    expect(find.textContaining('where you are'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add_city')));

    expect(asked, isTrue);
  });

  testWidgets('says it is using the phone\'s location when it is', (
    tester,
  ) async {
    await _pump(tester, city: '', hasLocation: true);

    expect(find.text('Near me · your area'), findsOneWidget);
    expect(find.byKey(const ValueKey('use_location')), findsNothing);
    expect(find.byKey(const ValueKey('add_city')), findsNothing);
  });

  testWidgets('offers both ways to say where you are when neither is set', (
    tester,
  ) async {
    var located = false;
    var asked = false;
    await _pump(
      tester,
      city: '',
      onUseLocation: () => located = true,
      onSetCity: () => asked = true,
    );

    await tester.tap(find.byKey(const ValueKey('use_location')));
    await tester.tap(find.byKey(const ValueKey('add_city')));

    expect(located, isTrue);
    expect(asked, isTrue);
  });

  testWidgets('with a city but no location, offers the phone\'s location', (
    tester,
  ) async {
    await _pump(tester, city: 'Harare');

    expect(find.byKey(const ValueKey('use_location')), findsOneWidget);
    expect(find.byKey(const ValueKey('add_city')), findsNothing);
  });
}
