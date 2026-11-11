// One line in the cart: picture, name, size and price, with quantity buttons.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/shop/widgets/safe_product_image.dart';

class CartLineTile extends StatelessWidget {
  const CartLineTile({
    super.key,
    required this.line,
    required this.price,
    required this.onQuantity,
  });

  final Map<String, dynamic> line;
  final double price;
  final ValueChanged<int> onQuantity;

  @override
  Widget build(BuildContext context) {
    final quantity = (line['quantity'] as num?)?.toInt() ?? 1;
    final imageUrl =
        (line['rawImageUrl'] ?? line['imageUrl'] ?? line['imageURL'] ?? '')
            .toString();
    final selectedSize = (line['selectedSize'] ?? '').toString();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
        width: 58,
        child: SafeProductImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          iconSize: 28,
        ),
      ),
      title: Text((line['name'] ?? 'Product').toString()),
      subtitle: Text(
        selectedSize.isEmpty
            ? '\$${price.toStringAsFixed(2)}'
            : 'Size $selectedSize • \$${price.toStringAsFixed(2)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => onQuantity(quantity - 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$quantity'),
          IconButton(
            onPressed: () => onQuantity(quantity + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
