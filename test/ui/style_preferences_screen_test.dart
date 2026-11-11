import 'package:banigoba/modules/onboarding/models/style_preferences.dart';
import 'package:banigoba/modules/onboarding/views/style_preferences_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('saves the chosen styles and makeover focus', (tester) async {
    StylePreferences? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: StylePreferencesScreen(
          onSave: (answers) async => saved = answers,
          onSkip: () async {},
        ),
      ),
    );

    await tester.tap(find.text('Traditional'));
    await tester.tap(find.text('Casual'));
    await tester.tap(find.text('Hair only'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('preferences_save')));
    await tester.pump();

    // Stored in option order, not tap order.
    expect(saved?.styles, ['Casual', 'Traditional']);
    expect(saved?.focus, MakeoverFocus.hair);
  });

  testWidgets('can continue without answering anything', (tester) async {
    StylePreferences? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: StylePreferencesScreen(
          onSave: (answers) async => saved = answers,
          onSkip: () async {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('preferences_save')));
    await tester.pump();

    expect(saved?.isEmpty, isTrue);
  });

  testWidgets('first run offers Skip for now', (tester) async {
    var skipped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StylePreferencesScreen(
          onSave: (_) async {},
          onSkip: () async => skipped = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('preferences_skip')));
    await tester.pump();

    expect(skipped, isTrue);
  });

  testWidgets('from Settings there is no Skip and answers are prefilled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StylePreferencesScreen(
          isFirstRun: false,
          initial: const StylePreferences(
            styles: ['Elegant'],
            focus: MakeoverFocus.outfit,
          ),
          onSave: (_) async {},
          onSkip: () async {},
        ),
      ),
    );

    expect(find.byKey(const ValueKey('preferences_skip')), findsNothing);
    final elegant = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Elegant'),
    );
    final outfit = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Outfit only'),
    );
    expect(elegant.selected, isTrue);
    expect(outfit.selected, isTrue);
  });
}
