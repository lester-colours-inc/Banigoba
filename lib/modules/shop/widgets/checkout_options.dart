// How to get the order (K-3): collect from the shop, or, when the shop
// delivers, have it delivered for the shop's fee. Shows the money as it will
// be charged; the order service works the same numbers out again from the
// shop's saved settings.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/provider/models/commission.dart';
import 'package:banigoba/modules/shop/models/delivery.dart';

class CheckoutOptions extends StatelessWidget {
  const CheckoutOptions({
    super.key,
    required this.itemsTotal,
    required this.settings,
    required this.fulfilment,
    required this.area,
    required this.onFulfilment,
    required this.onArea,
    this.rates = const CommissionRates(),
  });

  final double itemsTotal;
  final DeliverySettings settings;
  final Fulfilment fulfilment;

  /// The area chosen from the shop's list ('' when none).
  final String area;
  final ValueChanged<Fulfilment> onFulfilment;
  final ValueChanged<String> onArea;

  /// The platform's commission, shown as the service fee.
  final CommissionRates rates;

  static String _money(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final delivery = fulfilment == Fulfilment.delivery;
    final quote = quoteDelivery(settings, area: area);
    final needsArea = delivery && settings.areas.isNotEmpty && area.isEmpty;
    final fee = delivery && quote.available ? quote.fee : 0.0;
    final showTotals = !delivery || quote.available;
    final serviceFee = commissionOn(itemsTotal, rates);

    Widget option({
      required Key key,
      required Fulfilment value,
      required String title,
      required String subtitle,
    }) => ListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      selected: fulfilment == value,
      leading: Icon(
        fulfilment == value
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
      ),
      onTap: () => onFulfilment(value),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        option(
          key: const ValueKey('option_collect'),
          value: Fulfilment.collect,
          title: 'Collect from the shop',
          subtitle: 'Pay upon collection',
        ),
        if (settings.delivers)
          option(
            key: const ValueKey('option_delivery'),
            value: Fulfilment.delivery,
            title: 'Deliver to me',
            subtitle: settings.fee == 0
                ? 'Free delivery · Pay on delivery'
                : '${_money(settings.fee)} delivery · Pay on delivery',
          ),
        if (delivery && settings.areas.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in settings.areas)
                ChoiceChip(
                  key: ValueKey('area_$name'),
                  label: Text(name),
                  selected: area.trim().toLowerCase() == name.toLowerCase(),
                  onSelected: (_) => onArea(name),
                ),
            ],
          ),
        ],
        if (needsArea)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Choose your area to see the delivery fee.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        if (delivery && settings.note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              settings.note,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        if (showTotals) ...[
          const SizedBox(height: 12),
          Text('Items: ${_money(itemsTotal)}'),
          Text(
            'Service fee: ${_money(serviceFee)}',
            key: const ValueKey('service_fee_line'),
          ),
          if (delivery) Text('Delivery: ${fee == 0 ? 'Free' : _money(fee)}'),
          Text(
            'Total: ${_money(itemsTotal + serviceFee + fee)}',
            key: const ValueKey('total_line'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }
}
