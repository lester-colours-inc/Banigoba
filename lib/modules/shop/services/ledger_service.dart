// Reads the signed-in person's own ledger (see models/ledger_summary.dart).
import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/modules/shop/models/ledger_summary.dart';

abstract interface class LedgerSource {
  Future<LedgerSummary> mine();
}

class LedgerService implements LedgerSource {
  @override
  Future<LedgerSummary> mine() async {
    final rows = await supabase.rpc('my_ledger_summary');
    return LedgerSummary.fromRows([
      for (final row in rows as List) Map<String, dynamic>.from(row as Map),
    ]);
  }
}
