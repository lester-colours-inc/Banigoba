// Full filter sheet for the marketplace: sort, category, gender, size,
// colour, style, price range and availability. Edits a draft and returns it
// when the shopper taps "Show N results".
import 'package:flutter/material.dart';

import 'package:banigoba/modules/shop/models/shop_filters.dart';
import 'package:banigoba/modules/shop/widgets/colour_swatch.dart';

const Color _primary = Color(0xFF0D0140);

/// Opens the sheet; resolves to the new filters, or null if dismissed.
Future<ShopFilters?> showShopFilterSheet(
  BuildContext context, {
  required ShopFilters initial,
  required ShopFilterOptions options,
  required List<Map<String, dynamic>> products,
}) => showModalBottomSheet<ShopFilters>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) =>
      ShopFilterSheet(initial: initial, options: options, products: products),
);

class ShopFilterSheet extends StatefulWidget {
  const ShopFilterSheet({
    super.key,
    required this.initial,
    required this.options,
    required this.products,
  });

  final ShopFilters initial;
  final ShopFilterOptions options;

  /// Search-matched products, used for the live result count.
  final List<Map<String, dynamic>> products;

  @override
  State<ShopFilterSheet> createState() => _ShopFilterSheetState();
}

class _ShopFilterSheetState extends State<ShopFilterSheet> {
  late ShopFilters _draft = widget.initial;

  void _update(ShopFilters next) => setState(() => _draft = next);

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    final count = applyShopFilters(widget.products, _draft).length;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scroll) => Column(
        children: [
          _header(context),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                _section('Sort by', _sortChips()),
                if (options.categories.isNotEmpty)
                  _section(
                    'Category',
                    _choiceWrap(
                      options.categories,
                      _draft.categories,
                      (v) => _update(
                        _draft.copyWith(
                          categories: toggled(_draft.categories, v),
                        ),
                      ),
                    ),
                  ),
                if (options.genders.isNotEmpty)
                  _section(
                    'Shop for',
                    _choiceWrap(
                      options.genders,
                      _draft.genders,
                      (v) => _update(
                        _draft.copyWith(genders: toggled(_draft.genders, v)),
                      ),
                    ),
                    hint: 'Unisex pieces always show',
                  ),
                if (options.priceCeiling > 0)
                  _section('Price', _priceSlider(options.priceCeiling)),
                if (options.sizes.isNotEmpty)
                  _section('Size', _sizeGrid(options.sizes)),
                if (options.colours.isNotEmpty)
                  _section('Colour', _colourWrap(options.colours)),
                if (options.styles.isNotEmpty)
                  _section(
                    'Style',
                    _choiceWrap(
                      options.styles,
                      _draft.styles,
                      (v) => _update(
                        _draft.copyWith(styles: toggled(_draft.styles, v)),
                      ),
                    ),
                  ),
                _section('Availability', _availability()),
              ],
            ),
          ),
          _footer(context, count),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Filters',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(
          onPressed: _draft.isEmpty ? null : () => _update(_draft.cleared()),
          child: const Text('Reset'),
        ),
      ],
    ),
  );

  Widget _section(String title, Widget child, {String? hint}) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );

  Widget _sortChips() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final sort in ShopSort.values)
        _chip(
          label: sort.label,
          selected: _draft.sort == sort,
          onTap: () => _update(_draft.copyWith(sort: sort)),
        ),
    ],
  );

  Widget _choiceWrap(
    List<String> values,
    Set<String> selected,
    ValueChanged<String> onToggle,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final value in values)
        _chip(
          label: filterLabel(value),
          selected: selected.contains(value),
          onTap: () => onToggle(value),
        ),
    ],
  );

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Widget? avatar,
  }) => FilterChip(
    label: Text(label),
    avatar: avatar,
    selected: selected,
    showCheckmark: avatar == null,
    onSelected: (_) => onTap(),
    selectedColor: _primary,
    checkmarkColor: Colors.white,
    labelStyle: TextStyle(
      color: selected ? Colors.white : null,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
    ),
    shape: StadiumBorder(
      side: BorderSide(
        color: selected
            ? _primary
            : Theme.of(context).colorScheme.outlineVariant,
      ),
    ),
  );

  Widget _priceSlider(double ceiling) {
    final start = (_draft.minPrice ?? 0).clamp(0, ceiling).toDouble();
    final end = (_draft.maxPrice ?? ceiling).clamp(start, ceiling).toDouble();
    final divisions = (ceiling / 5).round().clamp(1, 200);
    return Column(
      children: [
        Row(
          children: [
            _priceBox('Min', start),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('–'),
            ),
            _priceBox('Max', end, isMax: true),
          ],
        ),
        RangeSlider(
          values: RangeValues(start, end),
          min: 0,
          max: ceiling,
          divisions: divisions,
          activeColor: _primary,
          onChanged: (range) => _update(
            _draft.copyWith(
              minPrice: () => range.start <= 0 ? null : range.start,
              maxPrice: () => range.end >= ceiling ? null : range.end,
            ),
          ),
        ),
      ],
    );
  }

  Widget _priceBox(String label, double value, {bool isMax = false}) {
    final atCeiling = isMax && _draft.maxPrice == null;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11)),
            Text(
              '\$${value.toStringAsFixed(0)}${atCeiling ? '+' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sizeGrid(List<String> sizes) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final size in sizes)
        _sizeTile(
          size,
          _draft.sizes.contains(size),
          () => _update(_draft.copyWith(sizes: toggled(_draft.sizes, size))),
        ),
    ],
  );

  Widget _sizeTile(String size, bool selected, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      constraints: const BoxConstraints(minWidth: 52),
      height: 44,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? _primary : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? _primary
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Text(
        size,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : null,
        ),
      ),
    ),
  );

  Widget _colourWrap(List<String> colours) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final colour in colours)
        _chip(
          label: filterLabel(colour),
          selected: _draft.colours.contains(colour),
          avatar: ColourSwatch(name: colour, size: 18),
          onTap: () => _update(
            _draft.copyWith(colours: toggled(_draft.colours, colour)),
          ),
        ),
    ],
  );

  Widget _availability() => Column(
    children: [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('In stock only'),
        value: _draft.inStockOnly,
        activeThumbColor: _primary,
        onChanged: (v) => _update(_draft.copyWith(inStockOnly: v)),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('New arrivals'),
        subtitle: const Text('Listed in the last 14 days'),
        value: _draft.newOnly,
        activeThumbColor: _primary,
        onChanged: (v) => _update(_draft.copyWith(newOnly: v)),
      ),
    ],
  );

  Widget _footer(BuildContext context, int count) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: FilledButton(
        onPressed: () => Navigator.of(context).pop(_draft),
        style: FilledButton.styleFrom(
          backgroundColor: _primary,
          minimumSize: const Size(double.infinity, 54),
        ),
        child: Text(
          count == 0
              ? 'No matches'
              : 'Show $count result${count == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}
