// Change how many of a piece are left without opening the full product form
// (review item K-1): a stepper per size, or one for a one-size piece. For a
// flea-market trader who sold two and needs to say so.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/stock_edit_controller.dart';

/// The new counts the trader chose: per size, or just [stock] for a one-size
/// piece.
class StockEdit {
  const StockEdit({this.sizes, this.stock});

  final Map<String, int>? sizes;
  final int? stock;
}

/// Opens the editor for [product]; null when cancelled.
Future<StockEdit?> showStockEditSheet(
  BuildContext context,
  Map<String, dynamic> product,
) {
  return showModalBottomSheet<StockEdit>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => GetBuilder<StockEditController>(
      init: StockEditController(product),
      global: false,
      builder: (controller) => _StockEditSheet(controller: controller),
    ),
  );
}

class _StockEditSheet extends StatelessWidget {
  const _StockEditSheet({required this.controller});

  final StockEditController controller;

  Widget _row(
    Key key,
    String label,
    int count,
    VoidCallback minus,
    VoidCallback plus,
  ) {
    return Row(
      key: key,
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        IconButton(
          onPressed: count > 0 ? minus : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$count',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(onPressed: plus, icon: const Icon(Icons.add_circle_outline)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (controller.product['name'] ?? 'this piece').toString();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Obx(() {
          final sizes = controller.sizes.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How many $name are left?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (controller.hasSizes)
                for (final size in sizes.keys)
                  _row(
                    ValueKey('stock_$size'),
                    'Size $size',
                    sizes[size]!,
                    () => controller.adjustSize(size, -1),
                    () => controller.adjustSize(size, 1),
                  )
              else
                _row(
                  const ValueKey('stock_one'),
                  'In stock',
                  controller.stock.value,
                  () => controller.adjustOne(-1),
                  () => controller.adjustOne(1),
                ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('stock_save'),
                onPressed: () => Navigator.pop(context, controller.result()),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Save'),
              ),
            ],
          );
        }),
      ),
    );
  }
}
