// Earnings (K-7): what the signed-in provider owes Banigoba in commission, and
// what they are owed for sales they brought in. Money on an open order is
// pending, becomes due when the order is collected or delivered, and is
// settled once paid.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/shop/models/ledger_summary.dart';
import 'package:banigoba/modules/shop/services/ledger_service.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key, LedgerSource? source}) : _source = source;

  final LedgerSource? _source;

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  late Future<LedgerSummary> _summary = _load();

  Future<LedgerSummary> _load() => (widget._source ?? LedgerService()).mine();

  static String _money(double value) => '\$${value.toStringAsFixed(2)}';

  Future<void> _refresh() async {
    setState(() => _summary = _load());
    await _summary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: FutureBuilder<LedgerSummary>(
        future: _summary,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Earnings could not be loaded.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final summary = snapshot.data!;
          if (summary.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Nothing yet. Your sales and referral earnings will show '
                  'here once an order comes in.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (summary.owedDue +
                        summary.owedPending +
                        summary.owedSettled >
                    0)
                  _Section(
                    key: const ValueKey('owed_section'),
                    title: 'Commission you owe Banigoba',
                    note:
                        'Buyers pay you directly. Banigoba adds a service '
                        'fee on top of your price and you pass it on. '
                        '${summary.sales} '
                        '${summary.sales == 1 ? 'sale' : 'sales'} so far.',
                    due: _money(summary.owedDue),
                    pending: _money(summary.owedPending),
                    settled: _money(summary.owedSettled),
                  ),
                if (summary.earnedDue +
                        summary.earnedPending +
                        summary.earnedSettled >
                    0)
                  _Section(
                    key: const ValueKey('earned_section'),
                    title: 'Your referral earnings',
                    note:
                        'Your share of the commission on sales your posts and '
                        'links brought in.',
                    due: _money(summary.earnedDue),
                    pending: _money(summary.earnedPending),
                    settled: _money(summary.earnedSettled),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.title,
    required this.note,
    required this.due,
    required this.pending,
    required this.settled,
  });

  final String title;
  final String note;
  final String due;
  final String pending;
  final String settled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget line(String label, String value, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(note, style: TextStyle(color: colors.onSurfaceVariant)),
            const Divider(height: 24),
            line('Due now (finished orders)', due, bold: true),
            line('Coming (open orders)', pending),
            line('Settled', settled),
          ],
        ),
      ),
    );
  }
}
