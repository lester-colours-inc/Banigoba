import 'package:banigoba/data/models/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 28, 12);

ContentItem _item(
  String title, {
  String kind = 'news',
  DateTime? at,
  String image = 'https://img.example/a.jpg',
}) => ContentItem.fromMap('id-$title', {
  'title': title,
  'url': 'https://mag.example/${title.hashCode}',
  'imageUrl': image,
  'sourceName': 'Vogue',
  'kind': kind,
  'places': ['harare'],
  'topics': ['wedding'],
  'publishedAt': at ?? DateTime(2026, 10, 28, 9),
});

void main() {
  group('ContentItem.fromMap', () {
    test('reads a stored link preview', () {
      final item = _item('Spring report');

      expect(item.id, 'id-Spring report');
      expect(item.title, 'Spring report');
      expect(item.sourceName, 'Vogue');
      expect(item.isEvent, isFalse);
      expect(item.places, ['harare']);
      expect(item.topics, ['wedding']);
      expect(item.hasImage, isTrue);
    });

    test('reads an event, and a missing picture', () {
      final item = _item(
        'Harare Fashion Week returns',
        kind: 'event',
        image: '',
      );

      expect(item.isEvent, isTrue);
      expect(item.hasImage, isFalse);
    });

    test('copes with missing fields', () {
      final item = ContentItem.fromMap('x', const {});

      expect(item.title, '');
      expect(item.sourceName, '');
      expect(item.places, isEmpty);
      expect(item.isEvent, isFalse);
    });
  });

  group('opensSafely', () {
    test('only https and http links open', () {
      expect(
        ContentItem.fromMap('a', {'url': 'https://x.example/a'}).opensSafely,
        isTrue,
      );
      expect(
        ContentItem.fromMap('a', {'url': 'javascript:alert(1)'}).opensSafely,
        isFalse,
      );
      expect(ContentItem.fromMap('a', const {}).opensSafely, isFalse);
    });
  });

  group('mentions', () {
    test('finds a whole name in the title, ignoring case', () {
      final item = _item('Michelle Obama steps out in Ankara');

      expect(item.mentions('michelle obama'), isTrue);
      expect(item.mentions('Michelle Obama'), isTrue);
    });

    test('does not match part of a word or another person', () {
      final item = _item('Jordanian designer wins prize');

      expect(item.mentions('Jordan'), isFalse);
      expect(item.mentions('Michelle Obama'), isFalse);
    });

    test('ignores names that are blank or too short to be reliable', () {
      final item = _item('Ed Sheeran wears Gucci');

      expect(item.mentions(''), isFalse);
      expect(item.mentions('  '), isFalse);
      expect(item.mentions('Ed'), isFalse);
    });

    test('does not treat punctuation in a name as a pattern', () {
      final item = _item('A story about anything');

      expect(item.mentions('a.*'), isFalse);
    });
  });

  group('newsAbout', () {
    test('groups the stories by the idols they mention', () {
      final items = [
        _item('Beyoncé Knowles unveils new line'),
        _item('Rihanna launches collection'),
        _item('Weather report'),
        _item('Beyoncé Knowles at Paris Fashion Week'),
      ];

      final about = newsAbout(items, [
        'Beyoncé Knowles',
        'Rihanna',
        'Nobody Here',
      ]);

      expect(about.keys, ['Beyoncé Knowles', 'Rihanna']);
      expect(about['Beyoncé Knowles'], hasLength(2));
      expect(about['Rihanna'], hasLength(1));
    });

    test('is empty when no idol is mentioned', () {
      expect(newsAbout([_item('Weather report')], ['Rihanna']), isEmpty);
    });
  });

  group('agoLabel', () {
    test('reads in plain words', () {
      expect(
        _item('a', at: DateTime(2026, 10, 28, 11, 59, 30)).agoLabel(_now),
        'Just now',
      );
      expect(
        _item('a', at: DateTime(2026, 10, 28, 11, 40)).agoLabel(_now),
        '20 min ago',
      );
      expect(
        _item('a', at: DateTime(2026, 10, 28, 9)).agoLabel(_now),
        '3 h ago',
      );
      expect(
        _item('a', at: DateTime(2026, 10, 27, 10)).agoLabel(_now),
        'Yesterday',
      );
      expect(
        _item('a', at: DateTime(2026, 10, 24, 10)).agoLabel(_now),
        '4 d ago',
      );
    });

    test('sourceLine credits the source with the time', () {
      expect(
        _item('a', at: DateTime(2026, 10, 28, 9)).sourceLine(_now),
        'Vogue · 3 h ago',
      );
    });
  });

  group('splitByKind', () {
    test('separates events from news, newest first', () {
      final items = [
        _item('old news', at: DateTime(2026, 10, 20)),
        _item(
          'Fashion Week returns',
          kind: 'event',
          at: DateTime(2026, 10, 27),
        ),
        _item('new news', at: DateTime(2026, 10, 28, 9)),
      ];

      final split = splitByKind(items);

      expect(split.news.map((i) => i.title), ['new news', 'old news']);
      expect(split.events.map((i) => i.title), ['Fashion Week returns']);
    });
  });
}
