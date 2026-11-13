// The checkout sheet: delivery or collection, the area, paying now or at
// the shop, and placing the order.
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'package:banigoba/modules/provider/models/commission.dart';
import 'package:banigoba/modules/settings/services/platform_settings_service.dart';
import 'package:banigoba/modules/settings/services/private_account_service.dart';
import 'package:banigoba/modules/shop/models/delivery.dart';
import 'package:banigoba/modules/shop/services/order_service.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

/// Asks the buyer for an address; null when they cancel.
typedef AddressPrompt =
    Future<Map<String, dynamic>?> Function({required bool deliveryOnly});

/// What the checkout sheet hands back once the order is placed.
class PlacedOrder {
  const PlacedOrder({
    required this.id,
    required this.total,
    required this.payNow,
  });

  final String id;
  final double total;
  final bool payNow;
}

class CheckoutSheetController extends GetxController {
  CheckoutSheetController({
    required this.userId,
    required this.itemsTotal,
    required this.sellerId,
    required this.askAddress,
  });

  final String userId;
  final double itemsTotal;
  final String sellerId;
  final AddressPrompt askAddress;

  final RxBool loaded = false.obs;
  final Rx<DeliverySettings> settings = const DeliverySettings().obs;
  final Rx<CommissionRates> rates = const CommissionRates().obs;
  final Rx<Fulfilment> fulfilment = Fulfilment.collect.obs;
  final RxString area = ''.obs;
  final RxBool placing = false.obs;

  /// Pay online (Smile&Pay) right after placing, instead of at the shop.
  final RxBool payNow = false.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait<Object>([
      _deliveryFor(sellerId),
      PlatformSettingsService().rates(),
    ]);
    if (isClosed) return;
    settings.value = results[0] as DeliverySettings;
    rates.value = results[1] as CommissionRates;
    loaded.value = true;
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

  bool get delivering => fulfilment.value == Fulfilment.delivery;

  bool get canConfirm =>
      loaded.value &&
      (!delivering ||
          quoteDelivery(settings.value, area: area.value).available);

  void chooseFulfilment(Fulfilment value) {
    fulfilment.value = value;
    // With one area to choose from, choose it.
    if (value == Fulfilment.delivery &&
        area.value.isEmpty &&
        settings.value.areas.length == 1) {
      area.value = settings.value.areas.first;
    }
  }

  void chooseArea(String value) => area.value = value;

  void choosePayNow(bool value) => payNow.value = value;

  /// What the buyer will pay, as the checkout shows it.
  double get total {
    final fee = delivering
        ? quoteDelivery(settings.value, area: area.value).fee
        : 0.0;
    return itemsTotal + commissionOn(itemsTotal, rates.value) + fee;
  }

  Future<void> confirm() async {
    placing.value = true;
    try {
      final hasAddress = await _ensureAddress(deliveryOnly: delivering);
      if (!hasAddress) {
        if (!isClosed) placing.value = false;
        return;
      }
      final orderId = await OrderService().placeCollectionOrder(
        customerId: userId,
        fulfilment: fulfilment.value,
        deliveryArea: area.value,
      );
      if (isClosed) return;
      // The sheet's opener goes on to payment when the buyer chose to pay now.
      Get.back<PlacedOrder>(
        result: PlacedOrder(id: orderId, total: total, payNow: payNow.value),
      );
      AppToast.say(
        'Order #${orderId.substring(0, 6).toUpperCase()} sent to the boutique.',
      );
    } catch (error) {
      if (isClosed) return;
      placing.value = false;
      AppToast.say('Unable to place order: $error');
    }
  }

  Future<bool> _ensureAddress({bool deliveryOnly = false}) async {
    final account = PrivateAccountService();
    final address = await account.address(userId);
    // Delivery needs the buyer's own street address, not a collection point.
    final suitable = deliveryOnly
        ? (address['street'] ?? '').toString().trim().isNotEmpty &&
              address['collectionPreference'] != 'collection_point'
        : _hasCollectionAddress(address);
    if (suitable) return true;
    if (isClosed) return false;

    final collectionAddress = await askAddress(deliveryOnly: deliveryOnly);
    if (collectionAddress == null) return false;

    await account.saveAddress(userId, collectionAddress);
    return true;
  }

  static bool _hasCollectionAddress(Map<String, dynamic> address) {
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
}
