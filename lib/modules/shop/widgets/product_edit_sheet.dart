// The owner's "Edit Item" bottom sheet.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/product_edit_controller.dart';

Future<void> showProductEditSheet(
  BuildContext context, {
  required Map<String, dynamic> product,
  required bool isCatalog,
  required Future<void> Function(Map<String, dynamic> updated) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => GetBuilder<ProductEditController>(
      init: ProductEditController(
        product: product,
        isCatalog: isCatalog,
        onSave: onSave,
      ),
      global: false,
      builder: (controller) => _ProductEditSheet(controller: controller),
    ),
  );
}

class _ProductEditSheet extends StatelessWidget {
  const _ProductEditSheet({required this.controller});

  final ProductEditController controller;

  static String _label(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  Widget _chips(String title, List<String> options, RxList<String> chosen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Obx(
          () => Wrap(
            spacing: 8,
            children: [
              for (final option in options)
                FilterChip(
                  label: Text(option),
                  selected: chosen.contains(option),
                  onSelected: (on) => controller.toggle(chosen, option, on: on),
                ),
            ],
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Item',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller.name,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            Obx(
              () => DropdownButtonFormField<String>(
                initialValue: controller.styleTag.value,
                decoration: const InputDecoration(
                  labelText: 'Style',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final v in ProductEditController.styleOptions)
                    DropdownMenuItem(value: v, child: Text(_label(v))),
                ],
                onChanged: (v) {
                  if (v != null) controller.styleTag.value = v;
                },
              ),
            ),
            const SizedBox(height: 15),
            if (!controller.isCatalog) ...[
              Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: controller.visibility.value,
                  decoration: const InputDecoration(
                    labelText: 'Visibility',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final v in const ['private', 'public'])
                      DropdownMenuItem(value: v, child: Text(v.toUpperCase())),
                  ],
                  onChanged: (v) {
                    if (v != null) controller.visibility.value = v;
                  },
                ),
              ),
            ],
            const SizedBox(height: 15),
            _chips(
              'Colours',
              ProductEditController.availableColours,
              controller.colours,
            ),
            _chips(
              'Weather Tags',
              ProductEditController.weatherOptions,
              controller.weatherTags,
            ),
            _chips(
              'Functional Tags',
              ProductEditController.functionalOptions,
              controller.functionalTags,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D0140),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: controller.save,
                child: const Text(
                  'Save Changes',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
