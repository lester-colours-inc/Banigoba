// "Share my stock": what to share (all, a category, picked pieces), in the
// shop's own words, and who in Banigoba to tell (K-9).
import 'package:flutter/material.dart';

import '../../../data/models/shop_link.dart';
import '../../widgets/safe_product_image.dart';

class ShopLinkForm extends StatefulWidget {
  const ShopLinkForm({
    super.key,
    required this.ownerId,
    required this.shopName,
    required this.products,
    required this.onSubmit,
  });

  final String ownerId;
  final String shopName;

  /// The shop's own pieces, each with an 'id'.
  final List<Map<String, dynamic>> products;
  final Future<void> Function(ShopLink draft) onSubmit;

  @override
  State<ShopLinkForm> createState() => _ShopLinkFormState();
}

class _ShopLinkFormState extends State<ShopLinkForm> {
  ShareScope _scope = ShareScope.all;
  String _category = '';
  final List<String> _picked = [];
  ShareAudience _audience = ShareAudience.linkOnly;
  final TextEditingController _title = TextEditingController();
  final TextEditingController _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final found = <String>{};
    for (final product in widget.products) {
      final category = (product['category'] ?? '').toString().trim();
      if (category.isNotEmpty) found.add(category.toLowerCase());
    }
    return found.toList()..sort();
  }

  String _id(Map<String, dynamic> product) => (product['id'] ?? '').toString();

  String _image(Map<String, dynamic> product) =>
      (product['rawImageUrl'] ?? product['imageUrl'] ?? '').toString();

  ShopLink _draft() {
    final base = ShopLink(
      id: '',
      ownerId: widget.ownerId,
      shopName: widget.shopName,
      title: '',
      scope: _scope,
      category: _category,
      productIds: List.unmodifiable(_picked),
      audience: _audience,
    );
    final covered = switch (_scope) {
      ShareScope.all => widget.products,
      ShareScope.category => widget.products.where(
        (p) => (p['category'] ?? '').toString().toLowerCase() == _category,
      ),
      ShareScope.items => [
        for (final id in _picked) ...widget.products.where((p) => _id(p) == id),
      ],
    };
    final cover = covered
        .map(_image)
        .firstWhere((url) => url.isNotEmpty, orElse: () => '');
    return ShopLink(
      id: '',
      ownerId: base.ownerId,
      shopName: base.shopName,
      title: _title.text.trim().isEmpty ? base.scopeLabel : _title.text.trim(),
      note: _note.text.trim(),
      scope: base.scope,
      category: base.category,
      productIds: base.productIds,
      audience: base.audience,
      coverImageUrl: cover,
    );
  }

  Future<void> _submit() async {
    final draft = _draft();
    final problem = validateShopLink(
      title: draft.title,
      note: draft.note,
      scope: _scope,
      category: _category,
      productIds: _picked,
    );
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(draft);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = 'Could not create the link: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        heading('What do you want to share?'),
        Wrap(
          spacing: 8,
          children: [
            for (final (scope, label) in const [
              (ShareScope.all, 'All my stock'),
              (ShareScope.category, 'A category'),
              (ShareScope.items, 'Pick pieces'),
            ])
              ChoiceChip(
                key: ValueKey('scope_${scope.value}'),
                label: Text(label),
                selected: _scope == scope,
                onSelected: (_) => setState(() {
                  _scope = scope;
                  _error = null;
                }),
              ),
          ],
        ),
        if (_scope == ShareScope.category) ...[
          heading('Which category?'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in _categories)
                ChoiceChip(
                  key: ValueKey('category_$category'),
                  label: Text(
                    '${category[0].toUpperCase()}${category.substring(1)}',
                  ),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
            ],
          ),
        ],
        if (_scope == ShareScope.items) ...[
          heading('Pick the pieces (${_picked.length} chosen)'),
          for (final product in widget.products)
            CheckboxListTile(
              key: ValueKey('pick_${_id(product)}'),
              contentPadding: EdgeInsets.zero,
              value: _picked.contains(_id(product)),
              onChanged: (on) => setState(() {
                on == true
                    ? _picked.add(_id(product))
                    : _picked.remove(_id(product));
              }),
              secondary: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SafeProductImage(
                  imageUrl: _image(product),
                  width: 48,
                  height: 48,
                  iconSize: 22,
                ),
              ),
              title: Text((product['name'] ?? 'Piece').toString()),
            ),
        ],
        heading('In your words'),
        TextField(
          key: const ValueKey('link_title'),
          controller: _title,
          maxLength: kMaxLinkTitle,
          decoration: const InputDecoration(
            labelText: 'Title (optional)',
            hintText: 'e.g. New in: winter coats',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('link_note'),
          controller: _note,
          maxLength: kMaxLinkNote,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            hintText: 'e.g. Sizes S to XL, delivery in Harare',
            border: OutlineInputBorder(),
          ),
        ),
        heading('Who in Banigoba should know?'),
        for (final audience in ShareAudience.values)
          ListTile(
            key: ValueKey('audience_${audience.value}'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _audience == audience
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: Text(audience.label),
            subtitle: Text(audience.description),
            onTap: () => setState(() => _audience = audience),
          ),
        Text(
          'Whatever you choose, you also get a link and a QR code to send on '
          'WhatsApp or anywhere else.',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: colors.error)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('create_link'),
          onPressed: _busy ? null : _submit,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
          child: Text(_busy ? 'Creating...' : 'Create link'),
        ),
      ],
    );
  }
}
