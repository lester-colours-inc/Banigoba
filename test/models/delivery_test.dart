import 'package:banigoba/data/models/delivery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeliverySettings.fromShop', () {
    test('a shop with nothing set does not deliver', () {
      expect(DeliverySettings.fromShop(const {}).delivers, isFalse);
      expect(DeliverySettings.fromShop(null).delivers, isFalse);
    });

    test('reads whether it delivers, the fee, the areas and the note', () {
      final settings = DeliverySettings.fromShop({
        'delivery': {
          'delivers': true,
          'fee': 3.5,
          'areas': ['Avondale', 'Borrowdale'],
          'note': 'Same day before 4pm',
        },
      });

      expect(settings.delivers, isTrue);
      expect(settings.fee, 3.5);
      expect(settings.areas, ['Avondale', 'Borrowdale']);
      expect(settings.note, 'Same day before 4pm');
    });

    test('copes with strings, junk and negative fees', () {
      final settings = DeliverySettings.fromShop({
        'delivery': {
          'delivers': true,
          'fee': '2.50',
          'areas': ['  Avondale ', '', 7],
        },
      });
      expect(settings.fee, 2.5);
      expect(settings.areas, ['Avondale', '7']);

      expect(
        DeliverySettings.fromShop({
          'delivery': {'delivers': true, 'fee': -4},
        }).fee,
        0,
      );
    });
  });

  group('DeliverySettings.cleaned', () {
    test(
      'trims, drops blanks and repeats (ignoring case) and caps the list',
      () {
        final cleaned = DeliverySettings.cleaned(
          delivers: true,
          fee: 2,
          areas: [
            ' Avondale',
            'avondale ',
            '',
            'Borrowdale',
            for (var i = 0; i < 40; i += 1) 'Area $i',
          ],
        );

        expect(cleaned.areas.first, 'Avondale');
        expect(cleaned.areas[1], 'Borrowdale');
        expect(cleaned.areas.length, kMaxDeliveryAreas);
      },
    );

    test('rounds the fee to cents and never goes below zero', () {
      expect(
        DeliverySettings.cleaned(
          delivers: true,
          fee: 2.499,
          areas: const [],
        ).fee,
        2.5,
      );
      expect(
        DeliverySettings.cleaned(delivers: true, fee: -1, areas: const []).fee,
        0,
      );
    });

    test('toMap holds what the shop saved', () {
      final map = DeliverySettings.cleaned(
        delivers: true,
        fee: 3,
        areas: const ['Avondale'],
        note: ' Call first ',
      ).toMap();

      expect(map, {
        'delivers': true,
        'fee': 3.0,
        'areas': ['Avondale'],
        'note': 'Call first',
      });
    });
  });

  group('quoteDelivery', () {
    const everywhere = DeliverySettings(delivers: true, fee: 2, areas: []);
    const some = DeliverySettings(
      delivers: true,
      fee: 2.5,
      areas: ['Avondale', 'Borrowdale'],
    );

    test('a shop that does not deliver cannot', () {
      final quote = quoteDelivery(const DeliverySettings(), area: 'Avondale');

      expect(quote.available, isFalse);
      expect(quote.reason, contains('does not deliver'));
    });

    test('no listed areas means anywhere the buyer gives an address', () {
      expect(quoteDelivery(everywhere, area: 'Anywhere').available, isTrue);
      expect(quoteDelivery(everywhere, area: '').available, isTrue);
      expect(quoteDelivery(everywhere, area: '').fee, 2);
    });

    test(
      'with listed areas the buyer must be in one, ignoring case and spacing',
      () {
        expect(quoteDelivery(some, area: ' avondale ').available, isTrue);
        expect(quoteDelivery(some, area: 'Borrowdale').fee, 2.5);
        final outside = quoteDelivery(some, area: 'Mbare');
        expect(outside.available, isFalse);
        expect(outside.reason, contains('Avondale'));
      },
    );

    test('with listed areas, no area chosen is not available', () {
      expect(quoteDelivery(some, area: '').available, isFalse);
    });
  });

  group('orderTotals', () {
    const settings = DeliverySettings(delivers: true, fee: 3, areas: []);

    test('collection has no fee', () {
      final totals = orderTotals(
        items: 40,
        fulfilment: Fulfilment.collect,
        settings: settings,
        area: '',
      );

      expect(totals.fee, 0);
      expect(totals.total, 40);
    });

    test('delivery adds the shop\'s fee', () {
      final totals = orderTotals(
        items: 40,
        fulfilment: Fulfilment.delivery,
        settings: settings,
        area: 'Avondale',
      );

      expect(totals.fee, 3);
      expect(totals.total, 43);
    });

    test('delivery the shop does not offer is refused', () {
      expect(
        () => orderTotals(
          items: 40,
          fulfilment: Fulfilment.delivery,
          settings: const DeliverySettings(),
          area: 'Avondale',
        ),
        throwsA(isA<DeliveryUnavailable>()),
      );
    });
  });

  group('order statuses', () {
    test('collection ends in collected, delivery in delivered', () {
      expect(statusesFor(Fulfilment.collect), [
        'submitted',
        'accepted',
        'ready_for_collection',
        'collected',
        'cancelled',
      ]);
      expect(statusesFor(Fulfilment.delivery), [
        'submitted',
        'accepted',
        'out_for_delivery',
        'delivered',
        'cancelled',
      ]);
    });

    test('labels are in plain words', () {
      expect(orderStatusText('out_for_delivery'), 'Out for delivery');
      expect(orderStatusText('delivered'), 'Delivered');
      expect(orderStatusText('ready_for_collection'), 'Ready for collection');
      expect(orderStatusText('collected'), 'Collected');
      expect(orderStatusText('accepted'), 'Accepted by boutique');
      expect(orderStatusText('cancelled'), 'Cancelled');
      expect(orderStatusText('submitted'), 'Submitted');
      expect(orderStatusText('anything else'), 'Submitted');
    });

    test('an order is finished once collected, delivered or cancelled', () {
      expect(isOrderFinished('collected'), isTrue);
      expect(isOrderFinished('delivered'), isTrue);
      expect(isOrderFinished('cancelled'), isTrue);
      expect(isOrderFinished('out_for_delivery'), isFalse);
    });

    test('an old order with no fulfilment is a collection', () {
      expect(Fulfilment.fromValue(null), Fulfilment.collect);
      expect(Fulfilment.fromValue('delivery'), Fulfilment.delivery);
      expect(Fulfilment.fromValue('junk'), Fulfilment.collect);
    });
  });
}
