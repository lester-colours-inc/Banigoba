import 'package:banigoba/data/models/delivery.dart';
import 'package:banigoba/ui/widgets/checkout_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  DeliverySettings settings = const DeliverySettings(),
  double items = 40,
  Fulfilment fulfilment = Fulfilment.collect,
  String area = '',
  ValueChanged<Fulfilment>? onFulfilment,
  ValueChanged<String>? onArea,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CheckoutOptions(
            itemsTotal: items,
            settings: settings,
            fulfilment: fulfilment,
            area: area,
            onFulfilment: onFulfilment ?? (_) {},
            onArea: onArea ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

const _delivers = DeliverySettings(delivers: true, fee: 3, areas: []);
const _inAreas = DeliverySettings(
  delivers: true,
  fee: 2.5,
  areas: ['Avondale', 'Borrowdale'],
  note: 'Same day before 4pm',
);

void main() {
  testWidgets('a shop that does not deliver offers collection only', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byKey(const ValueKey('option_collect')), findsOneWidget);
    expect(find.byKey(const ValueKey('option_delivery')), findsNothing);
    expect(find.text('Service fee: \$8.00'), findsOneWidget);
    expect(find.text('Total: \$48.00'), findsOneWidget);
    expect(find.textContaining('Pay upon collection'), findsOneWidget);
  });

  testWidgets('a shop that delivers offers both, with its fee', (tester) async {
    await _pump(tester, settings: _delivers);

    expect(find.byKey(const ValueKey('option_delivery')), findsOneWidget);
    expect(find.textContaining('\$3.00'), findsWidgets);
  });

  testWidgets('choosing delivery reports it', (tester) async {
    Fulfilment? chosen;
    await _pump(
      tester,
      settings: _delivers,
      onFulfilment: (value) => chosen = value,
    );

    await tester.tap(find.byKey(const ValueKey('option_delivery')));

    expect(chosen, Fulfilment.delivery);
  });

  testWidgets('delivery adds the fee to the total and pays on delivery', (
    tester,
  ) async {
    await _pump(tester, settings: _delivers, fulfilment: Fulfilment.delivery);

    expect(find.text('Items: \$40.00'), findsOneWidget);
    expect(find.text('Delivery: \$3.00'), findsOneWidget);
    expect(find.text('Total: \$51.00'), findsOneWidget);
    expect(find.textContaining('Pay on delivery'), findsOneWidget);
  });

  testWidgets('free delivery says free', (tester) async {
    await _pump(
      tester,
      settings: const DeliverySettings(delivers: true),
      fulfilment: Fulfilment.delivery,
    );

    expect(find.text('Delivery: Free'), findsOneWidget);
    expect(find.text('Total: \$48.00'), findsOneWidget);
  });

  testWidgets('with listed areas the buyer picks one', (tester) async {
    String? picked;
    await _pump(
      tester,
      settings: _inAreas,
      fulfilment: Fulfilment.delivery,
      onArea: (value) => picked = value,
    );

    expect(find.text('Avondale'), findsOneWidget);
    expect(find.text('Borrowdale'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('area_Borrowdale')));

    expect(picked, 'Borrowdale');
  });

  testWidgets('shows the shop\'s note for delivery', (tester) async {
    await _pump(
      tester,
      settings: _inAreas,
      fulfilment: Fulfilment.delivery,
      area: 'Avondale',
    );

    expect(find.text('Same day before 4pm'), findsOneWidget);
  });

  testWidgets(
    'delivery with no area chosen asks for one and shows no fee yet',
    (tester) async {
      await _pump(tester, settings: _inAreas, fulfilment: Fulfilment.delivery);

      expect(find.textContaining('Choose your area'), findsOneWidget);
      expect(find.byKey(const ValueKey('total_line')), findsNothing);
    },
  );

  testWidgets('no area picker when the shop delivers anywhere', (tester) async {
    await _pump(tester, settings: _delivers, fulfilment: Fulfilment.delivery);

    expect(find.byKey(const ValueKey('area_Avondale')), findsNothing);
    expect(find.textContaining('Choose your area'), findsNothing);
  });
}
