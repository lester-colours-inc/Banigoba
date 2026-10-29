// Delivery (review item K-3): a shop chooses whether it delivers itself, the
// fee and the areas it covers; the buyer either collects or has it delivered;
// the app tracks the order's status either way. Pure rules, used by checkout,
// the shop's settings and the order service (which recomputes the fee from
// the shop's saved settings, so the app is never trusted with the price).
import 'package:flutter/foundation.dart';

/// The most areas a shop can list.
const int kMaxDeliveryAreas = 20;

enum Fulfilment {
  collect('collect'),
  delivery('delivery');

  const Fulfilment(this.value);

  final String value;

  /// Orders placed before delivery existed have no value: they are collection.
  static Fulfilment fromValue(Object? value) =>
      value == 'delivery' ? Fulfilment.delivery : Fulfilment.collect;
}

double _money(Object? value) {
  final number = value is num
      ? value.toDouble()
      : double.tryParse((value ?? '').toString().trim()) ?? 0;
  if (number.isNaN || number < 0) return 0;
  return (number * 100).round() / 100;
}

String _key(String area) => area.trim().toLowerCase();

@immutable
class DeliverySettings {
  const DeliverySettings({
    this.delivers = false,
    this.fee = 0,
    this.areas = const [],
    this.note = '',
  });

  /// Reads `delivery` from a shop's map. Anything missing means no delivery.
  factory DeliverySettings.fromShop(Map<String, dynamic>? shop) {
    final raw = shop?['delivery'];
    if (raw is! Map) return const DeliverySettings();
    return DeliverySettings.cleaned(
      delivers: raw['delivers'] == true,
      fee: _money(raw['fee']),
      areas: [
        if (raw['areas'] is Iterable)
          for (final area in raw['areas'] as Iterable) area.toString(),
      ],
      note: (raw['note'] ?? '').toString(),
    );
  }

  /// What a shop saves: trimmed, no blanks or repeats, a sane fee.
  factory DeliverySettings.cleaned({
    required bool delivers,
    required double fee,
    required List<String> areas,
    String note = '',
  }) {
    final seen = <String>{};
    final kept = <String>[];
    for (final area in areas) {
      final name = area.trim();
      if (name.isEmpty || !seen.add(_key(name))) continue;
      kept.add(name);
      if (kept.length == kMaxDeliveryAreas) break;
    }
    return DeliverySettings(
      delivers: delivers,
      fee: _money(fee),
      areas: List.unmodifiable(kept),
      note: note.trim(),
    );
  }

  final bool delivers;
  final double fee;

  /// Areas the shop covers. Empty means anywhere the buyer gives an address.
  final List<String> areas;
  final String note;

  Map<String, Object> toMap() => {
    'delivers': delivers,
    'fee': fee,
    'areas': areas,
    'note': note,
  };
}

/// Whether a shop can deliver to an area, and for how much.
@immutable
class DeliveryQuote {
  const DeliveryQuote.available(this.fee) : available = true, reason = '';
  const DeliveryQuote.unavailable(this.reason) : available = false, fee = 0;

  final bool available;
  final double fee;

  /// Why not, in words for the buyer.
  final String reason;
}

DeliveryQuote quoteDelivery(DeliverySettings settings, {required String area}) {
  if (!settings.delivers) {
    return const DeliveryQuote.unavailable('This shop does not deliver.');
  }
  if (settings.areas.isEmpty) return DeliveryQuote.available(settings.fee);
  final wanted = _key(area);
  if (wanted.isNotEmpty && settings.areas.any((a) => _key(a) == wanted)) {
    return DeliveryQuote.available(settings.fee);
  }
  return DeliveryQuote.unavailable(
    'This shop delivers to ${settings.areas.join(', ')}.',
  );
}

class DeliveryUnavailable implements Exception {
  const DeliveryUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

@immutable
class OrderTotals {
  const OrderTotals({required this.items, required this.fee});

  final double items;
  final double fee;

  double get total => items + fee;
}

/// The money for an order: the items, plus the shop's fee for delivery. Throws
/// [DeliveryUnavailable] when delivery was asked for but the shop does not
/// offer it to that area.
OrderTotals orderTotals({
  required double items,
  required Fulfilment fulfilment,
  required DeliverySettings settings,
  required String area,
}) {
  if (fulfilment == Fulfilment.collect) {
    return OrderTotals(items: items, fee: 0);
  }
  final quote = quoteDelivery(settings, area: area);
  if (!quote.available) throw DeliveryUnavailable(quote.reason);
  return OrderTotals(items: items, fee: quote.fee);
}

/// The statuses an order moves through, in order, ending in cancelled.
List<String> statusesFor(Fulfilment fulfilment) => switch (fulfilment) {
  Fulfilment.collect => const [
    'submitted',
    'accepted',
    'ready_for_collection',
    'collected',
    'cancelled',
  ],
  Fulfilment.delivery => const [
    'submitted',
    'accepted',
    'out_for_delivery',
    'delivered',
    'cancelled',
  ],
};

String orderStatusText(String status) => switch (status) {
  'accepted' => 'Accepted by boutique',
  'ready_for_collection' => 'Ready for collection',
  'collected' => 'Collected',
  'out_for_delivery' => 'Out for delivery',
  'delivered' => 'Delivered',
  'cancelled' => 'Cancelled',
  _ => 'Submitted',
};

bool isOrderFinished(String status) =>
    status == 'collected' || status == 'delivered' || status == 'cancelled';
