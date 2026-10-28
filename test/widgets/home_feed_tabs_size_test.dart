import 'package:banigoba/ui/widgets/home_feed_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _labels = ['My Fashion Makeover', 'My Daily Dress Up', 'Community'];

void main() {
  test('uses the normal size when every label fits', () {
    expect(feedTabFontSize(labels: _labels, tabWidth: 400), kFeedTabFontSize);
  });

  test('shrinks all tabs by the same amount when the widest does not fit', () {
    final narrow = feedTabFontSize(labels: _labels, tabWidth: 110);

    expect(narrow, lessThan(kFeedTabFontSize));
    expect(narrow, greaterThanOrEqualTo(kFeedTabMinFontSize));
  });

  test('never goes below the smallest readable size', () {
    expect(feedTabFontSize(labels: _labels, tabWidth: 20), kFeedTabMinFontSize);
  });

  test('a narrower screen never gives a bigger size', () {
    final wide = feedTabFontSize(labels: _labels, tabWidth: 130);
    final narrower = feedTabFontSize(labels: _labels, tabWidth: 100);

    expect(narrower, lessThanOrEqualTo(wide));
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
