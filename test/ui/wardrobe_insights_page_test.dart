// Verifies the Wardrobe insights screen (W-10).
import 'package:banigoba/ui/screens/wardrobe/wardrobe_insights_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 4);

Map<String, dynamic> _piece(
  String id, {
  String name = 'Blue shirt',
  String category = 'tops',
  int worn = 0,
}) => {
  'id': id,
  'name': name,
  'category': category,
  'subcategory': 'shirts',
  'colours': ['blue'],
  'weatherTags': <String>[],
  'wearCount': worn,
  'createdAt': DateTime(2026, 1, 1).toIso8601String(),
};

Future<void> _open(
  WidgetTester tester,
  Future<List<Map<String, dynamic>>> Function() load,
) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: WardrobeInsightsPage(load: load, now: _now),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an empty wardrobe invites adding pieces', (tester) async {
    await _open(tester, () async => []);

    expect(find.textContaining('Add a few pieces'), findsOneWidget);
  });

  testWidgets('shows favourites, unworn pieces and missing basics', (
    tester,
  ) async {
    await _open(
      tester,
      () async => [
        _piece('a', name: 'Favourite tee', worn: 8),
        _piece('b', name: 'Forgotten top'),
        _piece('c', name: 'Third top'),
      ],
    );

    expect(find.byKey(const ValueKey('insights_headline')), findsOneWidget);
    expect(find.text('Only you can see this.'), findsOneWidget);
    expect(find.byKey(const ValueKey('insight_mostWorn')), findsOneWidget);
    expect(find.text('Favourite tee: worn 8 times'), findsOneWidget);
    expect(find.byKey(const ValueKey('insight_neverWorn')), findsOneWidget);
    expect(find.text('Forgotten top'), findsOneWidget);
    expect(find.byKey(const ValueKey('insight_missingBasics')), findsOneWidget);
    expect(find.text('No shoes yet'), findsOneWidget);
  });

  testWidgets('near-duplicates are named', (tester) async {
    await _open(
      tester,
      () async => [for (var i = 0; i < 3; i++) _piece('s$i', worn: 1)],
    );

    expect(find.text('3 blue shirts'), findsOneWidget);
  });

  testWidgets('a failure says so instead of crashing', (tester) async {
    await _open(tester, () async => throw Exception('offline'));

    expect(find.text('Your wardrobe could not be loaded.'), findsOneWidget);
  });
}
