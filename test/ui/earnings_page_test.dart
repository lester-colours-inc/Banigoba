// Verifies the Earnings screen shows what a shop owes and an influencer earns.
import 'package:banigoba/data/models/ledger_summary.dart';
import 'package:banigoba/data/services/ledger_service.dart';
import 'package:banigoba/ui/screens/provider/earnings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLedger implements LedgerSource {
  _FakeLedger(this.summary);
  final LedgerSummary summary;

  @override
  Future<LedgerSummary> mine() async => summary;
}

Future<void> _open(WidgetTester tester, LedgerSummary summary) async {
  await tester.pumpWidget(
    MaterialApp(home: EarningsPage(source: _FakeLedger(summary))),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an empty ledger says nothing yet', (tester) async {
    await _open(tester, const LedgerSummary());

    expect(find.textContaining('Nothing yet'), findsOneWidget);
  });

  testWidgets('a shop sees the commission it owes', (tester) async {
    await _open(
      tester,
      const LedgerSummary(owedDue: 4.5, owedPending: 1.2, sales: 3),
    );

    expect(find.byKey(const ValueKey('owed_section')), findsOneWidget);
    expect(find.byKey(const ValueKey('earned_section')), findsNothing);
    expect(find.text('\$4.50'), findsOneWidget);
    expect(find.text('\$1.20'), findsOneWidget);
    expect(find.textContaining('3 sales'), findsOneWidget);
  });

  testWidgets('an influencer sees their referral earnings', (tester) async {
    await _open(tester, const LedgerSummary(earnedDue: 0.5));

    expect(find.byKey(const ValueKey('earned_section')), findsOneWidget);
    expect(find.byKey(const ValueKey('owed_section')), findsNothing);
  });
}
