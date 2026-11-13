// The posts one viewer may see. The database decides: row-level security on
// `posts` lets through the viewer's own posts, public posts, followers-only
// posts of people they follow, and friends-only posts of mutual follows
// (October 2026 review, I-2). So a feed is just "the posts I can read".
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:banigoba/core/offline/local_cache.dart';
import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/modules/social/models/post.dart';

/// Merges lists into one: each post once, newest first.
List<Post> mergeVisiblePosts(Iterable<List<Post>> results) {
  final byId = <String, Post>{
    for (final posts in results)
      for (final post in posts) post.id: post,
  };
  return List.unmodifiable(
    byId.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );
}

/// How many posts a feed loads at once, and how many more each scroll to the
/// end adds.
const int kFeedPageSize = 30;

/// Live list of the newest [limit] posts [viewerId] may see. A feed grows by
/// asking again with a bigger [limit]. [following] and [friends] are accepted
/// for call-site compatibility but unused: who can see what is enforced by the
/// database, not by the query.
///
/// Each result is also saved on the phone (see [loadSavedVisiblePosts]), so
/// the feed can open without a connection.
Stream<List<Post>> watchVisiblePosts({
  required String viewerId,
  Stream<List<String>>? following,
  Stream<List<String>>? friends,
  int limit = kFeedPageSize,
}) {
  return supabase
      .from('posts')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .limit(limit)
      .map((rows) {
        unawaited(_saveVisiblePosts(viewerId, rows));
        return [for (final row in rows) Post.fromRow(row)];
      });
}

/// How many of the newest posts are kept on the phone for offline viewing.
const int kSavedFeedSize = kFeedPageSize * 2;

String _feedCacheKey(String viewerId) => 'feed.$viewerId';

Future<void> _saveVisiblePosts(
  String viewerId,
  List<Map<String, dynamic>> rows,
) {
  final newest = rows.length > kSavedFeedSize
      ? rows.sublist(0, kSavedFeedSize)
      : rows;
  return LocalCache.write(_feedCacheKey(viewerId), newest);
}

/// The posts [viewerId] last saw, newest first, or null if none were saved.
/// Unreadable rows (e.g. from an older app version) are skipped.
Future<List<Post>?> loadSavedVisiblePosts(String viewerId) async {
  final rows = await LocalCache.readRows(_feedCacheKey(viewerId));
  if (rows == null || rows.isEmpty) return null;
  final posts = <Post>[];
  for (final row in rows) {
    try {
      posts.add(Post.fromRow(row));
    } on Object catch (error) {
      debugPrint('Skipping unreadable saved post: $error');
    }
  }
  return posts.isEmpty ? null : mergeVisiblePosts([posts]);
}
