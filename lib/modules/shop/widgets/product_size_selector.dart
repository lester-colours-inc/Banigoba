// The size chips on the product detail screen.
import 'package:flutter/material.dart';

class ProductSizeSelector extends StatelessWidget {
  const ProductSizeSelector({
    super.key,
    required this.sizes,
    required this.selected,
    required this.onSelected,
  });

  /// Sizes with stock. The customer only sees labels; quantities stay hidden
  /// but still drive stock checks when adding to cart and placing an order.
  final List<String> sizes;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Size:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (sizes.isEmpty)
            Text(
              'No sizes available',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final size in sizes)
                  ChoiceChip(
                    label: Text(size),
                    selected: selected == size,
                    onSelected: (_) => onSelected(size),
                    selectedColor: const Color(
                      0xFF0D0140,
                    ).withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: selected == size ? const Color(0xFF0D0140) : null,
                      fontWeight: selected == size
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
