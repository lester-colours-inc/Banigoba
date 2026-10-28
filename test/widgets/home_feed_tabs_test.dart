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

Rect _indicator(WidgetTester tester) =>
    tester.getRect(find.byKey(const ValueKey('home_feed_indicator')));

Rect _tab(WidgetTester tester, HomeFeed feed) => tester.getRect(
  find.ancestor(of: find.text(feed.label), matching: find.byType(InkWell)),
);

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

  testWidgets('the capsule sits behind the selected feed', (tester) async {
    await tester.pumpWidget(_host(initial: HomeFeed.community));

    final capsule = _indicator(tester);
    final tab = _tab(tester, HomeFeed.community);
    expect(capsule.left, closeTo(tab.left, 0.5));
    expect(capsule.width, closeTo(tab.width, 0.5));
  });

  testWidgets('longer feed names get wider tabs', (tester) async {
    await tester.pumpWidget(_host());

    expect(
      _tab(tester, HomeFeed.myMakeover).width,
      greaterThan(_tab(tester, HomeFeed.community).width),
    );
  });

  testWidgets('the capsule follows the finger mid-swipe', (tester) async {
    await tester.pumpWidget(_host(withFeeds: true));
    final first = _tab(tester, HomeFeed.myMakeover);
    final second = _tab(tester, HomeFeed.dailyDressUp);

    final gesture = await tester.startGesture(const Offset(300, 300));
    await gesture.moveBy(const Offset(-20, 0)); // past the drag slop
    await gesture.moveBy(const Offset(-90, 0));
    await tester.pump();

    final capsule = _indicator(tester);
    expect(capsule.left, inExclusiveRange(first.left, second.left));
    expect(
      capsule.width,
      inExclusiveRange(
        [first.width, second.width].reduce((a, b) => a < b ? a : b),
        [first.width, second.width].reduce((a, b) => a > b ? a : b),
      ),
    );

    await gesture.up();
    await tester.pumpAndSettle();
    // Let go short of halfway: the feed, and the capsule, spring back.
    expect(_indicator(tester).left, closeTo(first.left, 0.5));
  });
}
