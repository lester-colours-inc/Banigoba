// Small cards on the avatar try-on page: the chosen items and the avatar and
// clothing pictures.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/makeover/models/try_on_prompt.dart';
import 'package:banigoba/modules/shop/widgets/safe_product_image.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

class SelectedOutfitStrip extends StatelessWidget {
  const SelectedOutfitStrip({super.key, required this.products});

  final List<Map<String, dynamic>> products;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Selected outfit',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final product = products[index];
              return Container(
                width: 82,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SafeProductImage(
                        imageUrl: tryOnProductImageUrl(product),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        iconSize: 28,
                      ),
                    ),
                    Text(
                      (product['name'] ?? 'Clothing').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class TryOnImageCard extends StatelessWidget {
  const TryOnImageCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.emptyText,
  });

  final String title;
  final String? imageUrl;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: 230,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: url == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(emptyText, textAlign: TextAlign.center),
                  ),
                )
              : AppNetworkImage(
                  url,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  fallback: const Center(
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
        ),
      ],
    );
  }
}
