// Verifies the affirmation row: no empty text for the owner, and a total
// that only the look's owner ever sees (H-4, BNG SRS 001).
import 'package:banigoba/data/models/affirmation.dart';
import 'package:banigoba/data/services/affirmation_service.dart';
import 'package:banigoba/ui/widgets/affirmation_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAffirmations implements AffirmationService {
  _FakeAffirmations(this.facets);

  final List<AffirmationFacet> facets;

  @override
  Stream<List<AffirmationFacet>> watchFacetsForTarget({
    required AffirmationTargetType targetType,
    required String targetId,
  }) => Stream.value(facets);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _facets = [
  AffirmationFacet(
    definitionId: 'regal',
    emoji: '👑',
    shortLabel: 'Regal',
    category: AffirmationCategory.characterAndBearing,
    senderCount: 3,
  ),
  AffirmationFacet(
    definitionId: 'fresh',
    emoji: '✨',
    shortLabel: 'Fresh',
    category: AffirmationCategory.styleAndOriginality,
    senderCount: 2,
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required String viewer,
  List<AffirmationFacet> facets = _facets,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AffirmationRow(
          targetType: AffirmationTargetType.post,
          targetId: 'post-1',
          targetOwnerId: 'owner',
          currentUserId: viewer,
          ownerName: 'Tariro',
          showAction: false,
          service: _FakeAffirmations(facets),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('the owner sees the total of affirmations received', (
    tester,
  ) async {
    await _pump(tester, viewer: 'owner');

    expect(
      find.byKey(const ValueKey('affirmation_owner_total')),
      findsOneWidget,
    );
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('everyone else sees which affirmations, never a number', (
    tester,
  ) async {
    await _pump(tester, viewer: 'someone-else');

    expect(find.text('Regal'), findsOneWidget);
    expect(find.byKey(const ValueKey('affirmation_owner_total')), findsNothing);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('no "No affirmations yet" text for the owner', (tester) async {
    await _pump(tester, viewer: 'owner', facets: const []);

    expect(find.textContaining('No affirmations yet'), findsNothing);
    expect(find.byKey(const ValueKey('affirmation_owner_total')), findsNothing);
  });

  test('the private total adds up every sender', () {
    expect(privateReceivedTotal(_facets), 5);
    expect(privateReceivedTotal(const []), 0);
  });
}
