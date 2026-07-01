import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/services/order_service.dart';
import 'shop_chat_page.dart';

class SellerOrdersPage extends StatelessWidget {
  const SellerOrdersPage({super.key});

  static const _primary = Color(0xFF0D0140);

  @override
  Widget build(BuildContext context) {
    final sellerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final orderService = OrderService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: sellerId.isEmpty
          ? const Center(child: Text('Sign in to view orders.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: orderService.watchSellerOrders(sellerId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Unable to load orders.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final aTime = a.data()['createdAt'] as Timestamp?;
                    final bTime = b.data()['createdAt'] as Timestamp?;
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
                    final doc = orders[index];
                    return _OrderCard(
                      orderId: doc.id,
                      order: doc.data(),
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

  static const _statuses = [
    'submitted',
    'accepted',
    'ready_for_collection',
    'collected',
    'cancelled',
  ];

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
    final orderNumber = (order['orderNumber'] ?? widget.orderId.substring(0, 6))
        .toString();
    final total = (order['total'] as num?)?.toDouble() ?? 0;
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
            const SizedBox(height: 8),
            Text(
              customerName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (customerEmail.isNotEmpty) Text(customerEmail),
            const SizedBox(height: 10),
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
              initialValue: _statuses.contains(status) ? status : 'submitted',
              decoration: const InputDecoration(
                labelText: 'Order status',
                border: OutlineInputBorder(),
              ),
              items: _statuses
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Order status updated.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to update order: $error')));
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
