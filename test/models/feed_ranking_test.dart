import 'package:banigoba/modules/home/models/feed_ranking.dart';
import 'package:banigoba/modules/home/models/geo_cell.dart';
import 'package:banigoba/modules/social/models/post.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 28, 12);

Post _post(String id, String author, {Duration age = Duration.zero}) => Post(
  id: id,
  authorId: author,
  caption: id,
  commentCount: 0,
  createdAt: _now.subtract(age),
  imageURL: '',
  outfitId: '',
  productIds: const [],
  products: const [],
  visibility: PostVisibility.public,
);

List<String> _ids(List<Post> posts) => [for (final post in posts) post.id];

void main() {
  group('normalizeCity', () {
    test('lower-cases, trims and drops the country', () {
      expect(normalizeCity('  Harare '), 'harare');
      expect(normalizeCity('Harare, Zimbabwe'), 'harare');
      expect(normalizeCity('BULAWAYO'), 'bulawayo');
    });

    test('is empty for nothing', () {
      expect(normalizeCity(null), '');
      expect(normalizeCity('   '), '');
    });
  });

  group('rankPosts', () {
    test('puts people I follow first, even over a newer stranger', () {
      final ranked = rankPosts(
        [
          _post('stranger-new', 'zed', age: const Duration(hours: 1)),
          _post('followed-old', 'rudo', age: const Duration(days: 3)),
        ],
        viewerId: 'me',
        following: {'rudo'},
        cityOf: const {},
        viewerCity: '',
        now: _now,
      );

      expect(_ids(ranked), ['followed-old', 'stranger-new']);
    });

    test('puts people in my city above strangers, below people I follow', () {
      final ranked = rankPosts(
        [
          _post('far', 'zed', age: const Duration(hours: 1)),
          _post('near', 'tino', age: const Duration(days: 1)),
          _post('followed', 'rudo', age: const Duration(days: 2)),
        ],
        viewerId: 'me',
        following: {'rudo'},
        cityOf: {'tino': 'harare', 'zed': 'lagos', 'rudo': 'bulawayo'},
        viewerCity: 'harare',
        now: _now,
      );

      expect(_ids(ranked), ['followed', 'near', 'far']);
    });

    test('a very old followed post does not bury fresh ones for ever', () {
      final ranked = rankPosts(
        [
          _post('fresh-stranger', 'zed', age: const Duration(hours: 2)),
          _post('month-old-followed', 'rudo', age: const Duration(days: 30)),
        ],
        viewerId: 'me',
        following: {'rudo'},
        cityOf: const {},
        viewerCity: '',
        now: _now,
      );

      expect(_ids(ranked), ['fresh-stranger', 'month-old-followed']);
    });

    test('newest first within the same group', () {
      final ranked = rankPosts(
        [
          _post('older', 'rudo', age: const Duration(hours: 5)),
          _post('newer', 'tino', age: const Duration(hours: 1)),
        ],
        viewerId: 'me',
        following: {'rudo', 'tino'},
        cityOf: const {},
        viewerCity: '',
        now: _now,
      );

      expect(_ids(ranked), ['newer', 'older']);
    });

    test('my own posts rank with the people I follow', () {
      final ranked = rankPosts(
        [
          _post('stranger', 'zed', age: const Duration(hours: 1)),
          _post('mine', 'me', age: const Duration(days: 2)),
        ],
        viewerId: 'me',
        following: const {},
        cityOf: const {},
        viewerCity: '',
        now: _now,
      );

      expect(_ids(ranked), ['mine', 'stranger']);
    });

    test('does not guess a city when mine is not set', () {
      final ranked = rankPosts(
        [
          _post('a', 'tino', age: const Duration(hours: 3)),
          _post('b', 'zed', age: const Duration(hours: 1)),
        ],
        viewerId: 'me',
        following: const {},
        cityOf: {'tino': '', 'zed': ''},
        viewerCity: '',
        now: _now,
      );

      expect(_ids(ranked), ['b', 'a']);
    });

    test('an empty feed stays empty', () {
      expect(
        rankPosts(
          const [],
          viewerId: 'me',
          following: const {},
          cityOf: const {},
          viewerCity: 'harare',
          now: _now,
        ),
        isEmpty,
      );
    });
  });

  group('nearMe', () {
    test('keeps people I follow, me, and people in my city', () {
      final posts = [
        _post('mine', 'me'),
        _post('followed', 'rudo'),
        _post('near', 'tino'),
        _post('far', 'zed'),
      ];

      final near = nearMe(
        posts,
        viewerId: 'me',
        following: {'rudo'},
        cityOf: {'tino': 'harare', 'zed': 'lagos'},
        viewerCity: 'harare',
      );

      expect(_ids(near), ['mine', 'followed', 'near']);
    });

    test('with no city of my own it keeps only me and people I follow', () {
      final near = nearMe(
        [_post('followed', 'rudo'), _post('near', 'tino')],
        viewerId: 'me',
        following: {'rudo'},
        cityOf: {'tino': 'harare'},
        viewerCity: '',
      );

      expect(_ids(near), ['followed']);
    });
  });

  group('by location (GPS cells)', () {
    const harare = GeoCell(155, -90);
    const hararePlus = GeoCell(156, -90); // touching
    const bulawayo = GeoCell(143, -101);

    test('someone in a touching cell ranks as near', () {
      final ranked = rankPosts(
        [
          _post('far', 'zed', age: const Duration(hours: 1)),
          _post('near', 'tino', age: const Duration(days: 1)),
        ],
        viewerId: 'me',
        following: const {},
        cityOf: const {},
        viewerCity: '',
        viewerCell: harare,
        cellOf: {'tino': hararePlus, 'zed': bulawayo},
        now: _now,
      );

      expect(_ids(ranked), ['near', 'far']);
    });

    test('the cell wins over a matching city name when both are known', () {
      final ranked = rankPosts(
        [
          _post('same-name-far', 'zed', age: const Duration(hours: 1)),
          _post('close', 'tino', age: const Duration(days: 1)),
        ],
        viewerId: 'me',
        following: const {},
        cityOf: {'zed': 'harare', 'tino': ''},
        viewerCity: 'harare',
        viewerCell: harare,
        cellOf: {'zed': bulawayo, 'tino': hararePlus},
        now: _now,
      );

      expect(_ids(ranked), ['close', 'same-name-far']);
    });

    test('falls back to the city when the author has no location', () {
      final ranked = rankPosts(
        [
          _post('far', 'zed', age: const Duration(hours: 1)),
          _post('same-city', 'tino', age: const Duration(days: 1)),
        ],
        viewerId: 'me',
        following: const {},
        cityOf: {'tino': 'harare'},
        viewerCity: 'harare',
        viewerCell: harare,
        cellOf: const {},
        now: _now,
      );

      expect(_ids(ranked), ['same-city', 'far']);
    });

    test('nearMe keeps people in my cells, me and people I follow', () {
      final near = nearMe(
        [
          _post('mine', 'me'),
          _post('followed', 'rudo'),
          _post('close', 'tino'),
          _post('far', 'zed'),
        ],
        viewerId: 'me',
        following: {'rudo'},
        cityOf: const {},
        viewerCity: '',
        viewerCell: harare,
        cellOf: {'tino': hararePlus, 'zed': bulawayo},
      );

      expect(_ids(near), ['mine', 'followed', 'close']);
    });

    test('with no cell and no city only me and people I follow remain', () {
      final near = nearMe(
        [_post('followed', 'rudo'), _post('close', 'tino')],
        viewerId: 'me',
        following: {'rudo'},
        cityOf: const {},
        viewerCity: '',
        viewerCell: null,
        cellOf: {'tino': hararePlus},
      );

      expect(_ids(near), ['followed']);
    });
  });
}
