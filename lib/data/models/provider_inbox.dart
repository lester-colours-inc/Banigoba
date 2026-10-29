// One list for everything a provider has to answer (S-3): shop orders, design
// requests and hair requests, with the ones needing an answer first.
import 'package:flutter/foundation.dart';

enum InboxKind {
  order('Order', 'Orders'),
  design('Design request', 'Designs'),
  hair('Hair request', 'Hair');

  const InboxKind(this.label, this.filterLabel);

  final String label;
  final String filterLabel;
}

String _text(Object? value) => (value ?? '').toString().trim();

String _statusLabel(String status) => switch (status) {
  'submitted' || 'pending' => 'New',
  'accepted' => 'Accepted',
  'declined' => 'Declined',
  'completed' => 'Completed',
  'ready_for_collection' => 'Ready for collection',
  'collected' => 'Collected',
  'out_for_delivery' => 'Out for delivery',
  'delivered' => 'Delivered',
  'cancelled' => 'Cancelled',
  _ => 'Updated',
};

@immutable
class InboxItem {
  const InboxItem({
    required this.kind,
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.title,
    required this.detail,
    required this.status,
    required this.createdAt,
    this.data = const {},
  });

  final InboxKind kind;
  final String id;
  final String customerId;
  final String customerName;
  final String title;
  final String detail;
  final String status;
  final DateTime? createdAt;

  /// The stored document, for the detail view.
  final Map<String, dynamic> data;

  bool get needsAction => status == 'submitted' || status == 'pending';

  String get statusLabel => _statusLabel(status);

  factory InboxItem.fromOrder(
    String id,
    Map<String, dynamic> data, {
    required DateTime? createdAt,
  }) {
    final items = data['items'] is List ? data['items'] as List : const [];
    final pieces = items.fold<int>(
      0,
      (sum, item) =>
          sum + (item is Map ? (item['quantity'] as num?)?.toInt() ?? 1 : 1),
    );
    final total = (data['total'] as num?)?.toDouble() ?? 0;
    final number = _text(data['orderNumber']);
    return InboxItem(
      kind: InboxKind.order,
      id: id,
      customerId: _text(data['customerId']),
      customerName: _text(data['customerName']).isEmpty
          ? 'Customer'
          : _text(data['customerName']),
      title:
          'Order #${number.isEmpty ? id.substring(0, id.length.clamp(0, 6)) : number}',
      detail: [
        '$pieces ${pieces == 1 ? 'item' : 'items'} · \$${total.toStringAsFixed(2)}',
        if (data['fulfilment'] == 'delivery')
          'Delivery${_text(data['deliveryArea']).isEmpty ? '' : ' to ${_text(data['deliveryArea'])}'}',
      ].join(' · '),
      status: _text(data['status']).isEmpty
          ? 'submitted'
          : _text(data['status']),
      createdAt: createdAt,
      data: data,
    );
  }

  factory InboxItem.fromDesignRequest(
    String id,
    Map<String, dynamic> data, {
    required DateTime? createdAt,
  }) {
    final budget = _text(data['budget']);
    final deadline = _text(data['deadline']);
    return InboxItem(
      kind: InboxKind.design,
      id: id,
      customerId: _text(data['customerId']),
      customerName: _text(data['customerName']).isEmpty
          ? 'Customer'
          : _text(data['customerName']),
      title: _text(data['occasion']).isEmpty
          ? 'Custom design'
          : _text(data['occasion']),
      detail: [
        if (budget.isNotEmpty) 'Budget $budget',
        if (deadline.isNotEmpty) 'by $deadline',
      ].join(' · '),
      status: _text(data['status']).isEmpty ? 'pending' : _text(data['status']),
      createdAt: createdAt,
      data: data,
    );
  }

  factory InboxItem.fromAgentRequest(
    String id,
    Map<String, dynamic> data, {
    required DateTime? createdAt,
  }) {
    final date = _text(data['preferredDate']);
    final budget = _text(data['budget']);
    return InboxItem(
      kind: InboxKind.hair,
      id: id,
      customerId: _text(data['customerId']),
      customerName: _text(data['customerName']).isEmpty
          ? 'Customer'
          : _text(data['customerName']),
      title: _text(data['service']).isEmpty
          ? 'Hair request'
          : _text(data['service']),
      detail: [
        if (date.isNotEmpty) date,
        if (budget.isNotEmpty) 'Budget $budget',
      ].join(' · '),
      status: _text(data['status']).isEmpty ? 'pending' : _text(data['status']),
      createdAt: createdAt,
      data: data,
    );
  }
}

/// Merges the lists into one: items that need an answer first, then newest
/// first, undated last. [only] keeps a single kind.
List<InboxItem> mergeInbox(Iterable<List<InboxItem>> lists, {InboxKind? only}) {
  final merged = [
    for (final list in lists)
      for (final item in list)
        if (only == null || item.kind == only) item,
  ];
  merged.sort((a, b) {
    if (a.needsAction != b.needsAction) return a.needsAction ? -1 : 1;
    final aTime = a.createdAt;
    final bTime = b.createdAt;
    if (aTime == null || bTime == null) {
      if (aTime == bTime) return 0;
      return aTime == null ? 1 : -1;
    }
    return bTime.compareTo(aTime);
  });
  return merged;
}

/// How many items are waiting for an answer.
int openCount(Iterable<InboxItem> items) =>
    items.where((item) => item.needsAction).length;
