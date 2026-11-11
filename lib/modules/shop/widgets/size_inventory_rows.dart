// The "Size Inventory" part of the product form: a row per size with its
// quantity and optional garment measurements.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/profile_details/models/body_profile.dart';
import 'package:banigoba/modules/shop/controllers/product_form_controller.dart';
import 'package:banigoba/modules/wardrobe/models/fit_check.dart';

class SizeInventoryRows extends StatelessWidget {
  const SizeInventoryRows({super.key, required this.controller});

  final ProductFormController controller;

  static String _chartLabel(BodyMeasurement part) => switch (part) {
    BodyMeasurement.shoulders => 'Shoulders',
    BodyMeasurement.chest => 'Chest',
    BodyMeasurement.waist => 'Waist',
    BodyMeasurement.hips => 'Hips',
    _ => part.label,
  };

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Obx(() {
      final entries = controller.sizeEntries;
      final isShoes = controller.category.value == 'shoes';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Size Inventory',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: controller.addSize,
                icon: const Icon(Icons.add),
                label: const Text('Add Size'),
              ),
            ],
          ),
          if (entries.isEmpty)
            Text(
              'Use XXS-XXXL, UK clothing sizes, or UK shoe sizes (UK 7). '
              'Leave empty for one-size items.',
              style: TextStyle(color: muted),
            )
          else ...[
            for (var index = 0; index < entries.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: entries[index].sizeController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Size',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: entries[index].quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove size',
                          onPressed: () => controller.removeSize(index),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!isShoes)
                      // Optional size chart: what the garment measures in
                      // this size, so buyers get a fit check.
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final part in kChartParts)
                            SizedBox(
                              width: 104,
                              child: TextField(
                                key: ValueKey('chart_${index}_${part.key}'),
                                controller:
                                    entries[index].measureControllers[part],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: part == BodyMeasurement.insideLeg
                                      ? 'Inseam (cm)'
                                      : '${_chartLabel(part)} (cm)',
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            if (!isShoes)
              Text(
                'Optional: measure the garment itself, all the way around for '
                'chest, waist and hips. Buyers see a fit check against their '
                'own measurements.',
                style: TextStyle(fontSize: 12, color: muted),
              ),
          ],
        ],
      );
    });
  }
}
