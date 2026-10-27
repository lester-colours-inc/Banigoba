import 'package:banigoba/ui/widgets/home_feed_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({
  HomeFeed initial = HomeFeed.myMakeover,
  double width = 360,
  bool withFeeds = false,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 640)),
      child: DefaultTabController(
        length: HomeFeed.values.length,
        initialIndex: initial.index,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Home'),
            bottom: const HomeFeedTabs(),
          ),
          body: withFeeds
              ? TabBarView(
                  children: [
                    for (final feed in HomeFeed.values)
                      Center(child: Text('${feed.label} feed')),
                  ],
                )
              : null,
        ),
      ),
    ),
  );
}

HomeFeed _shown(WidgetTester tester) =>
    HomeFeed.values[DefaultTabController.of(
      tester.element(find.byType(HomeFeedTabs)),
    ).index];

Iterable<String> _selectedLabels(WidgetTester tester) => tester
    .widgetList<Semantics>(find.byType(Semantics))
    .where((semantics) => semantics.properties.selected == true)
    .map(
      (semantics) => tester
          .widget<Text>(
            find.descendant(
              of: find.byWidget(semantics),
              matching: find.byType(Text),
            ),
          )
          .data!,
    );

double _underlineWidth(WidgetTester tester, HomeFeed feed) {
  final tab = find.ancestor(
    of: find.text(feed.label),
    matching: find.byType(InkWell),
  );
  final underline = find.descendant(
    of: tab,
    matching: find.byWidgetPredicate(
      (widget) => widget is Container && widget.constraints?.maxHeight == 3,
    ),
  );
  return tester.getSize(underline).width;
}

void main() {
  test('feeds are My Fashion Makeover, My Daily Dress Up, Community', () {
    expect(HomeFeed.values.map((feed) => feed.label), [
      'My Fashion Makeover',
      'My Daily Dress Up',
      'Community',
    ]);
  });

  testWidgets('shows every feed label at once, without scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(_host(width: 320));

    for (final feed in HomeFeed.values) {
      expect(find.text(feed.label).hitTestable(), findsOneWidget);
    }
    expect(find.byType(Scrollable), findsNothing);
  });

  testWidgets('tapping a feed shows it', (tester) async {
    await tester.pumpWidget(_host(withFeeds: true));

    await tester.tap(find.text('Community'));
    await tester.pumpAndSettle();

    expect(_shown(tester), HomeFeed.community);
    expect(find.text('Community feed'), findsOneWidget);
    expect(_selectedLabels(tester), ['Community']);
  });

  testWidgets('marks only the selected feed as selected', (tester) async {
    await tester.pumpWidget(_host(initial: HomeFeed.dailyDressUp));

    expect(_selectedLabels(tester), ['My Daily Dress Up']);
  });

  testWidgets('swiping the feed switches to the next one', (tester) async {
    await tester.pumpWidget(_host(withFeeds: true));

    await tester.fling(
      find.text('My Fashion Makeover feed'),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(_shown(tester), HomeFeed.dailyDressUp);
    expect(find.text('My Daily Dress Up feed'), findsOneWidget);
    expect(_selectedLabels(tester), ['My Daily Dress Up']);
  });

  testWidgets('the underline follows the finger mid-swipe', (tester) async {
    await tester.pumpWidget(_host(withFeeds: true));

    final gesture = await tester.startGesture(const Offset(300, 300));
    await gesture.moveBy(const Offset(-20, 0)); // past the drag slop
    await gesture.moveBy(const Offset(-90, 0));
    await tester.pump();

    final leaving = _underlineWidth(tester, HomeFeed.myMakeover);
    final arriving = _underlineWidth(tester, HomeFeed.dailyDressUp);
    expect(leaving, inExclusiveRange(0, 56));
    expect(arriving, inExclusiveRange(0, 56));
    expect(leaving + arriving, closeTo(56, 0.5));
    expect(_underlineWidth(tester, HomeFeed.community), 0);

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
