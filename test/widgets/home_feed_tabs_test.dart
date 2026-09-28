import 'package:banigoba/ui/widgets/home_feed_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({
  required HomeFeed selected,
  required ValueChanged<HomeFeed> onSelected,
  double width = 360,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 640)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          bottom: HomeFeedTabs(selected: selected, onSelected: onSelected),
        ),
      ),
    ),
  );
}

void main() {
  test('feeds are My Timeline, Friends, Community in order', () {
    expect(HomeFeed.values.map((feed) => feed.label), [
      'My Timeline',
      'Friends',
      'Community',
    ]);
  });

  testWidgets('shows every feed label at once, without scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(selected: HomeFeed.myTimeline, onSelected: (_) {}, width: 320),
    );

    for (final feed in HomeFeed.values) {
      expect(find.text(feed.label).hitTestable(), findsOneWidget);
    }
    expect(find.byType(Scrollable), findsNothing);
  });

  testWidgets('reports the tapped feed', (tester) async {
    HomeFeed? tapped;
    await tester.pumpWidget(
      _host(selected: HomeFeed.myTimeline, onSelected: (feed) => tapped = feed),
    );

    await tester.tap(find.text('Community'));
    expect(tapped, HomeFeed.community);
  });

  testWidgets('marks only the selected feed as selected', (tester) async {
    await tester.pumpWidget(
      _host(selected: HomeFeed.friends, onSelected: (_) {}),
    );

    final selected = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((semantics) => semantics.properties.selected == true);
    expect(selected, hasLength(1));
  });
}
