// The strip under the tabs: a Filters button with an active-count badge,
// a sort menu, and quick category chips; then a result count line with
// "Clear all" when anything narrows the list.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/shops_controller.dart';
import 'package:banigoba/modules/shop/models/shop_filters.dart';
import 'package:banigoba/modules/shop/widgets/shop_filter_sheet.dart';

const Color _primary = Color(0xFF0D0140);

class ShopFilterBar extends StatelessWidget {
  const ShopFilterBar({super.key, required this.controller});

  final ShopsController controller;

  Future<void> _openSheet(BuildContext context) async {
    final result = await showShopFilterSheet(
      context,
      initial: controller.filters.value,
      options: controller.filterOptions,
      products: controller.matching,
      // All Products is not on the phone, so the database counts for it.
      countFor: controller.tab.value == 1 ? controller.countFor : null,
    );
    if (result != null) controller.setFilters(result);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final filters = controller.filters.value;
      final isProducts = controller.tab.value == 1;
      return ShopFilterStrip(
        filters: filters,
        categories: controller.filterOptions.categories,
        onOpenSheet: () => _openSheet(context),
        onToggleCategory: controller.toggleCategory,
        onClearCategories: controller.clearCategories,
        sort: isProducts
            ? _SortMenu<ShopSort>(
                values: ShopSort.values,
                selected: filters.sort,
                label: (s) => s.label,
                onSelected: controller.setSort,
              )
            : _SortMenu<BoutiqueSort>(
                values: BoutiqueSort.values,
                selected: controller.boutiqueSort.value,
                label: (s) => s.label,
                onSelected: controller.setBoutiqueSort,
              ),
      );
    });
  }
}

/// The Filters button, a sort menu and quick category chips, driven by plain
/// values so any page (marketplace, one boutique) can use it.
class ShopFilterStrip extends StatelessWidget {
  const ShopFilterStrip({
    super.key,
    required this.filters,
    required this.categories,
    required this.onOpenSheet,
    required this.onToggleCategory,
    required this.onClearCategories,
    required this.sort,
  });

  final ShopFilters filters;
  final List<String> categories;
  final VoidCallback onOpenSheet;
  final ValueChanged<String> onToggleCategory;
  final VoidCallback onClearCategories;

  /// A sort menu, e.g. from [ShopSortMenu] or the boutique sort.
  final Widget sort;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _FiltersButton(count: filters.activeCount, onTap: onOpenSheet),
          const SizedBox(width: 8),
          sort,
          if (categories.isNotEmpty) ...[
            const _Divider(),
            _QuickChip(
              label: 'All',
              selected: filters.categories.isEmpty,
              onTap: onClearCategories,
            ),
            for (final category in categories)
              _QuickChip(
                label: filterLabel(category),
                selected: filters.categories.contains(category),
                onTap: () => onToggleCategory(category),
              ),
          ],
        ],
      ),
    );
  }
}

/// Product sort menu for [ShopFilterStrip].
class ShopSortMenu extends StatelessWidget {
  const ShopSortMenu({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ShopSort selected;
  final ValueChanged<ShopSort> onSelected;

  @override
  Widget build(BuildContext context) => _SortMenu<ShopSort>(
    values: ShopSort.values,
    selected: selected,
    label: (s) => s.label,
    onSelected: onSelected,
  );
}

/// "24 products · Clear all" line under the bar.
class ShopResultSummary extends StatelessWidget {
  const ShopResultSummary({
    super.key,
    required this.label,
    required this.canClear,
    required this.onClear,
  });

  final String label;
  final bool canClear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 12, 2),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: muted, fontWeight: FontWeight.w600),
              ),
            ),
            if (canClear)
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Clear all'),
              ),
          ],
        ),
      ),
    );
  }
}

class _FiltersButton extends StatelessWidget {
  const _FiltersButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Material(
      color: active ? _primary : Theme.of(context).colorScheme.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: active
              ? _primary
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 18,
                color: active ? Colors.white : null,
              ),
              const SizedBox(width: 6),
              Text(
                'Filters',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : null,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.white,
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SortMenu<T> extends StatelessWidget {
  const _SortMenu({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      initialValue: selected,
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (_) => [
        for (final value in values)
          CheckedPopupMenuItem<T>(
            value: value,
            checked: value == selected,
            child: Text(label(value)),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: ShapeDecoration(
          shape: StadiumBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.swap_vert_rounded, size: 18),
            const SizedBox(width: 6),
            Text(
              label(selected),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        selectedColor: _primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : null,
          fontWeight: FontWeight.w600,
        ),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected
                ? _primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: VerticalDivider(
      width: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    ),
  );
}
