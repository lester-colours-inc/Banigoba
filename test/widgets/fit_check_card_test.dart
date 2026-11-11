// Verifies the product page's fit check card (K-2).
import 'package:banigoba/modules/profile_details/models/body_profile.dart';
import 'package:banigoba/modules/wardrobe/models/fit_check.dart';
import 'package:banigoba/modules/wardrobe/widgets/fit_check_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _body = BodyProfile(
  clothingSize: 'M',
  measurements: {
    BodyMeasurement.chest: 96,
    BodyMeasurement.waist: 88,
    BodyMeasurement.hips: 100,
  },
);

final _chart = SizeChart.fromProduct({
  'sizeChart': {
    'M': {'chest': 104, 'waist': 86, 'hips': 108},
    'L': {'chest': 112, 'waist': 98, 'hips': 116},
  },
});

Future<void> _pump(
  WidgetTester tester, {
  SizeChart? chart,
  BodyProfile body = _body,
  String selectedSize = 'M',
  List<String> available = const ['M', 'L'],
  ValueChanged<String>? onChoose,
  VoidCallback? onAdd,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: FitCheckCard(
            chart: chart ?? _chart,
            body: body,
            selectedSize: selectedSize,
            availableSizes: available,
            onChooseSize: onChoose ?? (_) {},
            onAddMeasurements: onAdd ?? () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('says it is tight around the waist and shows the numbers', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Size M: tight around the waist'), findsOneWidget);
    expect(find.textContaining('garment 86 cm, you 88 cm'), findsOneWidget);
    expect(find.text('Estimate'), findsOneWidget);
  });

  testWidgets('recommends a better size and lets you choose it', (
    tester,
  ) async {
    String? chosen;
    await _pump(tester, onChoose: (size) => chosen = size);

    expect(find.text('Best size for you: L'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('fit_choose_best')));
    expect(chosen, 'L');
  });

  testWidgets('does not offer a recommended size that is out of stock', (
    tester,
  ) async {
    await _pump(tester, available: const ['M']);

    expect(find.byKey(const ValueKey('fit_choose_best')), findsNothing);
    expect(find.textContaining('out of stock'), findsOneWidget);
  });

  testWidgets('asks for measurements when none are saved', (tester) async {
    var opened = false;
    await _pump(tester, body: const BodyProfile(), onAdd: () => opened = true);

    await tester.tap(find.byKey(const ValueKey('fit_add_measurements')));
    expect(opened, isTrue);
    expect(find.byKey(const ValueKey('fit_headline')), findsNothing);
  });

  testWidgets('without a shop size chart it compares size labels', (
    tester,
  ) async {
    await _pump(tester, chart: SizeChart.empty, selectedSize: 'L');

    expect(find.byKey(const ValueKey('fit_no_chart')), findsOneWidget);
    expect(find.textContaining('bigger than you usually wear'), findsOneWidget);
  });

  testWidgets('with no size chosen it asks you to choose one', (tester) async {
    final shoulders = SizeChart.fromProduct({
      'sizeChart': {
        'S': {'chest': 90},
        'XL': {'chest': 120},
      },
    });
    await _pump(
      tester,
      chart: shoulders,
      selectedSize: '',
      body: const BodyProfile(measurements: {BodyMeasurement.chest: 96}),
    );

    expect(find.text('Choose a size to see how it fits you.'), findsOneWidget);
  });
}
