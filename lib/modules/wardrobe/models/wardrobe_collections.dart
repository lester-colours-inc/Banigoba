// Collections for clothes in My Clothes (review item W-6): the person's own
// groups such as "Work", "Church" or "Weddings", the same idea as the
// categories for saved looks. A piece is in at most one collection, and
// collections are private to the owner.

/// What the filter row selects besides one collection.
enum CollectionView { all, uncollected }

/// The collection [piece] is in, or '' for none.
String collectionOf(Map<String, dynamic> piece) =>
    (piece['collection'] ?? '').toString().trim();

/// The collections in use across [pieces], A to Z, no repeats (ignoring case).
List<String> collectionsOf(Iterable<Map<String, dynamic>> pieces) {
  final byKey = <String, String>{};
  for (final piece in pieces) {
    final name = collectionOf(piece);
    if (name.isNotEmpty) byKey.putIfAbsent(name.toLowerCase(), () => name);
  }
  return List.unmodifiable(
    byKey.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
  );
}

/// The pieces to show: everything, the ones in no collection, or one
/// collection ([name], matched ignoring case).
List<Map<String, dynamic>> piecesIn(
  Iterable<Map<String, dynamic>> pieces, {
  CollectionView view = CollectionView.all,
  String? name,
}) {
  if (name != null && name.trim().isNotEmpty) {
    final wanted = name.trim().toLowerCase();
    return [
      for (final piece in pieces)
        if (collectionOf(piece).toLowerCase() == wanted) piece,
    ];
  }
  return switch (view) {
    CollectionView.all => List.of(pieces),
    CollectionView.uncollected => [
      for (final piece in pieces)
        if (collectionOf(piece).isEmpty) piece,
    ],
  };
}

/// How many pieces are in [name] (ignoring case).
int countIn(Iterable<Map<String, dynamic>> pieces, String name) =>
    piecesIn(pieces, name: name).length;
