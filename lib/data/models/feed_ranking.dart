// How the feeds are ordered (review items A-5, P-5, A-4):
//   people I follow (and me) first, then people in my city, then everyone
//   else, newest first within each group.
//
// It is a boost rather than three strict lists, so a month-old post from
// someone I follow cannot bury today's posts for ever: a followed author's
// post counts as [kFollowBonus] newer than it is, a nearby author's as
// [kNearBonus] newer.
//
// "Near me" means the same city. The city is the one each person chose in
// Settings and is public; nothing finer than a city is ever stored.
import 'post.dart';

/// A followed author's post ranks as if it were this much newer.
const Duration kFollowBonus = Duration(days: 7);

/// A post from someone in my city ranks as if it were this much newer.
const Duration kNearBonus = Duration(days: 2);

/// "  Harare, Zimbabwe " → "harare". Empty when there is nothing usable.
String normalizeCity(String? value) {
  final text = (value ?? '').split(',').first.trim().toLowerCase();
  return text;
}

bool _isNear(String author, String viewerCity, Map<String, String> cityOf) =>
    viewerCity.isNotEmpty && normalizeCity(cityOf[author]) == viewerCity;

/// [posts] ordered for [viewerId]. [viewerCity] and the values of [cityOf]
/// are compared after [normalizeCity]; an unknown city never counts as near.
List<Post> rankPosts(
  Iterable<Post> posts, {
  required String viewerId,
  required Set<String> following,
  required Map<String, String> cityOf,
  required String viewerCity,
  required DateTime now,
}) {
  final city = normalizeCity(viewerCity);
  int weight(Post post) {
    final author = post.authorId;
    final bonus = author == viewerId || following.contains(author)
        ? kFollowBonus
        : _isNear(author, city, cityOf)
        ? kNearBonus
        : Duration.zero;
    return post.createdAt.add(bonus).millisecondsSinceEpoch;
  }

  return List.unmodifiable(
    posts.toList()..sort((a, b) => weight(b).compareTo(weight(a))),
  );
}

/// The Community "Near me" view: me, the people I follow and people in my
/// city. Without a city of my own it is just me and the people I follow.
List<Post> nearMe(
  Iterable<Post> posts, {
  required String viewerId,
  required Set<String> following,
  required Map<String, String> cityOf,
  required String viewerCity,
}) {
  final city = normalizeCity(viewerCity);
  return [
    for (final post in posts)
      if (post.authorId == viewerId ||
          following.contains(post.authorId) ||
          _isNear(post.authorId, city, cityOf))
        post,
  ];
}
