// The seller's order list: a live stream plus per-order status updates.
import 'dart:async';

import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/modules/shop/services/order_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class SellerOrdersController extends GetxController {
  SellerOrdersController({OrderService? orders})
    : orderService = orders ?? OrderService();

  final OrderService orderService;

  final String sellerId = AppAuth.instance.currentUser?.uid ?? '';
  final RxList<Map<String, dynamic>> orders = <Map<String, dynamic>>[].obs;
  final RxBool loaded = false.obs;
  final RxBool failed = false.obs;
  // Ids of orders whose status is being saved.
  final RxSet<String> updating = <String>{}.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void onInit() {
    super.onInit();
    if (sellerId.isEmpty) return;
    _sub = orderService.watchSellerOrders(sellerId).listen((rows) {
      failed.value = false;
      orders.assignAll(
        rows.toList()..sort((a, b) {
          final aTime = asDateTime(a['createdAt']);
          final bTime = asDateTime(b['createdAt']);
          return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(
            aTime?.millisecondsSinceEpoch ?? 0,
          );
        }),
      );
      loaded.value = true;
    }, onError: (Object _) => failed.value = true);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> updateStatus(String orderId, String status) async {
    updating.add(orderId);
    try {
      await orderService.updateOrderStatus(orderId: orderId, status: status);
      if (!isClosed) AppToast.say('Order status updated.');
    } catch (error) {
      if (!isClosed) AppToast.say('Unable to update order: $error');
    } finally {
      updating.remove(orderId);
    }
  }
}
