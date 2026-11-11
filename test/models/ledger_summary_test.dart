// Verifies how ledger rows become what a shop owes and an influencer earns.
import 'package:banigoba/modules/shop/models/ledger_summary.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row(
  String kind,
  String status,
  num amount, [
  int n = 1,
]) => {'kind': kind, 'status': status, 'amount': amount, 'entries': n};

void main() {
  test('no rows is an empty summary', () {
    expect(LedgerSummary.fromRows(const []).isEmpty, isTrue);
  });

  test('a shop owes commission by stage and counts its sales', () {
    final summary = LedgerSummary.fromRows([
      _row('seller_commission_owed', 'due', 4.5, 3),
      _row('seller_commission_owed', 'pending', 1.2, 1),
      _row('seller_commission_owed', 'settled', 10, 5),
    ]);

    expect(summary.owedDue, 4.5);
    expect(summary.owedPending, 1.2);
    expect(summary.owedSettled, 10);
    expect(summary.sales, 9);
    expect(summary.earnedDue, 0);
  });

  test('an influencer earns a share by stage', () {
    final summary = LedgerSummary.fromRows([
      _row('influencer_share', 'due', 0.5),
      _row('influencer_share', 'settled', 2),
    ]);

    expect(summary.earnedDue, 0.5);
    expect(summary.earnedSettled, 2);
    expect(summary.owedDue, 0);
  });

  test('cancelled orders count for nothing', () {
    final summary = LedgerSummary.fromRows([
      _row('seller_commission_owed', 'void', 5),
      _row('influencer_share', 'void', 1),
    ]);

    expect(summary.isEmpty, isTrue);
  });
}
