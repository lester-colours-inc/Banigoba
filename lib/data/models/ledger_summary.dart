// What a person owes the platform, and what the platform owes them (K-7).
//
// Built from the ledger: a shop owes Banigoba the commission on each sale (the
// buyer pays the shop directly), and an influencer is owed a share of the
// commission on sales they brought in. Money on an order that is still open is
// "pending"; once the order is collected or delivered it is "due"; "settled"
// means it has been paid.
import 'package:flutter/foundation.dart';

@immutable
class LedgerSummary {
  const LedgerSummary({
    this.owedDue = 0,
    this.owedPending = 0,
    this.owedSettled = 0,
    this.earnedDue = 0,
    this.earnedPending = 0,
    this.earnedSettled = 0,
    this.sales = 0,
  });

  /// Commission a shop owes Banigoba.
  final double owedDue;
  final double owedPending;
  final double owedSettled;

  /// Referral share Banigoba owes an influencer.
  final double earnedDue;
  final double earnedPending;
  final double earnedSettled;

  /// How many sales the entries come from.
  final int sales;

  bool get isEmpty =>
      owedDue +
          owedPending +
          owedSettled +
          earnedDue +
          earnedPending +
          earnedSettled ==
      0;

  /// Reads the rows of `my_ledger_summary` ({kind, status, entries, amount}).
  factory LedgerSummary.fromRows(Iterable<Map<String, dynamic>> rows) {
    var owedDue = 0.0, owedPending = 0.0, owedSettled = 0.0;
    var earnedDue = 0.0, earnedPending = 0.0, earnedSettled = 0.0;
    var sales = 0;
    for (final row in rows) {
      final amount = (row['amount'] as num?)?.toDouble() ?? 0;
      final owed = row['kind'] == 'seller_commission_owed';
      final earned = row['kind'] == 'influencer_share';
      final status = row['status'];
      if (status == 'void' || (!owed && !earned)) continue;
      if (owed) sales += (row['entries'] as num?)?.toInt() ?? 0;
      switch (status) {
        case 'due':
          if (owed)
            owedDue += amount;
          else
            earnedDue += amount;
        case 'pending':
          if (owed)
            owedPending += amount;
          else
            earnedPending += amount;
        case 'settled':
          if (owed)
            owedSettled += amount;
          else
            earnedSettled += amount;
      }
    }
    return LedgerSummary(
      owedDue: owedDue,
      owedPending: owedPending,
      owedSettled: owedSettled,
      earnedDue: earnedDue,
      earnedPending: earnedPending,
      earnedSettled: earnedSettled,
      sales: sales,
    );
  }
}
