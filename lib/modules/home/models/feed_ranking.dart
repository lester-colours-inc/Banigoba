// How the feeds are ordered (review items A-5, P-5, A-4):
//   people I follow (and me) first, then people in my city, then everyone
//   else, newest first within each group.
//
// It is a boost rather than three strict lists, so a month-old post from
// someone I follow cannot bury today's posts for ever: a followed author's
// post counts as [kFollowBonus] newer than it is, a nearby author's as
// [kNearBonus] newer.
//
// "Near me" is worked out from the phone's location when the person has
// allowed it (a coarse cell about 22 km wide; see geo_cell.dart), and from the
// city they typed in Settings when either side has no location. Neither is
// ever finer than a district.
import 'package:banigoba/modules/home/models/geo_cell.dart';
import 'package:banigoba/modules/social/models/post.dart';

/// A followed author's post ranks as if it were this much newer.
const Duration kFollowBonus = Duration(days: 7);

/// A post from someone in my city ranks as if it were this much newer.
const Duration kNearBonus = Duration(days: 2);

/// "  Harare, Zimbabwe " → "harare". Empty when there is nothing usable.
String normalizeCity(String? value) {
  final text = (value ?? '').split(',').first.trim().toLowerCase();
  return text;
}

/// Whether [author] is near the viewer. Cells decide when both are known;
/// otherwise the city names are compared. An unknown place is never near.
bool _isNear(
  String author, {
  required String viewerCity,
  required Map<String, String> cityOf,
  required GeoCell? viewerCell,
  required Map<String, GeoCell> cellOf,
}) {
  final theirCell = cellOf[author];
  if (viewerCell != null && theirCell != null) {
    return viewerCell.isNear(theirCell);
  }
  return viewerCity.isNotEmpty && normalizeCity(cityOf[author]) == viewerCity;
}

/// [posts] ordered for [viewerId]. [viewerCity] and the values of [cityOf]
/// are compared after [normalizeCity]; an unknown city never counts as near.
List<Post> rankPosts(
  Iterable<Post> posts, {
  required String viewerId,
  required Set<String> following,
  required Map<String, String> cityOf,
  required String viewerCity,
  GeoCell? viewerCell,
  Map<String, GeoCell> cellOf = const {},
  required DateTime now,
}) {
  final city = normalizeCity(viewerCity);
  int weight(Post post) {
    final author = post.authorId;
    final bonus = author == viewerId || following.contains(author)
        ? kFollowBonus
        : _isNear(
            author,
            viewerCity: city,
            cityOf: cityOf,
            viewerCell: viewerCell,
            cellOf: cellOf,
          )
        ? kNearBonus
        : Duration.zero;
    return post.createdAt.add(bonus).millisecondsSinceEpoch;
  }

  return List.unmodifiable(
    posts.toList()..sort((a, b) => weight(b).compareTo(weight(a))),
  );
}

/// Ranks [posts] one [pageSize] block of the newest-first list at a time and
/// joins the blocks in order. A feed that loads in pages uses this so a page
/// that arrives later is only ever added below what is on screen: ranking
/// everything together would let an older post from someone the viewer
/// follows jump above posts they are reading.
List<Post> rankInPages(
  Iterable<Post> posts, {
  required int pageSize,
  required List<Post> Function(Iterable<Post> page) rankPage,
}) {
  final newestFirst = posts.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return List.unmodifiable([
    for (var start = 0; start < newestFirst.length; start += pageSize)
      ...rankPage(newestFirst.skip(start).take(pageSize)),
  ]);
}

/// The Community "Near me" view: me, the people I follow and people in my
/// place. Without one of my own it is just me and the people I follow.
List<Post> nearMe(
  Iterable<Post> posts, {
  required String viewerId,
  required Set<String> following,
  required Map<String, String> cityOf,
  required String viewerCity,
  GeoCell? viewerCell,
  Map<String, GeoCell> cellOf = const {},
}) {
  final city = normalizeCity(viewerCity);
  return [
    for (final post in posts)
      if (post.authorId == viewerId ||
          following.contains(post.authorId) ||
          _isNear(
            post.authorId,
            viewerCity: city,
            cityOf: cityOf,
            viewerCell: viewerCell,
            cellOf: cellOf,
          ))
        post,
  ];
}
