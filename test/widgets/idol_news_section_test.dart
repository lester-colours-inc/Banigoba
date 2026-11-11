import 'package:banigoba/modules/home/models/content_item.dart';
import 'package:banigoba/modules/home/services/content_service.dart';
import 'package:banigoba/modules/home/widgets/idol_news_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 28, 12);

ContentItem _item(String id, String title) => ContentItem.fromMap(id, {
  'title': title,
  'url': 'https://mag.example/$id',
  'sourceName': 'Elle',
  'kind': 'news',
  'publishedAt': DateTime(2026, 10, 28, 9),
});

class _Source implements ContentSource {
  _Source(this.items);
  final List<ContentItem> items;

  @override
  Future<List<ContentItem>> latest({int limit = 60}) async => items;
}

Future<void> _pump(
  WidgetTester tester,
  List<String> names,
  List<ContentItem> items,
) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: IdolNewsSection(
            names: names,
            source: _Source(items),
            clock: () => _now,
            onOpen: (_) async {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the stories that name each idol', (tester) async {
    await _pump(
      tester,
      ['Rihanna', 'Michelle Obama'],
      [
        _item('a', 'Rihanna launches a new collection'),
        _item('b', 'Weather report'),
        _item('c', 'Michelle Obama wears Ankara'),
      ],
    );

    expect(find.text('In the news'), findsOneWidget);
    expect(find.text('Rihanna'), findsOneWidget);
    expect(find.text('Rihanna launches a new collection'), findsOneWidget);
    expect(find.text('Michelle Obama wears Ankara'), findsOneWidget);
    expect(find.text('Weather report'), findsNothing);
  });

  testWidgets('shows at most two stories per idol', (tester) async {
    await _pump(
      tester,
      ['Rihanna'],
      [for (var i = 0; i < 5; i += 1) _item('r$i', 'Rihanna story $i')],
    );

    expect(find.byKey(const ValueKey('content_r0')), findsOneWidget);
    expect(find.byKey(const ValueKey('content_r1')), findsOneWidget);
    expect(find.byKey(const ValueKey('content_r2')), findsNothing);
  });

  testWidgets('is hidden when no story names an idol', (tester) async {
    await _pump(tester, ['Rihanna'], [_item('a', 'Weather report')]);

    expect(find.byKey(const ValueKey('idol_news')), findsNothing);
  });

  testWidgets('is hidden when there are no idols', (tester) async {
    await _pump(tester, const [], [
      _item('a', 'Rihanna launches a collection'),
    ]);

    expect(find.byKey(const ValueKey('idol_news')), findsNothing);
  });
}
