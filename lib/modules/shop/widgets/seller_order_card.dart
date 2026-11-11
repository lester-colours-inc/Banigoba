// One order on the seller's Orders screen.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/seller_orders_controller.dart';
import 'package:banigoba/modules/shop/models/delivery.dart';
import 'package:banigoba/modules/shop/views/shop_chat_page.dart';

/// One order with its customer, items, status picker and a message button.
class SellerOrderCard extends StatelessWidget {
  const SellerOrderCard({
    super.key,
    required this.controller,
    required this.orderId,
    required this.order,
  });

  final SellerOrdersController controller;
  final String orderId;
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final items = List<Map<String, dynamic>>.from(
      order['items'] as List? ?? [],
    );
    final address = Map<String, dynamic>.from(
      order['customerAddress'] as Map? ?? const {},
    );
    final status = (order['status'] ?? 'submitted').toString();
    final fulfilment = Fulfilment.fromValue(order['fulfilment']);
    final delivering = fulfilment == Fulfilment.delivery;
    final deliveryFee = (order['deliveryFee'] as num?)?.toDouble() ?? 0;
    final deliveryArea = (order['deliveryArea'] ?? '').toString();
    // The steps that fit this kind of order, keeping the current one even if
    // it is from an older flow.
    final statuses = [
      ...statusesFor(fulfilment),
      if (!statusesFor(fulfilment).contains(status)) status,
    ];
    final orderNumber = (order['orderNumber'] ?? orderId.substring(0, 6))
        .toString();
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final itemsTotal = (order['itemsTotal'] as num?)?.toDouble() ?? 0;
    final commission = (order['commission'] as num?)?.toDouble() ?? 0;
    final customerName = (order['customerName'] ?? 'Customer').toString();
    final customerEmail = (order['customerEmail'] ?? '').toString();
    final chatId = (order['chatId'] ?? '').toString();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #$orderNumber',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF0D0140),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (commission > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Your price \$${itemsTotal.toStringAsFixed(2)} · '
                  'service fee \$${commission.toStringAsFixed(2)} '
                  '(collected for Banigoba)',
                  key: const ValueKey('commission_breakdown'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              customerName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (customerEmail.isNotEmpty) Text(customerEmail),
            const SizedBox(height: 10),
            Container(
              key: ValueKey('fulfilment_$orderId'),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: delivering
                    ? const Color(0xFF0D0140)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                delivering
                    ? 'Deliver${deliveryArea.isEmpty ? '' : ' to $deliveryArea'}'
                          ' · ${deliveryFee == 0 ? 'free' : '\$${deliveryFee.toStringAsFixed(2)}'}'
                    : 'Customer collects',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: delivering
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              _formatAddress(address),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) {
              final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
              final price = (item['price'] as num?)?.toDouble() ?? 0;
              final selectedSize = (item['selectedSize'] ?? '').toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '$quantity x ${(item['name'] ?? 'Product')}${selectedSize.isEmpty ? '' : ' • Size $selectedSize'} - \$${price.toStringAsFixed(2)}',
                ),
              );
            }),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: statuses.contains(status) ? status : 'submitted',
              decoration: const InputDecoration(
                labelText: 'Order status',
                border: OutlineInputBorder(),
              ),
              items: statuses
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(
                        controller.orderService.orderStatusLabel(status),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: controller.updating.contains(orderId)
                  ? null
                  : (value) {
                      if (value == null || value == status) return;
                      controller.updateStatus(orderId, value);
                    },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: chatId.isEmpty
                        ? null
                        : () => Get.to<void>(
                            () => ShopChatPage(
                              chatId: chatId,
                              title: customerName,
                              asSeller: true,
                            ),
                          ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Message Customer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> address) {
    final pickupPoint = (address['pickupPoint'] ?? '').toString().trim();
    final parts =
        [
          address['street'],
          address['city'],
          address['state'],
          address['postalCode'],
          address['country'],
        ].map((value) => (value ?? '').toString().trim()).where((value) {
          return value.isNotEmpty;
        }).toList();

    if (pickupPoint.isNotEmpty) {
      return [pickupPoint, ...parts].join(', ');
    }
    if (parts.isEmpty) return 'No address saved for this customer.';
    return parts.join(', ');
  }
}
