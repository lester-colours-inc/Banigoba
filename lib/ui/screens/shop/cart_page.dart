// Cart screen for boutique purchases.
//
// Responsibilities:
// - show the signed-in user's cart in real time,
// - display the selected size for sized boutique products,
// - let the user change quantities or remove lines,
// - collect the final collection details before creating an order.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/supabase/app_auth.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../data/models/commission.dart';
import '../../../data/services/platform_settings_service.dart';
import '../../../data/services/private_account_service.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/services/product_service.dart' show productMap;

import '../../../data/models/delivery.dart';
import '../../../data/services/cart_service.dart';
import '../../../data/services/order_service.dart';
import '../../widgets/checkout_options.dart';
import '../../widgets/safe_product_image.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppAuth.instance.currentUser;
    final cart = CartService();
    return Scaffold(
      appBar: AppBar(title: const Text("Cart")),
      body: user == null
          ? const Center(child: Text('Sign in to use your cart.'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: cart.watchCart(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data!;
                if (items.isEmpty) {
                  return const Center(child: Text('Your cart is empty.'));
                }
                return FutureBuilder<Map<String, Map<String, dynamic>>>(
                  future: _loadLiveProducts(items),
                  builder: (context, productSnapshot) {
                    // Cart documents keep a snapshot of product data, but the
                    // live product is loaded too so price display can recover
                    // if older cart rows are missing current fields.
                    final liveProducts =
                        productSnapshot.data ??
                        const <String, Map<String, dynamic>>{};
                    final total = items.fold<double>(0, (totalSoFar, data) {
                      final price = _priceFor(data, liveProducts[data['id']]);
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
                              final data = items[index];
                              final itemId = data['id'].toString();
                              final liveProduct = liveProducts[itemId];
                              final quantity =
                                  (data['quantity'] as num?)?.toInt() ?? 1;
                              final imageUrl =
                                  (data['rawImageUrl'] ??
                                          data['imageUrl'] ??
                                          data['imageURL'] ??
                                          '')
                                      .toString();
                              final price = _priceFor(data, liveProduct);
                              final selectedSize = (data['selectedSize'] ?? '')
                                  .toString();
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: SizedBox(
                                  width: 58,
                                  child: SafeProductImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.contain,
                                    iconSize: 28,
                                  ),
                                ),
                                title: Text(
                                  (data['name'] ?? 'Product').toString(),
                                ),
                                subtitle: Text(
                                  selectedSize.isEmpty
                                      ? '\$${price.toStringAsFixed(2)}'
                                      : 'Size $selectedSize • \$${price.toStringAsFixed(2)}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _setCartQuantity(
                                        context: context,
                                        cart: cart,
                                        userId: user.uid,
                                        productId: itemId,
                                        quantity: quantity - 1,
                                      ),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                    Text('$quantity'),
                                    IconButton(
                                      onPressed: () => _setCartQuantity(
                                        context: context,
                                        cart: cart,
                                        userId: user.uid,
                                        productId: itemId,
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
                                    'Items: \$${total.toStringAsFixed(2)}',
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
                                    _sellerIdOf(items),
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
    List<Map<String, dynamic>> cartItems,
  ) async {
    final products = <String, Map<String, dynamic>>{};
    await Future.wait(
      cartItems.map((item) async {
        final productId = (item['productId'] ?? item['id']).toString();
        final row = await supabase
            .from('products')
            .select()
            .eq('id', productId)
            .maybeSingle();
        if (row != null) products[item['id'].toString()] = productMap(row);
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

  Future<void> _setCartQuantity({
    required BuildContext context,
    required CartService cart,
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    try {
      await cart.setQuantity(
        userId: userId,
        productId: productId,
        quantity: quantity,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to update cart: $error')));
    }
  }

  /// The shop everything in the bag is from ('' when it cannot be told).
  String _sellerIdOf(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return '';
    final data = items.first;
    return (data['shopId'] ?? data['uploaderId'] ?? data['sellerId'] ?? '')
        .toString();
  }

  Future<DeliverySettings> _deliveryFor(String sellerId) async {
    if (sellerId.isEmpty) return const DeliverySettings();
    try {
      final seller = await ProfileService().get(sellerId);
      final shop = seller['shop'];
      return DeliverySettings.fromShop(
        shop is Map ? Map<String, dynamic>.from(shop) : null,
      );
    } on PostgrestException {
      return const DeliverySettings();
    }
  }

  void _showCollectionCheckout(
    BuildContext context,
    String userId,
    double total,
    String sellerId,
  ) {
    final deliveryLoad = Future.wait<Object>([
      _deliveryFor(sellerId),
      PlatformSettingsService().rates(),
    ]);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        var placing = false;
        var fulfilment = Fulfilment.collect;
        var area = '';
        return FutureBuilder<List<Object>>(
          future: deliveryLoad,
          builder: (context, snapshot) {
            final settings =
                (snapshot.data?[0] as DeliverySettings?) ??
                const DeliverySettings();
            final rates =
                (snapshot.data?[1] as CommissionRates?) ??
                const CommissionRates();
            return StatefulBuilder(
              builder: (context, setSheetState) {
                final delivering = fulfilment == Fulfilment.delivery;
                final canConfirm =
                    snapshot.hasData &&
                    (!delivering ||
                        quoteDelivery(settings, area: area).available);
                return SafeArea(
                  child: SingleChildScrollView(
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
                        const SizedBox(height: 10),
                        if (!snapshot.hasData)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          CheckoutOptions(
                            itemsTotal: total,
                            settings: settings,
                            rates: rates,
                            fulfilment: fulfilment,
                            area: area,
                            onFulfilment: (value) => setSheetState(() {
                              fulfilment = value;
                              // With one area to choose from, choose it.
                              if (value == Fulfilment.delivery &&
                                  area.isEmpty &&
                                  settings.areas.length == 1) {
                                area = settings.areas.first;
                              }
                            }),
                            onArea: (value) =>
                                setSheetState(() => area = value),
                          ),
                        const SizedBox(height: 14),
                        FilledButton(
                          key: const ValueKey('confirm_order'),
                          onPressed: placing || !canConfirm
                              ? null
                              : () async {
                                  setSheetState(() => placing = true);
                                  try {
                                    final hasAddress =
                                        await _ensureCollectionAddress(
                                          context,
                                          userId,
                                          deliveryOnly: delivering,
                                        );
                                    if (!hasAddress) {
                                      if (context.mounted) {
                                        setSheetState(() => placing = false);
                                      }
                                      return;
                                    }
                                    final orderId = await OrderService()
                                        .placeCollectionOrder(
                                          customerId: userId,
                                          fulfilment: fulfilment,
                                          deliveryArea: area,
                                        );
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
      },
    );
  }

  Future<bool> _ensureCollectionAddress(
    BuildContext context,
    String userId, {
    bool deliveryOnly = false,
  }) async {
    final account = PrivateAccountService();
    final address = await account.address(userId);
    // Delivery needs the buyer's own street address, not a collection point.
    final suitable = deliveryOnly
        ? (address['street'] ?? '').toString().trim().isNotEmpty &&
              address['collectionPreference'] != 'collection_point'
        : _hasCollectionAddress(address);
    if (suitable) return true;
    if (!context.mounted) return false;

    final collectionAddress = await _showCollectionAddressPrompt(
      context,
      deliveryOnly: deliveryOnly,
    );
    if (collectionAddress == null) return false;

    await account.saveAddress(userId, collectionAddress);
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
    BuildContext context, {
    bool deliveryOnly = false,
  }) async {
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
              title: Text(
                deliveryOnly ? 'Delivery address' : 'Collection details',
              ),
              content: SingleChildScrollView(
                child: Column(
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
                        selected: {usePickupPoint},
                        onSelectionChanged: (selection) {
                          setDialogState(
                            () => usePickupPoint = selection.first,
                          );
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
