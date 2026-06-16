// Displays and manages the signed-in user's shopping cart.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/services/cart_service.dart';
import '../../../data/services/order_service.dart';

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
                return FutureBuilder<Map<String, Map<String, dynamic>>>(
                  future: _loadLiveProducts(items),
                  builder: (context, productSnapshot) {
                    final liveProducts =
                        productSnapshot.data ??
                        const <String, Map<String, dynamic>>{};
                    final total = items.fold<double>(0, (totalSoFar, doc) {
                      final data = doc.data();
                      final price = _priceFor(data, liveProducts[doc.id]);
                      return totalSoFar +
                          price * ((data['quantity'] as num?)?.toInt() ?? 1);
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
                              final liveProduct = liveProducts[doc.id];
                              final quantity =
                                  (data['quantity'] as num?)?.toInt() ?? 1;
                              final imageUrl =
                                  (data['rawImageUrl'] ??
                                          data['imageUrl'] ??
                                          data['imageURL'] ??
                                          '')
                                      .toString();
                              final price = _priceFor(data, liveProduct);
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
                                title: Text(
                                  (data['name'] ?? 'Product').toString(),
                                ),
                                subtitle: Text('\$${price.toStringAsFixed(2)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => cart.setQuantity(
                                        userId: user.uid,
                                        productId: doc.id,
                                        quantity: quantity - 1,
                                      ),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                    Text('$quantity'),
                                    IconButton(
                                      onPressed: () => cart.setQuantity(
                                        userId: user.uid,
                                        productId: doc.id,
                                        quantity: quantity + 1,
                                      ),
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
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
                                  onPressed: () => _showCollectionCheckout(
                                    context,
                                    user.uid,
                                    total,
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
                );
              },
            ),
    );
  }

  Future<Map<String, Map<String, dynamic>>> _loadLiveProducts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> cartItems,
  ) async {
    final products = <String, Map<String, dynamic>>{};
    await Future.wait(
      cartItems.map((item) async {
        final productId = (item.data()['productId'] ?? item.id).toString();
        final product = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();
        final data = product.data();
        if (data != null) products[item.id] = data;
      }),
    );
    return products;
  }

  double _priceFor(
    Map<String, dynamic> cartData,
    Map<String, dynamic>? productData,
  ) {
    final cartPrice = _moneyValue(cartData['price']);
    if (cartPrice > 0) return cartPrice;
    return _moneyValue(productData?['price']);
  }

  double _moneyValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0;
    return 0;
  }

  void _showCollectionCheckout(
    BuildContext context,
    String userId,
    double total,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        var placing = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Checkout',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.radio_button_checked),
                      title: const Text('Pay upon collection'),
                      subtitle: Text('Total: \$${total.toStringAsFixed(2)}'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: placing
                          ? null
                          : () async {
                              setSheetState(() => placing = true);
                              try {
                                final hasCollectionAddress =
                                    await _ensureCollectionAddress(
                                      context,
                                      userId,
                                    );
                                if (!hasCollectionAddress) {
                                  if (context.mounted) {
                                    setSheetState(() => placing = false);
                                  }
                                  return;
                                }
                                final orderId = await OrderService()
                                    .placeCollectionOrder(customerId: userId);
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Order #${orderId.substring(0, 6).toUpperCase()} sent to the boutique.',
                                    ),
                                  ),
                                );
                              } catch (error) {
                                if (!context.mounted) return;
                                setSheetState(() => placing = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Unable to place order: $error',
                                    ),
                                  ),
                                );
                              }
                            },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Text(placing ? 'Sending Order...' : 'Confirm'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _ensureCollectionAddress(
    BuildContext context,
    String userId,
  ) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final snapshot = await userRef.get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final address = Map<String, dynamic>.from(
      data['address'] as Map? ?? const {},
    );
    if (_hasCollectionAddress(address)) return true;
    if (!context.mounted) return false;

    final collectionAddress = await _showCollectionAddressPrompt(context);
    if (collectionAddress == null) return false;

    await userRef.set({
      'address': collectionAddress,
      'accountUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return true;
  }

  bool _hasCollectionAddress(Map<String, dynamic> address) {
    final fields = [
      address['street'],
      address['city'],
      address['state'],
      address['postalCode'],
      address['country'],
      address['pickupPoint'],
    ];
    return fields.any((value) => (value ?? '').toString().trim().isNotEmpty);
  }

  Future<Map<String, dynamic>?> _showCollectionAddressPrompt(
    BuildContext context,
  ) async {
    final streetController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final postalController = TextEditingController();
    final countryController = TextEditingController();
    final pickupController = TextEditingController();
    var usePickupPoint = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Collection details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      selected: {usePickupPoint},
                      onSelectionChanged: (selection) {
                        setDialogState(() => usePickupPoint = selection.first);
                      },
                    ),
                    const SizedBox(height: 14),
                    if (usePickupPoint) ...[
                      TextField(
                        controller: pickupController,
                        decoration: const InputDecoration(
                          labelText: 'Collection point name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    ...[
                      TextField(
                        controller: streetController,
                        decoration: InputDecoration(
                          labelText: usePickupPoint
                              ? 'Collection point street address'
                              : 'Street address',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: stateController,
                        decoration: const InputDecoration(
                          labelText: 'State / Province',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: postalController,
                        decoration: const InputDecoration(
                          labelText: 'Postal code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: countryController,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (usePickupPoint) {
                      final pickupPoint = pickupController.text.trim();
                      final street = streetController.text.trim();
                      final city = cityController.text.trim();
                      final country = countryController.text.trim();
                      if (pickupPoint.isEmpty ||
                          street.isEmpty ||
                          city.isEmpty ||
                          country.isEmpty) {
                        return;
                      }
                      Navigator.pop(dialogContext, {
                        'collectionPreference': 'collection_point',
                        'pickupPoint': pickupPoint,
                        'street': street,
                        'city': city,
                        'state': stateController.text.trim(),
                        'postalCode': postalController.text.trim(),
                        'country': country,
                      });
                      return;
                    }

                    final street = streetController.text.trim();
                    final city = cityController.text.trim();
                    final country = countryController.text.trim();
                    if (street.isEmpty || city.isEmpty || country.isEmpty) {
                      return;
                    }
                    Navigator.pop(dialogContext, {
                      'collectionPreference': 'address',
                      'street': street,
                      'city': city,
                      'state': stateController.text.trim(),
                      'postalCode': postalController.text.trim(),
                      'country': country,
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    postalController.dispose();
    countryController.dispose();
    pickupController.dispose();
    return result;
  }
}
