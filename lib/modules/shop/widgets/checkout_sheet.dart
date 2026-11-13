// The bottom sheet that finishes an order from the cart.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/checkout_sheet_controller.dart';
import 'package:banigoba/modules/shop/widgets/checkout_options.dart';
import 'package:banigoba/modules/shop/widgets/collection_address_dialog.dart';
import 'package:banigoba/modules/shop/widgets/pay_order_sheet.dart';

/// Checkout, then, when the buyer chose to pay now, the payment sheet.
Future<void> showCheckoutSheet(
  BuildContext context, {
  required String userId,
  required double total,
  required String sellerId,
}) async {
  final placed = await _showCheckout(
    context,
    userId: userId,
    total: total,
    sellerId: sellerId,
  );
  if (placed == null || !placed.payNow || !context.mounted) return;
  await showPayOrderSheet(context, orderId: placed.id, total: placed.total);
}

Future<PlacedOrder?> _showCheckout(
  BuildContext context, {
  required String userId,
  required double total,
  required String sellerId,
}) {
  return showModalBottomSheet<PlacedOrder>(
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
              if (controller.loaded.value)
                SwitchListTile(
                  key: const ValueKey('pay_now_switch'),
                  contentPadding: EdgeInsets.zero,
                  value: controller.payNow.value,
                  onChanged: controller.choosePayNow,
                  title: const Text('Pay now online'),
                  subtitle: const Text(
                    'EcoCash, OneMoney, InnBucks, O\'mari, SmileCash or card',
                  ),
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
                  controller.placing.value
                      ? 'Sending Order...'
                      : controller.payNow.value
                      ? 'Confirm and pay'
                      : 'Confirm',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
