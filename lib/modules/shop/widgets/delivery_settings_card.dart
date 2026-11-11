// "Delivery" in My Shop (K-3): whether the shop delivers itself, the fee and
// the areas it covers. Buyers see these at checkout; the fee they pay is
// always recomputed from what is saved here.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/delivery_settings_controller.dart';
import 'package:banigoba/modules/shop/models/delivery.dart';

class DeliverySettingsCard extends StatelessWidget {
  const DeliverySettingsCard({
    super.key,
    required this.initial,
    required this.onSave,
  });

  final DeliverySettings initial;
  final Future<void> Function(DeliverySettings settings) onSave;

  @override
  Widget build(BuildContext context) {
    // Scoped to this card: created and disposed with the widget.
    return GetBuilder<DeliverySettingsController>(
      init: DeliverySettingsController(initial: initial, onSave: onSave),
      global: false,
      builder: (controller) => _DeliverySettingsView(controller: controller),
    );
  }
}

class _DeliverySettingsView extends StatelessWidget {
  const _DeliverySettingsView({required this.controller});

  final DeliverySettingsController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(
      () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                key: const ValueKey('delivers_switch'),
                contentPadding: EdgeInsets.zero,
                value: controller.delivers.value,
                onChanged: controller.setDelivers,
                secondary: const Icon(Icons.local_shipping_outlined),
                title: const Text(
                  'I deliver',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Buyers can choose delivery instead of collecting. You '
                  'deliver yourself and set the fee.',
                ),
              ),
              if (controller.delivers.value) ...[
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('delivery_fee'),
                  controller: controller.fee,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Delivery fee',
                    prefixText: '\$ ',
                    helperText: 'Leave empty for free delivery.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('delivery_areas'),
                  controller: controller.areas,
                  decoration: const InputDecoration(
                    labelText: 'Areas you deliver to',
                    helperText:
                        'Separate with commas. Leave empty to deliver anywhere '
                        'the buyer gives an address.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('delivery_note'),
                  controller: controller.note,
                  decoration: const InputDecoration(
                    labelText: 'Note for buyers (optional)',
                    helperText: 'For example: same day before 4pm.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (controller.error.value != null) ...[
                const SizedBox(height: 10),
                Text(
                  controller.error.value!,
                  style: TextStyle(color: colors.error),
                ),
              ],
              if (controller.saved.value) ...[
                const SizedBox(height: 10),
                Text('Saved.', style: TextStyle(color: colors.primary)),
              ],
              const SizedBox(height: 12),
              FilledButton(
                key: const ValueKey('save_delivery'),
                onPressed: controller.saving.value ? null : controller.save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(
                  controller.saving.value ? 'Saving...' : 'Save delivery',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
