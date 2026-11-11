// Earnings: loads the signed-in provider's ledger and refreshes it.
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/models/ledger_summary.dart';
import 'package:banigoba/modules/shop/services/ledger_service.dart';

class EarningsController extends GetxController {
  EarningsController({LedgerSource? source})
    : _source = source ?? LedgerService();

  final LedgerSource _source;

  /// Null until the first load finishes.
  final Rxn<LedgerSummary> summary = Rxn<LedgerSummary>();
  final RxBool failed = false.obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    try {
      final loaded = await _source.mine();
      if (isClosed) return;
      failed.value = false;
      summary.value = loaded;
    } on Object {
      if (!isClosed) failed.value = true;
    }
  }
}
