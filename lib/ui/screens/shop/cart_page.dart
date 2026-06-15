// Displays and manages the signed-in user's shopping cart.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/services/cart_service.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final cart = CartService();
    return Scaffold(
      appBar: AppBar(title: const Text("Cart")),
      body: user == null
          ? const Center(child: Text('Sign in to use your cart.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: cart.watchCart(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data!.docs;
                if (items.isEmpty) {
                  return const Center(child: Text('Your cart is empty.'));
                }
                final total = items.fold<double>(0, (totalSoFar, doc) {
                  final data = doc.data();
                  return totalSoFar +
                      ((data['price'] as num?)?.toDouble() ?? 0) *
                          ((data['quantity'] as num?)?.toInt() ?? 1);
                });
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final doc = items[index];
                          final data = doc.data();
                          final quantity =
                              (data['quantity'] as num?)?.toInt() ?? 1;
                          final imageUrl =
                              (data['rawImageUrl'] ??
                                      data['imageUrl'] ??
                                      data['imageURL'] ??
                                      '')
                                  .toString();
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: SizedBox(
                              width: 58,
                              child: imageUrl.isEmpty
                                  ? const Icon(Icons.checkroom)
                                  : Image.network(
                                      imageUrl,
                                      fit: BoxFit.contain,
                                    ),
                            ),
                            title: Text((data['name'] ?? 'Product').toString()),
                            subtitle: Text(
                              '\$${((data['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => cart.setQuantity(
                                    userId: user.uid,
                                    productId: doc.id,
                                    quantity: quantity - 1,
                                  ),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text('$quantity'),
                                IconButton(
                                  onPressed: () => cart.setQuantity(
                                    userId: user.uid,
                                    productId: doc.id,
                                    quantity: quantity + 1,
                                  ),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Total: \$${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Checkout will be available soon.',
                                      ),
                                    ),
                                  ),
                              child: const Text('Checkout'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
