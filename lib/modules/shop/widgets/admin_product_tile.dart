// One row in the seller's inventory list.
import 'package:flutter/material.dart';

import 'package:banigoba/core/utils/stock_status.dart';
import 'package:banigoba/modules/shop/widgets/safe_product_image.dart';

class AdminProductTile extends StatelessWidget {
  const AdminProductTile({
    super.key,
    required this.product,
    required this.reachText,
    required this.onStock,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> product;

  /// How far the piece got in feeds, or null to show nothing.
  final String? reachText;
  final VoidCallback onStock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static Map<String, int> _sizeInventory(Map<String, dynamic> data) {
    final raw = data['sizeInventory'];
    if (raw is! Map) return <String, int>{};
    final inventory = <String, int>{};
    raw.forEach((key, value) {
      final size = key.toString().trim().toUpperCase();
      final quantity = value is num
          ? value.toInt()
          : int.tryParse(value.toString().trim()) ?? 0;
      if (size.isNotEmpty) inventory[size] = quantity;
    });
    return inventory;
  }

  /// How much of a piece is left, in words, with a colour for the urgent ones.
  Widget _stockLabel(Map<String, dynamic> data, int stock) {
    final (text, color) = switch (stockLevelOf(data)) {
      StockLevel.soldOut => ('Sold out', Colors.red),
      StockLevel.low => ('Only $stock left', const Color(0xFFD9822B)),
      StockLevel.inStock => ('$stock in stock', Colors.green.shade700),
    };
    return Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = product;
    final docId = data['id'].toString();
    final name = data['name'] ?? 'No Name';
    final imageUrl = data['imageUrl'] ?? data['imageURL'] ?? '';
    final rawImageUrl = data['rawImageUrl'] ?? imageUrl;
    final sizeInventory = _sizeInventory(data);
    // For sized items, total stock is derived from the size buckets.
    final stock = sizeInventory.isNotEmpty
        ? sizeInventory.values.fold<int>(0, (total, q) => total + q)
        : (data['stock'] as num?)?.toInt() ?? 0;
    final price = ((data['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(2);
    final sizes = sizeInventory.isEmpty
        ? ''
        : ' • ${sizeInventory.length} sizes';

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SafeProductImage(
          imageUrl: rawImageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          iconSize: 26,
        ),
      ),
      title: Text(name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${data['category'] ?? 'No Category'} • \$$price$sizes"),
          _stockLabel(data, stock),
          if (reachText case final text?)
            Text(
              text,
              key: ValueKey('reach_$docId'),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: ValueKey('stock_$docId'),
            tooltip: 'Change how many are left',
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: onStock,
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
