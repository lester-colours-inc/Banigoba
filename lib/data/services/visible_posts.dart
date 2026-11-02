// The posts one viewer may see. The database decides: row-level security on
// `posts` lets through the viewer's own posts, public posts, followers-only
// posts of people they follow, and friends-only posts of mutual follows
// (October 2026 review, I-2). So a feed is just "the posts I can read".
import 'dart:async';

import '../../core/supabase/supabase_config.dart';
import '../models/post.dart';

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

/// How many posts a feed loads at once.
const int kFeedPageSize = 100;

/// Live list of the newest posts [viewerId] may see. [following] and
/// [friends] are accepted for call-site compatibility but unused: who can see
/// what is enforced by the database, not by the query.
Stream<List<Post>> watchVisiblePosts({
  required String viewerId,
  Stream<List<String>>? following,
  Stream<List<String>>? friends,
}) {
  return supabase
      .from('posts')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .limit(kFeedPageSize)
      .map((rows) => [for (final row in rows) Post.fromRow(row)]);
}
