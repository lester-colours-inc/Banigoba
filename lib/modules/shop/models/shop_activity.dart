// The shop's Home timeline: what happened in the shop, newest first.
//
// Built from the rows the seller screens already stream (orders, customer
// conversations and products), so the timeline needs no table of its own.
import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/core/utils/stock_status.dart';
import 'package:banigoba/modules/shop/models/delivery.dart';

/// How many events the Home timeline shows at most.
const int kShopTimelineLimit = 40;

enum ShopActivityKind { orderPlaced, orderUpdated, message, listed }

/// One thing that happened in the shop.
class ShopActivity {
  const ShopActivity({
    required this.kind,
    required this.title,
    required this.detail,
    required this.at,
    required this.refId,
    this.highlight = false,
  });

  final ShopActivityKind kind;
  final String title;
  final String detail;
  final DateTime at;

  /// The order, chat or product id the event is about.
  final String refId;

  /// True when the event still wants the seller's attention (a new order, an
  /// unread message).
  final bool highlight;
}

/// The day an event falls on, for the timeline's day headers.
DateTime activityDay(DateTime at) {
  final local = at.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Every event from [orders], [chats] and [products], newest first, capped
/// at [limit].
List<ShopActivity> buildShopTimeline({
  required Iterable<Map<String, dynamic>> orders,
  required Iterable<Map<String, dynamic>> chats,
  required Iterable<Map<String, dynamic>> products,
  int limit = kShopTimelineLimit,
}) {
  final events = <ShopActivity>[
    for (final order in orders) ..._orderEvents(order),
    for (final chat in chats) ?_messageEvent(chat),
    for (final product in products) ?_listedEvent(product),
  ]..sort((a, b) => b.at.compareTo(a.at));
  return List.unmodifiable(events.take(limit));
}

String _money(Object? value) =>
    '\$${((value as num?)?.toDouble() ?? 0).toStringAsFixed(2)}';

List<ShopActivity> _orderEvents(Map<String, dynamic> order) {
  final id = (order['id'] ?? '').toString();
  final number = (order['orderNumber'] ?? '').toString();
  final label = number.isEmpty ? 'Order' : 'Order #$number';
  final customer = (order['customerName'] ?? 'A customer').toString();
  final status = (order['status'] ?? 'submitted').toString();
  final placedAt = asDateTime(order['createdAt']);
  final history = (order['statusHistory'] as List?) ?? const [];
  return [
    if (placedAt != null)
      ShopActivity(
        kind: ShopActivityKind.orderPlaced,
        title: 'New order from $customer',
        detail: '$label · ${_money(order['total'])}',
        at: placedAt,
        refId: id,
        highlight: status == 'submitted',
      ),
    for (final entry in history)
      if (entry is Map && entry['status'] != 'submitted')
        if (asDateTime(entry['updatedAt']) case final at?)
          ShopActivity(
            kind: ShopActivityKind.orderUpdated,
            title: '$label · ${orderStatusText('${entry['status']}')}',
            detail: customer,
            at: at,
            refId: id,
          ),
  ];
}

ShopActivity? _messageEvent(Map<String, dynamic> chat) {
  final at = asDateTime(chat['lastMessageAt']);
  final text = (chat['lastMessage'] ?? '').toString().trim();
  if (at == null || text.isEmpty) return null;
  final unread = (chat['unreadBySeller'] as num?)?.toInt() ?? 0;
  return ShopActivity(
    kind: ShopActivityKind.message,
    title: (chat['customerName'] ?? 'Customer').toString(),
    detail: text,
    at: at,
    refId: (chat['id'] ?? '').toString(),
    highlight: unread > 0,
  );
}

ShopActivity? _listedEvent(Map<String, dynamic> product) {
  final at = asDateTime(product['createdAt']);
  if (at == null) return null;
  return ShopActivity(
    kind: ShopActivityKind.listed,
    title: 'Listed ${(product['name'] ?? 'a piece')}',
    detail: '${_money(product['price'])} · ${totalStock(product)} in stock',
    at: at,
    refId: (product['id'] ?? '').toString(),
  );
}

/// The numbers at the top of the Home tab.
class ShopPulse {
  const ShopPulse({
    required this.newOrders,
    required this.openOrders,
    required this.unreadChats,
    required this.needsRestock,
  });

  /// Orders the shop has not accepted yet.
  final int newOrders;

  /// Orders not yet collected, delivered or cancelled.
  final int openOrders;

  /// Conversations with a message the shop has not read.
  final int unreadChats;

  /// Pieces that are low or sold out.
  final int needsRestock;
}

ShopPulse shopPulse({
  required Iterable<Map<String, dynamic>> orders,
  required Iterable<Map<String, dynamic>> chats,
  required StockSummary stock,
}) {
  String status(Map<String, dynamic> o) =>
      (o['status'] ?? 'submitted').toString();
  return ShopPulse(
    newOrders: orders.where((o) => status(o) == 'submitted').length,
    openOrders: orders.where((o) => !isOrderFinished(status(o))).length,
    unreadChats: chats
        .where((c) => ((c['unreadBySeller'] as num?)?.toInt() ?? 0) > 0)
        .length,
    needsRestock: stock.low + stock.soldOut,
  );
}
