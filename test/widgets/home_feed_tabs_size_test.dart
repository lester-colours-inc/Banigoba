import 'package:banigoba/modules/home/widgets/home_feed_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _labels = ['My Fashion Makeover', 'My Daily Dress Up', 'Community'];

double _sum(List<double> values) => values.fold(0.0, (sum, v) => sum + v);

void main() {
  test('uses the normal size when every label fits', () {
    final layout = feedTabLayout(labels: _labels, width: 900);

    expect(layout.fontSize, kFeedTabFontSize);
  });

  test('shrinks all labels by the same amount when they do not fit', () {
    final layout = feedTabLayout(labels: _labels, width: 500);

    expect(layout.fontSize, lessThan(kFeedTabFontSize));
    expect(layout.fontSize, greaterThanOrEqualTo(kFeedTabMinFontSize));
  });

  test('never goes below the smallest readable size', () {
    final layout = feedTabLayout(labels: _labels, width: 60);

    expect(layout.fontSize, kFeedTabMinFontSize);
  });

  test('a narrower screen never gives a bigger size', () {
    final wide = feedTabLayout(labels: _labels, width: 600);
    final narrower = feedTabLayout(labels: _labels, width: 450);

    expect(narrower.fontSize, lessThanOrEqualTo(wide.fontSize));
  });

  test('the tabs fill the bar exactly, at any width', () {
    for (final width in [60.0, 320.0, 411.0, 900.0]) {
      final layout = feedTabLayout(labels: _labels, width: width);

      expect(_sum(layout.widths), closeTo(width, 0.001));
      expect(
        layout.leftOf(2),
        closeTo(layout.widths[0] + layout.widths[1], 0.001),
      );
    }
  });

  test('each tab is as wide as its label needs', () {
    final layout = feedTabLayout(labels: _labels, width: 411);

    expect(layout.widths[0], greaterThan(layout.widths[1]));
    expect(layout.widths[1], greaterThan(layout.widths[2]));
  });

  test('larger system text gives a smaller fitted size, not overflow', () {
    final normal = feedTabLayout(labels: _labels, width: 600);
    final large = feedTabLayout(
      labels: _labels,
      width: 600,
      textScaler: const TextScaler.linear(1.4),
    );

    expect(large.fontSize, lessThan(normal.fontSize));
  });

  testWidgets('all three tabs are drawn at the same size', (tester) async {
    tester.view.physicalSize = const Size(780, 1200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final controller = TabController(length: 3, vsync: const TestVSync());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HomeFeedTabs(controller: controller)),
      ),
    );

    final sizes = {
      for (final label in _labels)
        tester.widget<Text>(find.text(label)).style!.fontSize,
    };
    expect(sizes, hasLength(1));
  });
}
