// Order workflow for boutique checkout.
//
// Converts the current user's bag into an order in one database transaction
// (place_order): stock goes down, the bag empties, the boutique chat gets a
// confirmation and the seller a notification. Checkout is collection-based
// by default, with delivery where the shop offers it.
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/modules/shop/models/delivery.dart';
import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/modules/notifications/services/notification_service.dart';
import 'package:banigoba/modules/shop/services/shop_chat_service.dart';

/// An `orders` row as the screens read it (camelCase fields and an `id`).
Map<String, dynamic> orderMap(Map<String, dynamic> row) {
  final flat = flattenRow(row);
  return {...flat, 'orderId': row['id'], 'statusLabel': row['status_label']};
}

class OrderService {
  final ShopChatService _chatService = ShopChatService();
  final NotificationService _notifications = NotificationService();

  Stream<List<Map<String, dynamic>>> watchSellerOrders(String sellerId) {
    return supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('seller_id', sellerId)
        .map((rows) => [for (final row in rows) orderMap(row)]);
  }

  /// Places the order for everything in the bag, from one shop. By default
  /// the buyer collects; with [fulfilment] delivery the shop's own fee is
  /// added, worked out by the database from the shop's saved settings and
  /// never taken from the app. [deliveryArea] is the area the buyer chose
  /// from the shop's list (ignored for collection). Returns the order id.
  Future<String> placeCollectionOrder({
    required String customerId,
    Fulfilment fulfilment = Fulfilment.collect,
    String deliveryArea = '',
  }) async {
    final id = await supabase.rpc(
      'place_order',
      params: {
        'p_fulfilment': fulfilment.value,
        'p_delivery_area': deliveryArea.trim(),
      },
    );
    return id.toString();
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final sellerId = AppAuth.instance.currentUser?.uid ?? '';
    if (sellerId.isEmpty) return;
    final row = await supabase
        .from('orders')
        .select()
        .eq('id', orderId)
        .maybeSingle();
    if (row == null) throw Exception('Order not found.');
    final order = orderMap(row);
    if ((order['sellerId'] ?? '').toString() != sellerId) {
      throw Exception('You can only update your own boutique orders.');
    }

    final fulfilment = Fulfilment.fromValue(order['fulfilment']);
    if (!statusesFor(fulfilment).contains(status)) {
      throw Exception(
        '${orderStatusLabel(status)} does not apply to this '
        '${fulfilment == Fulfilment.delivery ? 'delivery' : 'collection'} order.',
      );
    }
    final label = orderStatusLabel(status);
    final history = [
      ...((row['status_history'] as List?) ?? const []),
      {
        'status': status,
        'label': label,
        'updatedBy': sellerId,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
    ];
    await supabase
        .from('orders')
        .update({
          'status': status,
          'status_label': label,
          'status_history': history,
        })
        .eq('id', orderId)
        .eq('seller_id', sellerId);

    final chatId = (order['chatId'] ?? '').toString();
    final orderNumber = (order['orderNumber'] ?? orderId.substring(0, 6))
        .toString();
    final shopName = (order['shopName'] ?? 'Boutique').toString();
    final customerId = (order['customerId'] ?? '').toString();
    final text = 'Order #$orderNumber status updated: $label.';
    if (chatId.isNotEmpty) {
      await _chatService.addSystemMessage(
        chatId: chatId,
        text: text,
        unreadForCustomer: true,
        orderId: orderId,
      );
    }
    if (customerId.isNotEmpty) {
      await _notifications.addNotification(
        receiverId: customerId,
        title: shopName,
        body: 'updated your order #$orderNumber: $label.',
        type: 'order_update',
        extraData: {
          'orderId': orderId,
          'chatId': chatId,
          'fromName': shopName,
          'shopName': shopName,
          'sellerId': sellerId,
          'customerId': customerId,
        },
      );
    }
  }

  String orderStatusLabel(String status) => orderStatusText(status);
}
