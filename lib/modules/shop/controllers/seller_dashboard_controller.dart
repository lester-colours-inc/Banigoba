// The boutique owner's shop screen: loads and saves the storefront details.
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/shop/models/delivery.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class SellerDashboardController extends GetxController {
  SellerDashboardController({ProfileService? profiles})
    : _profiles = profiles ?? ProfileService();

  final ProfileService _profiles;

  final shopName = TextEditingController();
  final description = TextEditingController();
  final contact = TextEditingController();
  final RxBool loading = true.obs;
  final RxBool saving = false.obs;
  final Rx<DeliverySettings> delivery = const DeliverySettings().obs;

  @override
  void onInit() {
    super.onInit();
    _loadShop();
  }

  @override
  void onClose() {
    shopName.dispose();
    description.dispose();
    contact.dispose();
    super.onClose();
  }

  Future<void> _loadShop() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) return;
    final data = await _profiles.get(user.uid);
    final shop = Map<String, dynamic>.from(data['shop'] as Map? ?? const {});
    shopName.text =
        (shop['name'] ?? data['displayName'] ?? user.displayName ?? '')
            .toString();
    description.text = (shop['description'] ?? '').toString();
    contact.text = (shop['contact'] ?? user.email ?? '').toString();
    delivery.value = DeliverySettings.fromShop(shop);
    if (!isClosed) loading.value = false;
  }

  /// Saves only the delivery settings, leaving the rest of the shop (and its
  /// verification) untouched.
  Future<void> saveDelivery(DeliverySettings settings) async {
    final user = AppAuth.instance.currentUser;
    if (user == null) throw Exception('Sign in first.');
    await _profiles.mergeSection(user.uid, 'shop', {
      'delivery': settings.toMap(),
    });
  }

  Future<void> saveShop() async {
    final user = AppAuth.instance.currentUser;
    if (user == null || saving.value) return;
    if (shopName.text.trim().isEmpty) {
      AppToast.say('Enter your shop or boutique name.');
      return;
    }
    saving.value = true;
    try {
      // Keep verification intact by changing only the editable storefront
      // fields inside the shop section.
      await _profiles.mergeSection(user.uid, 'shop', {
        'name': shopName.text.trim(),
        'description': description.text.trim(),
        'contact': contact.text.trim(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
      if (!isClosed) AppToast.say('Boutique details saved.');
    } finally {
      if (!isClosed) saving.value = false;
    }
  }
}
