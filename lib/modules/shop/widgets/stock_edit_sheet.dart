// Change how many of a piece are left without opening the full product form
// (review item K-1): a stepper per size, or one for a one-size piece. For a
// flea-market trader who sold two and needs to say so.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/shop/models/quick_add.dart';
import 'package:banigoba/core/utils/size_inventory.dart';

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
    builder: (_) => _StockEditSheet(product: product),
  );
}

class _StockEditSheet extends StatefulWidget {
  const _StockEditSheet({required this.product});

  final Map<String, dynamic> product;

  @override
  State<_StockEditSheet> createState() => _StockEditSheetState();
}

class _StockEditSheetState extends State<_StockEditSheet> {
  late Map<String, int> _sizes = parseSizeInventory(widget.product);
  late int _stock = (widget.product['stock'] as num?)?.toInt() ?? 0;

  bool get _hasSizes => _sizes.isNotEmpty;

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
    final name = (widget.product['name'] ?? 'this piece').toString();
    final sizeKeys = _sizes.keys.toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How many $name are left?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_hasSizes)
              for (final size in sizeKeys)
                _row(
                  ValueKey('stock_$size'),
                  'Size $size',
                  _sizes[size]!,
                  () =>
                      setState(() => _sizes = adjustedStock(_sizes, size, -1)),
                  () => setState(() => _sizes = adjustedStock(_sizes, size, 1)),
                )
            else
              _row(
                const ValueKey('stock_one'),
                'In stock',
                _stock,
                () => setState(() => _stock = _stock > 0 ? _stock - 1 : 0),
                () => setState(() => _stock += 1),
              ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('stock_save'),
              onPressed: () => Navigator.pop(
                context,
                _hasSizes ? StockEdit(sizes: _sizes) : StockEdit(stock: _stock),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
