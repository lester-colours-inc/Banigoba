// "Share my stock": what to share (all, a category, picked pieces), in the
// shop's own words, and who in Banigoba to tell (K-9).
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/shop_link_form_controller.dart';
import 'package:banigoba/modules/shop/models/shop_link.dart';
import 'package:banigoba/modules/shop/widgets/safe_product_image.dart';

class ShopLinkForm extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Scoped to this form: created and disposed with the widget.
    return GetBuilder<ShopLinkFormController>(
      init: ShopLinkFormController(
        ownerId: ownerId,
        shopName: shopName,
        products: products,
        onSubmit: onSubmit,
      ),
      global: false,
      builder: (controller) => _ShopLinkFormView(controller: controller),
    );
  }
}

class _ShopLinkFormView extends StatelessWidget {
  const _ShopLinkFormView({required this.controller});

  final ShopLinkFormController controller;

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

    return Obx(
      () => ListView(
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
                  selected: controller.scope.value == scope,
                  onSelected: (_) => controller.chooseScope(scope),
                ),
            ],
          ),
          if (controller.scope.value == ShareScope.category) ...[
            heading('Which category?'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in controller.categories)
                  ChoiceChip(
                    key: ValueKey('category_$category'),
                    label: Text(
                      '${category[0].toUpperCase()}${category.substring(1)}',
                    ),
                    selected: controller.category.value == category,
                    onSelected: (_) => controller.chooseCategory(category),
                  ),
              ],
            ),
          ],
          if (controller.scope.value == ShareScope.items) ...[
            heading('Pick the pieces (${controller.picked.length} chosen)'),
            for (final product in controller.products)
              CheckboxListTile(
                key: ValueKey('pick_${controller.idOf(product)}'),
                contentPadding: EdgeInsets.zero,
                value: controller.picked.contains(controller.idOf(product)),
                onChanged: (on) => controller.setPicked(
                  controller.idOf(product),
                  on: on == true,
                ),
                secondary: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SafeProductImage(
                    imageUrl: controller.imageOf(product),
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
            controller: controller.title,
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
            controller: controller.note,
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
                controller.audience.value == audience
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(audience.label),
              subtitle: Text(audience.description),
              onTap: () => controller.chooseAudience(audience),
            ),
          Text(
            'Whatever you choose, you also get a link and a QR code to send on '
            'WhatsApp or anywhere else.',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
          if (controller.error.value != null) ...[
            const SizedBox(height: 12),
            Text(
              controller.error.value!,
              style: TextStyle(color: colors.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('create_link'),
            onPressed: controller.busy.value ? null : controller.submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: Text(controller.busy.value ? 'Creating...' : 'Create link'),
          ),
        ],
      ),
    );
  }
}
