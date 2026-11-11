// The stock sheet's counts: per size, or one for a one-size piece.
import 'package:get/get.dart';

import 'package:banigoba/core/utils/size_inventory.dart';
import 'package:banigoba/modules/shop/models/quick_add.dart';
import 'package:banigoba/modules/shop/widgets/stock_edit_sheet.dart';

class StockEditController extends GetxController {
  StockEditController(this.product);

  final Map<String, dynamic> product;

  late final Rx<Map<String, int>> sizes = Rx(parseSizeInventory(product));
  late final RxInt stock = ((product['stock'] as num?)?.toInt() ?? 0).obs;

  bool get hasSizes => sizes.value.isNotEmpty;

  void adjustSize(String size, int delta) =>
      sizes.value = adjustedStock(sizes.value, size, delta);

  void adjustOne(int delta) {
    final next = stock.value + delta;
    stock.value = next < 0 ? 0 : next;
  }

  StockEdit result() =>
      hasSizes ? StockEdit(sizes: sizes.value) : StockEdit(stock: stock.value);
}
