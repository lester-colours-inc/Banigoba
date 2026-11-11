// "Orders & requests": the merged inbox for the roles a provider holds.
import 'dart:async';

import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/provider/models/provider_inbox.dart';
import 'package:banigoba/modules/provider/models/provider_roles.dart';
import 'package:banigoba/modules/provider/services/provider_inbox_service.dart';
import 'package:banigoba/modules/shop/views/seller_orders_page.dart';

class ProviderInboxController extends GetxController {
  ProviderInboxController({required this.roles});

  final List<ProviderRole> roles;
  final ProviderInboxService _service = ProviderInboxService();

  final bool signedIn = AppAuth.instance.currentUser != null;
  final RxList<InboxItem> items = <InboxItem>[].obs;
  final RxBool loaded = false.obs;

  StreamSubscription<List<InboxItem>>? _sub;

  @override
  void onInit() {
    super.onInit();
    final user = AppAuth.instance.currentUser;
    if (user == null) return;
    _sub = _service.watch(user.uid, roles).listen((rows) {
      items.assignAll(rows);
      loaded.value = true;
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void openOrders() => Get.to<void>(() => const SellerOrdersPage());

  Future<void> respond(InboxItem item, String status) => _service.respond(
    item: item,
    status: status,
    providerName: AppAuth.instance.currentUser?.displayName ?? 'Your business',
  );
}
