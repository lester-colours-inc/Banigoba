import 'package:banigoba/data/models/content_item.dart';
import 'package:banigoba/data/services/content_service.dart';
import 'package:banigoba/ui/widgets/fashion_news_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 28, 12);

ContentItem _item(
  String id,
  String title, {
  bool event = false,
  DateTime? at,
  DateTime? startsAt,
}) => ContentItem.fromMap(id, {
  'startsAt': ?startsAt,
  'title': title,
  'url': 'https://mag.example/$id',
  'imageUrl': '',
  'sourceName': 'Vogue',
  'kind': event ? 'event' : 'news',
  'publishedAt': at ?? DateTime(2026, 10, 28, 9),
});

class _Source implements ContentSource {
  _Source(this.items);
  final List<ContentItem> items;

  @override
  Future<List<ContentItem>> latest({int limit = 60}) async => items;
}

Future<void> _pump(
  WidgetTester tester,
  List<ContentItem> items, {
  Future<void> Function(ContentItem)? onOpen,
  int maxNews = 5,
  List<String> idols = const [],
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: FashionNewsSection(
            source: _Source(items),
            clock: () => _now,
            onOpen: onOpen ?? (_) async {},
            maxNews: maxNews,
            loadIdolNames: () async => idols,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows news with its source and time', (tester) async {
    await _pump(tester, [_item('a', 'Spring runway report')]);

    expect(find.text('In fashion news'), findsOneWidget);
    expect(find.text('Spring runway report'), findsOneWidget);
    expect(find.text('Vogue · 3 h ago'), findsOneWidget);
    expect(find.text('Fashion events'), findsNothing);
  });

  testWidgets('puts events under their own heading with a tag', (tester) async {
    await _pump(tester, [
      _item('e', 'Harare Fashion Week returns', event: true),
      _item('n', 'Spring runway report'),
    ]);

    expect(find.text('Fashion events'), findsOneWidget);
    expect(find.byKey(const ValueKey('event_tag_e')), findsOneWidget);
    expect(find.byKey(const ValueKey('event_tag_n')), findsNothing);
  });

  testWidgets('shows only the newest few stories', (tester) async {
    await _pump(tester, [
      for (var i = 0; i < 8; i += 1)
        _item(
          'n$i',
          'Story $i',
          at: DateTime(2026, 10, 28, 8).add(Duration(minutes: i)),
        ),
    ], maxNews: 3);

    expect(find.text('Story 7'), findsOneWidget);
    expect(find.text('Story 5'), findsOneWidget);
    expect(find.text('Story 4'), findsNothing);
  });

  testWidgets('opens the source when a story is tapped', (tester) async {
    ContentItem? opened;
    await _pump(tester, [
      _item('a', 'Spring runway report'),
    ], onOpen: (item) async => opened = item);

    await tester.tap(find.byKey(const ValueKey('content_a')));

    expect(opened?.url, 'https://mag.example/a');
  });

  testWidgets('is hidden when there is nothing to show', (tester) async {
    await _pump(tester, const []);

    expect(find.byKey(const ValueKey('fashion_news')), findsNothing);
    expect(find.text('In fashion news'), findsNothing);
  });

  testWidgets('shows the date on an event that has one', (tester) async {
    await _pump(tester, [
      _item(
        'e',
        'Gala returns',
        event: true,
        startsAt: DateTime.utc(2026, 11, 12),
      ),
    ]);

    expect(find.byKey(const ValueKey('event_date_e')), findsOneWidget);
    expect(find.text('12 Nov'), findsOneWidget);
  });

  testWidgets('leaves out an event whose day has passed', (tester) async {
    await _pump(tester, [
      _item(
        'old',
        'Gala was a success',
        event: true,
        startsAt: DateTime.utc(2026, 10, 1),
      ),
      _item('n', 'Spring runway report'),
    ]);

    expect(find.byKey(const ValueKey('content_old')), findsNothing);
  });

  group('from your idols', () {
    testWidgets('lists stories that name an idol, above the rest', (
      tester,
    ) async {
      await _pump(
        tester,
        [
          _item('a', 'Rihanna launches a new collection'),
          _item('b', 'Spring runway report'),
        ],
        idols: ['Rihanna'],
      );

      expect(find.text('From your idols'), findsOneWidget);
      final idolsAt = tester.getTopLeft(find.text('From your idols')).dy;
      final newsAt = tester.getTopLeft(find.text('In fashion news')).dy;
      expect(idolsAt, lessThan(newsAt));
    });

    testWidgets('does not repeat a story under both headings', (tester) async {
      await _pump(
        tester,
        [_item('a', 'Rihanna launches a new collection')],
        idols: ['Rihanna'],
      );

      expect(find.byKey(const ValueKey('content_a')), findsOneWidget);
    });

    testWidgets('no heading when no story names an idol', (tester) async {
      await _pump(
        tester,
        [_item('b', 'Spring runway report')],
        idols: ['Rihanna'],
      );

      expect(find.text('From your idols'), findsNothing);
    });

    testWidgets('no heading when the person has no idols', (tester) async {
      await _pump(tester, [_item('a', 'Rihanna launches a collection')]);

      expect(find.text('From your idols'), findsNothing);
    });
  });
}
