// The add / edit product form, shown as a bottom sheet.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/makeover/widgets/back_photo_field.dart';
import 'package:banigoba/modules/shop/controllers/product_form_controller.dart';
import 'package:banigoba/modules/shop/widgets/product_image_source.dart';
import 'package:banigoba/modules/shop/widgets/safe_product_image.dart';
import 'package:banigoba/modules/shop/widgets/size_inventory_rows.dart';
import 'package:banigoba/modules/wardrobe/widgets/piece_extra_details_fields.dart';

const Color _primary = Color(0xFF0D0140);

Future<void> showProductFormSheet(
  BuildContext context, {
  String? docId,
  Map<String, dynamic>? existingData,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => GetBuilder<ProductFormController>(
      init: ProductFormController(docId: docId, existingData: existingData),
      global: false,
      builder: (controller) => _ProductFormSheet(controller: controller),
    ),
  );
}

class _ProductFormSheet extends StatelessWidget {
  const _ProductFormSheet({required this.controller});

  final ProductFormController controller;

  static String _cap(String value) =>
      value[0].toUpperCase() + value.substring(1);

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          // Rebuilt with the value, so a change made elsewhere shows.
          key: ValueKey('$label-$value'),
          initialValue: value,
          items: [
            for (final e in items)
              DropdownMenuItem(value: e, child: Text(_cap(e))),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 10),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _chips(String title, List<String> options, RxList<String> chosen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                FilterChip(
                  label: Text(_cap(option)),
                  selected: chosen.contains(option),
                  onSelected: (on) => controller.toggle(chosen, option, on: on),
                  selectedColor: _primary.withValues(alpha: 0.2),
                  checkmarkColor: _primary,
                  labelStyle: TextStyle(
                    color: chosen.contains(option) ? _primary : Colors.black87,
                    fontWeight: chosen.contains(option)
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _imageArea(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        final image = await pickProductImage(context);
        if (image != null) controller.selectedImage.value = image;
      },
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Obx(() {
          final picked = controller.selectedImage.value;
          final existing = controller.existingImageUrl.value;
          if (picked != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(picked, fit: BoxFit.cover),
            );
          }
          if (existing.isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SafeProductImage(
                imageUrl: existing,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
              ),
            );
          }
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
              SizedBox(height: 10),
              Text('Select Image', style: TextStyle(color: Colors.grey)),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Close',
                onPressed: Get.back<void>,
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  c.isEditing ? 'Edit Product' : 'Add Boutique Product',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: Get.back<void>,
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
            ),
          ),
          const SizedBox(height: 20),
          _imageArea(context),
          const SizedBox(height: 10),
          Obx(
            () => BackPhotoField(
              picked: c.selectedBackImage.value,
              existingUrl: c.existingBackImageUrl.value,
              onPick: () async {
                final image = await pickProductImage(context);
                if (image != null) c.selectedBackImage.value = image;
              },
              onRemove: c.removeBackPhoto,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: c.name,
            decoration: const InputDecoration(
              labelText: 'Product Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: c.price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixText: r'$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: c.stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stock',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizeInventoryRows(controller: c),
          const SizedBox(height: 15),
          Obx(
            () => buildPieceExtraDetailsFields(
              context,
              shoulderController: c.shoulder,
              heightController: c.heightMeasurement,
              linenTypeController: c.linenType,
              madeWhereController: c.madeWhere,
              otherDetailControllers: c.otherDetails.toList(),
              onAddDetail: c.addDetail,
              onRemoveDetail: c.removeDetail,
            ),
          ),
          const SizedBox(height: 15),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _dropdown(
                    'Category',
                    c.category.value,
                    ProductFormController.categoryData.keys.toList(),
                    c.setCategory,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dropdown(
                    'Subcategory',
                    c.subcategory.value,
                    ProductFormController.categoryData[c.category.value]!,
                    (v) => c.subcategory.value = v,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Obx(
            () => _dropdown(
              'Style Tag',
              c.styleTag.value,
              ProductFormController.styleOptions,
              (v) => c.styleTag.value = v,
            ),
          ),
          const SizedBox(height: 15),
          _chips(
            'Select Colours',
            ProductFormController.availableColours,
            c.colours,
          ),
          Obx(
            () => _dropdown(
              'Gender',
              c.gender.value,
              ProductFormController.genderOptions,
              (v) => c.gender.value = v,
            ),
          ),
          const SizedBox(height: 15),
          _chips(
            'Weather Tags',
            ProductFormController.weatherOptions,
            c.weatherTags,
          ),
          _chips(
            'Functional Tags',
            ProductFormController.functionalOptions,
            c.functionalTags,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: c.submit,
              child: Text(
                c.isEditing ? 'Update Product' : 'Add Product',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
