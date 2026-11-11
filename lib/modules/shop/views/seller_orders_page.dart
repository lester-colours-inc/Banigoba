import 'package:flutter/material.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/supabase/rows.dart';

import 'package:banigoba/modules/shop/models/delivery.dart';
import 'package:banigoba/modules/shop/services/order_service.dart';
import 'package:banigoba/modules/shop/views/shop_chat_page.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class SellerOrdersPage extends StatelessWidget {
  const SellerOrdersPage({super.key});

  static const _primary = Color(0xFF0D0140);

  @override
  Widget build(BuildContext context) {
    final sellerId = AppAuth.instance.currentUser?.uid ?? '';
    final orderService = OrderService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: sellerId.isEmpty
          ? const Center(child: Text('Sign in to view orders.'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: orderService.watchSellerOrders(sellerId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Unable to load orders.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snapshot.data!.toList()
                  ..sort((a, b) {
                    final aTime = asDateTime(a['createdAt']);
                    final bTime = asDateTime(b['createdAt']);
                    return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(
                      aTime?.millisecondsSinceEpoch ?? 0,
                    );
                  });
                if (orders.isEmpty) {
                  return const Center(child: Text('No orders yet.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _OrderCard(
                      orderId: order['id'].toString(),
                      order: order,
                      orderService: orderService,
                    );
                  },
                );
              },
            ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  const _OrderCard({
    required this.orderId,
    required this.order,
    required this.orderService,
  });

  final String orderId;
  final Map<String, dynamic> order;
  final OrderService orderService;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
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
    final orderNumber = (order['orderNumber'] ?? widget.orderId.substring(0, 6))
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
              key: ValueKey('fulfilment_${widget.orderId}'),
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
                      child: Text(widget.orderService.orderStatusLabel(status)),
                    ),
                  )
                  .toList(),
              onChanged: _updating
                  ? null
                  : (value) {
                      if (value == null || value == status) return;
                      _updateStatus(value);
                    },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: chatId.isEmpty
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ShopChatPage(
                                chatId: chatId,
                                title: customerName,
                                asSeller: true,
                              ),
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

  Future<void> _updateStatus(String status) async {
    setState(() => _updating = true);
    try {
      await widget.orderService.updateOrderStatus(
        orderId: widget.orderId,
        status: status,
      );
      if (!mounted) return;
      AppToast.say('Order status updated.');
    } catch (error) {
      if (!mounted) return;
      AppToast.say('Unable to update order: $error');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
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
