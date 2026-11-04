// Verifies collections for clothes in My Clothes (W-6).
import 'package:banigoba/data/models/wardrobe_collections.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _piece(String id, [String? collection]) => {
  'id': id,
  if (collection != null) 'collection': collection,
};

void main() {
  final pieces = [
    _piece('a', 'Work'),
    _piece('b', 'weddings'),
    _piece('c', 'work'),
    _piece('d'),
    _piece('e', '  '),
  ];

  test('collections in use, A to Z, once each whatever the case', () {
    expect(collectionsOf(pieces), ['weddings', 'Work']);
    expect(collectionsOf(const []), isEmpty);
  });

  test('a piece with no collection reads as empty', () {
    expect(collectionOf(_piece('x')), '');
    expect(collectionOf(_piece('x', ' Church ')), 'Church');
  });

  test('showing everything keeps every piece', () {
    expect(piecesIn(pieces), hasLength(5));
  });

  test('showing one collection ignores case', () {
    final ids = piecesIn(pieces, name: 'WORK').map((p) => p['id']);
    expect(ids, ['a', 'c']);
  });

  test('showing the uncollected pieces', () {
    final ids = piecesIn(
      pieces,
      view: CollectionView.uncollected,
    ).map((p) => p['id']);
    expect(ids, ['d', 'e']);
  });

  test('counting a collection', () {
    expect(countIn(pieces, 'work'), 2);
    expect(countIn(pieces, 'nothing'), 0);
  });
}
