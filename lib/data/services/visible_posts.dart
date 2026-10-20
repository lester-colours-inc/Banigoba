// The posts one viewer may see, built only from queries the security rules
// can check (October 2026 review, I-2):
//   - their own posts                      authorId == me
//   - public posts                         visibility == public (and the
//                                          legacy isPublic flag)
//   - followers-only posts of people I follow
//                                          authorId == them, visibility ==
//                                          followers
//   - friends-only posts of mutual follows authorId == them, visibility ==
//                                          friends
// The results are merged, de-duplicated and sorted newest first. When who
// the viewer follows changes, the per-author queries are rebuilt.
//
// TODO(feed-scale): one listener per followed author is fine for now; at
// scale, fan posts out to per-user feed documents on the server instead.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post.dart';

/// Merges query results into one list: each post once, newest first.
List<Post> mergeVisiblePosts(Iterable<List<Post>> results) {
  final byId = <String, Post>{
    for (final posts in results)
      for (final post in posts) post.id: post,
  };
  return List.unmodifiable(
    byId.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );
}

/// The queries for [viewerId], given who they follow and who their friends
/// (mutual follows) are. Keys identify each query so results can be kept
/// apart.
Map<String, Query<Map<String, dynamic>>> visiblePostQueries(
  CollectionReference<Map<String, dynamic>> posts, {
  required String viewerId,
  required Set<String> following,
  required Set<String> friends,
}) {
  return {
    'own': posts.where('authorId', isEqualTo: viewerId),
    'public': posts.where('visibility', isEqualTo: PostVisibility.public.value),
    'legacyPublic': posts.where('isPublic', isEqualTo: true),
    for (final author in following)
      if (author != viewerId)
        'followers:$author': posts
            .where('authorId', isEqualTo: author)
            .where('visibility', isEqualTo: PostVisibility.followers.value),
    for (final author in friends)
      if (author != viewerId)
        'friends:$author': posts
            .where('authorId', isEqualTo: author)
            .where('visibility', isEqualTo: PostVisibility.friends.value),
  };
}

/// Live list of every post [viewerId] may see.
Stream<List<Post>> watchVisiblePosts({
  required String viewerId,
  required Stream<List<String>> following,
  required Stream<List<String>> friends,
  FirebaseFirestore? db,
}) {
  final posts = (db ?? FirebaseFirestore.instance).collection('posts');
  final results = <String, List<Post>>{};
  final subscriptions = <String, StreamSubscription<Object?>>{};
  StreamSubscription<List<String>>? followingSub;
  StreamSubscription<List<String>>? friendsSub;
  Set<String>? followingIds;
  Set<String>? friendIds;
  late final StreamController<List<Post>> controller;

  void emitIfReady() {
    final expected = subscriptions.keys;
    if (expected.every(results.containsKey)) {
      controller.add(mergeVisiblePosts(results.values));
    }
  }

  void rebuild() {
    final followingNow = followingIds;
    final friendsNow = friendIds;
    if (followingNow == null || friendsNow == null) return;
    final queries = visiblePostQueries(
      posts,
      viewerId: viewerId,
      following: followingNow,
      friends: friendsNow,
    );
    for (final key in subscriptions.keys.toList()) {
      if (queries.containsKey(key)) continue;
      unawaited(subscriptions.remove(key)?.cancel());
      results.remove(key);
    }
    for (final MapEntry(:key, value: query) in queries.entries) {
      if (subscriptions.containsKey(key)) continue;
      subscriptions[key] = query.snapshots().listen((snapshot) {
        results[key] = snapshot.docs.map(Post.fromFirestore).toList();
        emitIfReady();
      }, onError: controller.addError);
    }
    emitIfReady();
  }

  controller = StreamController<List<Post>>(
    onListen: () {
      followingSub = following.listen((ids) {
        followingIds = ids.toSet();
        rebuild();
      }, onError: controller.addError);
      friendsSub = friends.listen((ids) {
        friendIds = ids.toSet();
        rebuild();
      }, onError: controller.addError);
    },
    onCancel: () async {
      await followingSub?.cancel();
      await friendsSub?.cancel();
      await Future.wait(subscriptions.values.map((sub) => sub.cancel()));
      subscriptions.clear();
      results.clear();
    },
  );
  return controller.stream;
}
