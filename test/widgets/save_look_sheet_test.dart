import 'package:banigoba/ui/widgets/save_look_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpSheet(WidgetTester tester, {required bool canReplace}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SaveLookSheet(canReplace: canReplace)),
      ),
    );

void main() {
  testWidgets('a new look can be kept private, saved to wardrobe, or shared', (
    tester,
  ) async {
    await _pumpSheet(tester, canReplace: false);

    expect(find.byKey(const ValueKey('save_look_replace')), findsNothing);
    expect(find.text('Save to My Timeline'), findsOneWidget);
    expect(find.byKey(const ValueKey('save_look_wardrobe')), findsOneWidget);
    expect(find.byKey(const ValueKey('save_look_friends')), findsOneWidget);
    expect(find.byKey(const ValueKey('save_look_community')), findsOneWidget);
  });

  testWidgets('an edited look can update the original', (tester) async {
    await _pumpSheet(tester, canReplace: true);

    expect(find.text('Update the original'), findsOneWidget);
    expect(find.text('Save as a new look'), findsOneWidget);
  });

  testWidgets('tapping Save to Wardrobe returns that choice', (tester) async {
    SaveLookVisibility? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              picked = await showModalBottomSheet<SaveLookVisibility>(
                context: context,
                builder: (_) => const SaveLookSheet(),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save_look_wardrobe')));
    await tester.pumpAndSettle();

    expect(picked, SaveLookVisibility.wardrobe);
  });
}
