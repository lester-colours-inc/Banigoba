// Verifies moving a saved look to another category (W-6).
import 'package:banigoba/modules/makeover/widgets/change_look_category_sheet.dart';
import 'package:banigoba/modules/wardrobe/widgets/saved_to_wardrobe_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<String?> _open(
  WidgetTester tester, {
  List<String> existing = const ['Church', 'Work'],
  String current = 'Work',
  String noun = 'category',
  String subject = 'look',
  required Future<void> Function() interact,
}) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  String? result = 'not closed';
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showChangeLookCategorySheet(
            context,
            existingCategories: existing,
            currentCategory: current,
            noun: noun,
            subject: subject,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await interact();
  await tester.pumpAndSettle();
  return result;
}

FilledButton _save(WidgetTester tester) =>
    tester.widget(find.byKey(const ValueKey('move_category_save')));

void main() {
  test('categoryOptions: own categories A to Z, plus the current one', () {
    expect(categoryOptions(['Work', 'Church'], 'Weekend'), [
      'Church',
      'Weekend',
      'Work',
    ]);
  });

  test('categoryOptions offers starters only when there is nothing yet', () {
    expect(categoryOptions(const [], ''), kStarterLookCategories);
    expect(categoryOptions(const [], 'Gym'), ['Gym']);
  });

  testWidgets('shows where the look is now and cannot save until changed', (
    tester,
  ) async {
    await _open(
      tester,
      interact: () async {
        expect(find.text('Now in "Work".'), findsOneWidget);
        expect(_save(tester).onPressed, isNull);
      },
    );
  });

  testWidgets('picking another category moves the look there', (tester) async {
    final result = await _open(
      tester,
      interact: () async {
        await tester.tap(find.byKey(const ValueKey('move_category_Church')));
        await tester.pump();
        expect(find.text('Move to Church'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('move_category_save')));
      },
    );
    expect(result, 'Church');
  });

  testWidgets('a new typed category wins over a chip', (tester) async {
    final result = await _open(
      tester,
      interact: () async {
        await tester.enterText(
          find.byKey(const ValueKey('move_category_new')),
          ' Graduation ',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('move_category_save')));
      },
    );
    expect(result, 'Graduation');
  });

  testWidgets('"No category" returns an empty string to clear it', (
    tester,
  ) async {
    final result = await _open(
      tester,
      interact: () async {
        await tester.tap(find.byKey(const ValueKey('move_category_none')));
        await tester.pump();
        expect(find.text('Remove from category'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('move_category_save')));
      },
    );
    expect(result, '');
  });

  testWidgets('a look with no category starts on "No category"', (
    tester,
  ) async {
    await _open(
      tester,
      current: '',
      interact: () async {
        expect(find.text('This look has no category yet.'), findsOneWidget);
        expect(_save(tester).onPressed, isNull);
      },
    );
  });

  testWidgets('for clothes it talks about collections and pieces', (
    tester,
  ) async {
    await _open(
      tester,
      noun: 'collection',
      subject: 'piece',
      current: '',
      interact: () async {
        expect(find.text('Move to a collection'), findsOneWidget);
        expect(find.text('This piece has no collection yet.'), findsOneWidget);
        expect(find.text('No collection'), findsOneWidget);
        expect(find.text('Or make a new collection'), findsOneWidget);
      },
    );
  });
}
