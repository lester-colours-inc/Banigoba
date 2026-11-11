// The bottom sheet that finishes an order from the cart.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/checkout_sheet_controller.dart';
import 'package:banigoba/modules/shop/widgets/checkout_options.dart';
import 'package:banigoba/modules/shop/widgets/collection_address_dialog.dart';

Future<void> showCheckoutSheet(
  BuildContext context, {
  required String userId,
  required double total,
  required String sellerId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => GetBuilder<CheckoutSheetController>(
      init: CheckoutSheetController(
        userId: userId,
        itemsTotal: total,
        sellerId: sellerId,
        askAddress: ({required bool deliveryOnly}) =>
            showCollectionAddressDialog(
              sheetContext,
              deliveryOnly: deliveryOnly,
            ),
      ),
      global: false,
      builder: (controller) => _CheckoutSheet(controller: controller),
    ),
  );
}

class _CheckoutSheet extends StatelessWidget {
  const _CheckoutSheet({required this.controller});

  final CheckoutSheetController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Checkout',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (!controller.loaded.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                CheckoutOptions(
                  itemsTotal: controller.itemsTotal,
                  settings: controller.settings.value,
                  rates: controller.rates.value,
                  fulfilment: controller.fulfilment.value,
                  area: controller.area.value,
                  onFulfilment: controller.chooseFulfilment,
                  onArea: controller.chooseArea,
                ),
              const SizedBox(height: 14),
              FilledButton(
                key: const ValueKey('confirm_order'),
                onPressed: controller.placing.value || !controller.canConfirm
                    ? null
                    : controller.confirm,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(
                  controller.placing.value ? 'Sending Order...' : 'Confirm',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
