import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:banigoba/core/offline/local_cache.dart';
import 'package:banigoba/modules/social/services/visible_posts.dart';

Map<String, dynamic> _row(String id, String createdAt) => {
  'id': id,
  'author_id': 'author-$id',
  'caption': 'Look $id',
  'image_url': 'https://example.com/$id.jpg',
  'created_at': createdAt,
  'visibility': 'public',
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LocalCache', () {
    test('returns null for a key that was never saved', () async {
      expect(await LocalCache.read('missing'), isNull);
      expect(await LocalCache.readMap('missing'), isNull);
      expect(await LocalCache.readRows('missing'), isNull);
    });

    test('round-trips maps and rows', () async {
      await LocalCache.write('profile.u1', {'id': 'u1', 'city': 'Harare'});
      await LocalCache.write('rows', [
        {'id': 'a'},
        'not a row',
        {'id': 'b'},
      ]);

      expect(await LocalCache.readMap('profile.u1'), {
        'id': 'u1',
        'city': 'Harare',
      });
      expect(await LocalCache.readRows('rows'), [
        {'id': 'a'},
        {'id': 'b'},
      ]);
    });

    test('ignores unreadable saved text', () async {
      SharedPreferences.setMockInitialValues({'offline_cache.bad': '{oops'});
      expect(await LocalCache.read('bad'), isNull);
    });

    test('clear removes only cached entries', () async {
      SharedPreferences.setMockInitialValues({'dark_mode_enabled': true});
      await LocalCache.write('feed.u1', [_row('1', '2026-11-01T00:00:00Z')]);

      await LocalCache.clear();

      final prefs = await SharedPreferences.getInstance();
      expect(await LocalCache.read('feed.u1'), isNull);
      expect(prefs.getBool('dark_mode_enabled'), isTrue);
    });
  });

  group('isNetworkError', () {
    test('treats timeouts and connection failures as offline', () {
      expect(isNetworkError(TimeoutException('slow')), isTrue);
      expect(isNetworkError(Exception('Failed host lookup')), isTrue);
      expect(isNetworkError(AuthRetryableFetchException()), isTrue);
    });

    test('treats server answers as not offline', () {
      expect(
        isNetworkError(const PostgrestException(message: 'denied')),
        isFalse,
      );
      expect(isNetworkError(const AuthException('bad token')), isFalse);
    });
  });

  group('loadSavedVisiblePosts', () {
    test('is null when nothing was saved for the viewer', () async {
      expect(await loadSavedVisiblePosts('u1'), isNull);
    });

    test('returns the saved posts newest first', () async {
      await LocalCache.write('feed.u1', [
        _row('old', '2026-10-01T00:00:00Z'),
        _row('new', '2026-11-10T00:00:00Z'),
      ]);

      final posts = await loadSavedVisiblePosts('u1');

      expect(posts?.map((post) => post.id), ['new', 'old']);
      expect(posts?.first.imageURL, 'https://example.com/new.jpg');
    });

    test('keeps each viewer\'s saved feed apart', () async {
      await LocalCache.write('feed.u1', [_row('1', '2026-11-01T00:00:00Z')]);
      expect(await loadSavedVisiblePosts('u2'), isNull);
    });
  });
}
