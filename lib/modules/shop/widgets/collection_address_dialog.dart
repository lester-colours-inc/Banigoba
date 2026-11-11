// Asks the buyer for a delivery address or a collection point.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/collection_address_controller.dart';

/// Shows the dialog; resolves to the address, or null when cancelled.
Future<Map<String, dynamic>?> showCollectionAddressDialog(
  BuildContext context, {
  bool deliveryOnly = false,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => GetBuilder<CollectionAddressController>(
      init: CollectionAddressController(deliveryOnly: deliveryOnly),
      global: false,
      builder: (controller) => _CollectionAddressDialog(
        controller: controller,
        dialogContext: dialogContext,
      ),
    ),
  );
}

class _CollectionAddressDialog extends StatelessWidget {
  const _CollectionAddressDialog({
    required this.controller,
    required this.dialogContext,
  });

  final CollectionAddressController controller;
  final BuildContext dialogContext;

  static Widget _field(TextEditingController c, String label) => TextField(
    controller: c,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final deliveryOnly = controller.deliveryOnly;
    return AlertDialog(
      title: Text(deliveryOnly ? 'Delivery address' : 'Collection details'),
      content: SingleChildScrollView(
        child: Obx(() {
          final usePickup = controller.usePickupPoint.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!deliveryOnly)
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Address'),
                      icon: Icon(Icons.home_outlined),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Collection point'),
                      icon: Icon(Icons.location_on_outlined),
                    ),
                  ],
                  selected: {usePickup},
                  onSelectionChanged: (selection) =>
                      controller.setUsePickupPoint(selection.first),
                ),
              const SizedBox(height: 14),
              if (usePickup) ...[
                _field(controller.pickup, 'Collection point name'),
                const SizedBox(height: 10),
              ],
              _field(
                controller.street,
                usePickup
                    ? 'Collection point street address'
                    : 'Street address',
              ),
              const SizedBox(height: 10),
              _field(controller.city, 'City'),
              const SizedBox(height: 10),
              _field(controller.state, 'State / Province'),
              const SizedBox(height: 10),
              _field(controller.postal, 'Postal code'),
              const SizedBox(height: 10),
              _field(controller.country, 'Country'),
            ],
          );
        }),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final result = controller.result();
            if (result != null) Navigator.pop(dialogContext, result);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
