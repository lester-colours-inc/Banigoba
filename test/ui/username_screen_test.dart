// Verifies choosing a @username.
import 'package:banigoba/ui/screens/onboarding/username_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<String>> _open(
  WidgetTester tester, {
  String? suggestion = 'tariro.m',
  Set<String> taken = const {},
}) async {
  final claimed = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: UsernameScreen(
        suggest: () async => suggestion,
        isAvailable: (name) async => !taken.contains(name),
        onClaim: (name) async => claimed.add(name),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return claimed;
}

FilledButton _save(WidgetTester tester) =>
    tester.widget(find.byKey(const ValueKey('username_save')));

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const ValueKey('username_field')), text);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('fills in a suggestion that can be confirmed straight away', (
    tester,
  ) async {
    final claimed = await _open(tester);

    expect(find.text('tariro.m'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('username_save')));
    await tester.pumpAndSettle();
    expect(claimed, ['tariro.m']);
  });

  testWidgets('a taken name cannot be saved', (tester) async {
    await _open(tester, taken: {'rudo'});

    await _type(tester, 'rudo');
    expect(find.text('That username is taken. Try another.'), findsOneWidget);
    expect(_save(tester).onPressed, isNull);
  });

  testWidgets('an invalid name says why and cannot be saved', (tester) async {
    await _open(tester);

    await _type(tester, 'ta');
    expect(find.textContaining('at least'), findsOneWidget);
    expect(_save(tester).onPressed, isNull);
  });

  testWidgets('a free name can be saved, normalised', (tester) async {
    final claimed = await _open(tester, suggestion: null);

    await _type(tester, '@Rudo_99');
    expect(_save(tester).onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('username_save')));
    await tester.pumpAndSettle();
    expect(claimed, ['rudo_99']);
  });
}
