// Verifies what the wardrobe says about itself (W-10).
import 'package:banigoba/data/models/wardrobe_insights.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 4);

Map<String, dynamic> _piece(
  String id, {
  String name = '',
  String category = 'tops',
  String subcategory = 'none',
  List<String> colours = const ['blue'],
  List<String> weather = const [],
  int worn = 0,
  DateTime? lastWorn,
  DateTime? added,
}) => {
  'id': id,
  'name': name.isEmpty ? 'Piece $id' : name,
  'category': category,
  'subcategory': subcategory,
  'colours': colours,
  'weatherTags': weather,
  'wearCount': worn,
  'lastWornAt': lastWorn?.toIso8601String(),
  'createdAt': (added ?? DateTime(2026, 1, 1)).toIso8601String(),
};

Iterable<Insight> _of(List<Insight> all, InsightKind kind) =>
    all.where((i) => i.kind == kind);

void main() {
  test('an empty wardrobe has nothing to say', () {
    expect(analyzeWardrobe(const [], now: _now), isEmpty);
    expect(wardrobeHeadline(const [], const []), 'Your wardrobe is empty.');
  });

  test('favourites are the most worn, most first, at most three', () {
    final insights = analyzeWardrobe([
      _piece('a', name: 'Blue shirt', worn: 9),
      _piece('b', worn: 2),
      _piece('c', worn: 5),
      _piece('d', worn: 1),
      _piece('e'),
    ], now: _now);

    final favourites = _of(insights, InsightKind.mostWorn).toList();
    expect(favourites, hasLength(kInsightListLimit));
    expect(favourites.first.summary, 'Blue shirt: worn 9 times');
    expect(favourites.first.pieceIds, ['a']);
  });

  test('a piece owned a while and never worn is flagged; a new one is not', () {
    final insights = analyzeWardrobe([
      _piece('old', name: 'Red dress', added: DateTime(2026, 8, 1)),
      _piece('new', name: 'New hat', added: DateTime(2026, 11, 1)),
    ], now: _now);

    final waiting = _of(insights, InsightKind.neverWorn).toList();
    expect(waiting.map((i) => i.summary), ['Red dress']);
  });

  test('a piece not worn for six months or more is flagged', () {
    final insights = analyzeWardrobe([
      _piece('a', name: 'Linen shirt', worn: 3, lastWorn: DateTime(2026, 3, 1)),
      _piece('b', name: 'Jeans', worn: 3, lastWorn: DateTime(2026, 10, 20)),
    ], now: _now);

    final lately = _of(insights, InsightKind.notWornLately).toList();
    expect(lately, hasLength(1));
    expect(lately.single.summary, startsWith('Linen shirt: not worn in'));
  });

  test('three of the same kind and colour are called out', () {
    final insights = analyzeWardrobe([
      for (var i = 0; i < 4; i++)
        _piece('s$i', subcategory: 'shirts', colours: ['blue']),
      _piece('x', subcategory: 'shirts', colours: ['red']),
    ], now: _now);

    final duplicates = _of(insights, InsightKind.duplicates).toList();
    expect(duplicates.single.summary, '4 blue shirts');
    expect(duplicates.single.pieceIds, hasLength(4));
  });

  test('too few everyday pieces are named as missing basics', () {
    final insights = analyzeWardrobe([
      _piece('a'),
      _piece('b'),
      _piece('c'),
      _piece('d', category: 'bottoms'),
    ], now: _now);

    final missing = _of(
      insights,
      InsightKind.missingBasics,
    ).map((i) => i.summary);
    expect(missing, contains('Only 1 bottoms (most people want 2)'));
    expect(missing, contains('No shoes yet'));
    expect(missing, contains('No outerwear yet'));
    expect(missing.any((s) => s.startsWith('Only 3 top')), isFalse);
  });

  test('no neutral colours is a missing basic', () {
    final insights = analyzeWardrobe([
      _piece('a', colours: ['red']),
      _piece('b', colours: ['green']),
      _piece('c', colours: ['pink']),
    ], now: _now);

    expect(
      _of(insights, InsightKind.missingBasics).map((i) => i.summary),
      contains('Nothing in black, white, grey or beige to mix with'),
    );
  });

  test('weather gaps appear only with enough pieces and some tags', () {
    List<Map<String, dynamic>> many(List<String> weather) => [
      for (var i = 0; i < 6; i++) _piece('p$i', weather: weather),
    ];

    final gaps = _of(
      analyzeWardrobe(many(['hot', 'mild']), now: _now),
      InsightKind.weatherGaps,
    ).map((i) => i.summary);
    expect(gaps, contains('Nothing for cold days'));
    expect(gaps, contains('Nothing for rainy days'));
    expect(gaps, isNot(contains('Nothing for hot days')));

    // No tags at all: nothing to judge from, so nothing is said.
    expect(
      _of(analyzeWardrobe(many(const []), now: _now), InsightKind.weatherGaps),
      isEmpty,
    );
    // Too few pieces.
    expect(
      _of(
        analyzeWardrobe([
          _piece('a', weather: ['hot']),
        ], now: _now),
        InsightKind.weatherGaps,
      ),
      isEmpty,
    );
  });

  test('findings come in display order', () {
    final insights = analyzeWardrobe([
      _piece('a', worn: 5, added: DateTime(2026, 1, 1)),
      _piece('b', name: 'Idle', added: DateTime(2026, 1, 1)),
    ], now: _now);

    final order = insights.map((i) => i.kind.index).toList();
    expect([...order]..sort(), order);
  });

  test('the headline counts what is worth a look', () {
    final wardrobe = [_piece('a'), _piece('b', name: 'Idle')];
    final insights = analyzeWardrobe(wardrobe, now: _now);

    expect(wardrobeHeadline(wardrobe, insights), startsWith('2 pieces, with'));
  });
}
