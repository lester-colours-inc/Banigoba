// Presents catalog and wardrobe products for building an avatar outfit.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/services/product_service.dart';

Future<List<Map<String, dynamic>>?> showTryOnProductPicker(
  BuildContext context, {
  List<Map<String, dynamic>> initialProducts = const [],
  String outfitLabel = 'Outfit',
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
    return null;
  }

  final productService = ProductService();
  final productsFuture = Future.wait([
    productService.getCatalogProducts(),
    productService.getWardrobeProducts(user.uid),
  ]);

  if (!context.mounted) return null;
  return showModalBottomSheet<List<Map<String, dynamic>>>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      var source = initialProducts.isEmpty ? 0 : 2;
      var category = 'all';
      final selected = <String, Map<String, dynamic>>{};
      for (final product in initialProducts) {
        selected[_productGroup(product)] = product;
      }

      return StatefulBuilder(
        builder: (context, setModalState) {
          final colors = Theme.of(context).colorScheme;
          return FractionallySizedBox(
            heightFactor: 0.9,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 8, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Build Your Look',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Choose products, then complete the look.'),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SegmentedButton<int>(
                      segments: [
                        const ButtonSegment(
                          value: 0,
                          icon: Icon(Icons.storefront_outlined),
                          label: Text('Catalog'),
                        ),
                        const ButtonSegment(
                          value: 1,
                          icon: Icon(Icons.favorite_outline),
                          label: Text('My Wardrobe'),
                        ),
                        if (initialProducts.isNotEmpty)
                          ButtonSegment(
                            value: 2,
                            icon: const Icon(Icons.checkroom_outlined),
                            label: Text(outfitLabel),
                          ),
                      ],
                      selected: {source},
                      onSelectionChanged: (value) {
                        setModalState(() {
                          source = value.first;
                          category = 'all';
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        for (final option in const [
                          ('all', 'All', Icons.grid_view_rounded),
                          ('tops', 'Tops', Icons.checkroom_outlined),
                          ('bottoms', 'Bottoms', Icons.dry_cleaning_outlined),
                          ('dresses', 'Dresses', Icons.woman_2_outlined),
                          ('accessories', 'Accessories', Icons.watch_outlined),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(option.$2),
                              avatar: Icon(option.$3, size: 18),
                              selected: category == option.$1,
                              onSelected: (_) {
                                setModalState(() => category = option.$1);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: FutureBuilder<List<List<Map<String, dynamic>>>>(
                      future: productsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Unable to load products: ${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        final sourceProducts = source == 2
                            ? initialProducts
                            : snapshot.data?[source] ?? const [];
                        final products = sourceProducts
                            .where(
                              (product) =>
                                  category == 'all' ||
                                  _productGroup(product) == category,
                            )
                            .toList();
                        if (products.isEmpty) {
                          return Center(
                            child: Text(
                              source == 0
                                  ? 'No products in this category.'
                                  : source == 1
                                  ? 'No favourited products in this category.'
                                  : 'No outfit products in this category.',
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            final group = _productGroup(product);
                            final imageUrl = _imageUrl(product);
                            final isSelected =
                                selected[group] != null &&
                                _imageUrl(selected[group]!) == imageUrl;
                            return InkWell(
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    selected.remove(group);
                                  } else {
                                    if (group == 'dresses') {
                                      selected.remove('tops');
                                      selected.remove('bottoms');
                                    } else if (group == 'tops' ||
                                        group == 'bottoms') {
                                      selected.remove('dresses');
                                    }
                                    selected[group] = product;
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? colors.primary
                                        : colors.outlineVariant,
                                    width: isSelected ? 3 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(
                                            imageUrl,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, _, _) =>
                                                const Icon(
                                                  Icons.broken_image_outlined,
                                                ),
                                          ),
                                          if (isSelected)
                                            const Positioned(
                                              top: 8,
                                              right: 8,
                                              child: CircleAvatar(
                                                radius: 14,
                                                child: Icon(
                                                  Icons.check,
                                                  size: 17,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        (product['name'] ?? 'Clothing')
                                            .toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton.icon(
                        onPressed: selected.isEmpty
                            ? null
                            : () => Navigator.pop(
                                sheetContext,
                                selected.values.toList(),
                              ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(
                          selected.isEmpty
                              ? 'Select products'
                              : 'Complete Look (${selected.length})',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

String _productGroup(Map<String, dynamic> product) {
  final value = '${product['category'] ?? ''} ${product['subcategory'] ?? ''}'
      .toLowerCase();
  if (value.contains('dress') ||
      value.contains('jumpsuit') ||
      value.contains('one-piece')) {
    return 'dresses';
  }
  if (value.contains('bottom') ||
      value.contains('pants') ||
      value.contains('trouser') ||
      value.contains('jean') ||
      value.contains('short') ||
      value.contains('skirt')) {
    return 'bottoms';
  }
  if (value.contains('accessor') ||
      value.contains('bag') ||
      value.contains('hat') ||
      value.contains('watch') ||
      value.contains('jewel')) {
    return 'accessories';
  }
  return 'tops';
}

String _imageUrl(Map<String, dynamic> product) {
  for (final field in const [
    'rawImageUrl',
    'imageUrl',
    'imageURL',
    'processedImageUrl',
  ]) {
    final value = product[field];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return '';
}
