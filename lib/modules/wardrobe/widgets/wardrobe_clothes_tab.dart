// The My Clothes tab: insights entry, collection chips, pieces by category.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/wardrobe/controllers/wardrobe_controller.dart';
import 'package:banigoba/modules/wardrobe/models/wardrobe_collections.dart';
import 'package:banigoba/modules/wardrobe/widgets/wardrobe_item_card.dart';

class WardrobeClothesTab extends StatelessWidget {
  const WardrobeClothesTab({super.key, required this.controller});

  final WardrobeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.items.value;
      if (items == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (items.isEmpty) {
        return const Center(
          child: Text('Your wardrobe is empty. Upload some items!'),
        );
      }
      final collections = collectionsOf(items);
      final shown = controller.shownItems;
      return Column(
        children: [
          _InsightsEntry(controller: controller),
          if (collections.isNotEmpty)
            _CollectionChips(
              controller: controller,
              collections: collections,
              items: items,
            ),
          Expanded(
            child: shown.isEmpty
                ? const Center(child: Text('Nothing here yet.'))
                : _GroupedProductList(controller: controller, items: shown),
          ),
        ],
      );
    });
  }
}

/// A card above My Clothes that opens the wardrobe insights (W-10).
class _InsightsEntry extends StatelessWidget {
  const _InsightsEntry({required this.controller});

  final WardrobeController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        child: ListTile(
          key: const ValueKey('wardrobe_insights_entry'),
          leading: Icon(Icons.insights_outlined, color: colors.primary),
          title: const Text(
            'Wardrobe insights',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'What you wear most, what is sitting unworn, what is missing.',
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: controller.openInsights,
        ),
      ),
    );
  }
}

/// The row of collections above My Clothes (W-6).
class _CollectionChips extends StatelessWidget {
  const _CollectionChips({
    required this.controller,
    required this.collections,
    required this.items,
  });

  final WardrobeController controller;
  final List<String> collections;
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    final name = controller.collectionName.value;
    final view = controller.collectionView.value;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          _chip(
            const ValueKey('collection_all'),
            'All (${items.length})',
            name == null && view == CollectionView.all,
            controller.showAllCollections,
          ),
          for (final collection in collections)
            _chip(
              ValueKey('collection_$collection'),
              '$collection (${countIn(items, collection)})',
              name == collection,
              () => controller.showCollection(collection),
            ),
          _chip(
            const ValueKey('collection_none'),
            'Not in a collection',
            name == null && view == CollectionView.uncollected,
            controller.showUncollected,
          ),
        ],
      ),
    );
  }

  Widget _chip(Key key, String label, bool selected, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          key: key,
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
}

/// A scrollable list of products grouped by category.
class _GroupedProductList extends StatelessWidget {
  const _GroupedProductList({required this.controller, required this.items});

  final WardrobeController controller;
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final category = (item['category']?.toString() ?? 'Other').toLowerCase();
      grouped.putIfAbsent(category, () => []).add(item);
    }
    final categories = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: categories.length,
      itemBuilder: (context, catIndex) {
        final category = categories[catIndex];
        final categoryItems = grouped[category]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                category[0].toUpperCase() + category.substring(1),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.64,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: categoryItems.length,
              itemBuilder: (context, index) => WardrobeItemCard(
                controller: controller,
                data: Map<String, dynamic>.from(categoryItems[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}
