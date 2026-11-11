// Verifies the sheet shown after saving a look to the Smart Wardrobe.
import 'package:banigoba/modules/wardrobe/widgets/saved_looks_grid.dart';
import 'package:banigoba/modules/wardrobe/widgets/saved_to_wardrobe_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<String?> _open(
  WidgetTester tester, {
  List<String> categories = const [],
  VoidCallback? onOpenWardrobe,
  required Future<void> Function() interact,
}) async {
  String? result = 'not closed';
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showSavedToWardrobeSheet(
            context,
            existingCategories: categories,
            onOpenWardrobe: onOpenWardrobe ?? () {},
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

void main() {
  testWidgets('says where the look went and offers starter categories', (
    tester,
  ) async {
    await _open(
      tester,
      interact: () async {
        expect(find.text('Saved to My Smart Wardrobe'), findsOneWidget);
        expect(find.textContaining('Saved Looks'), findsOneWidget);
        for (final name in kStarterLookCategories) {
          expect(find.text(name), findsOneWidget);
        }
      },
    );
  });

  testWidgets('picking a category returns it', (tester) async {
    final result = await _open(
      tester,
      categories: const ['Church', 'Work'],
      interact: () async {
        await tester.tap(find.text('Work'));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('save_look_category')));
      },
    );
    expect(result, 'Work');
  });

  testWidgets('a typed new category wins over a picked one', (tester) async {
    final result = await _open(
      tester,
      categories: const ['Work'],
      interact: () async {
        await tester.tap(find.text('Work'));
        await tester.enterText(
          find.byKey(const ValueKey('look_category_new')),
          ' Graduation ',
        );
        await tester.pump();
        expect(find.text('Add to Graduation'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('save_look_category')));
      },
    );
    expect(result, 'Graduation');
  });

  testWidgets('View in wardrobe closes the sheet and opens the wardrobe', (
    tester,
  ) async {
    var opened = false;
    await _open(
      tester,
      onOpenWardrobe: () => opened = true,
      interact: () async =>
          tester.tap(find.byKey(const ValueKey('open_wardrobe'))),
    );
    expect(opened, isTrue);
    expect(find.text('Saved to My Smart Wardrobe'), findsNothing);
  });

  group('groupLooksByCategory', () {
    test('groups A to Z, uncategorised last, skipping looks with no image', () {
      final groups = groupLooksByCategory([
        {'imageUrl': 'a', 'category': 'Work'},
        {'imageUrl': 'b'},
        {'imageUrl': 'c', 'category': 'Church'},
        {'imageUrl': '', 'category': 'Work'},
      ]);
      expect(groups.keys, ['Church', 'Work', kUncategorisedLooks]);
      expect(groups['Work'], hasLength(1));
    });
  });
}
