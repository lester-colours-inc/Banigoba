// What a person's Smart Wardrobe says about itself (review item W-10): what
// they wear most, what is sitting unworn, near-duplicates, missing basics and
// weather gaps. Pure functions over the wardrobe's items (the maps the product
// service returns), so the rules are the same everywhere and easy to test.
//
// Everything here is private to the owner and is never compared with other
// people.
import 'package:flutter/foundation.dart';

import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/modules/wardrobe/models/wear_tracking.dart';

/// The kinds of finding, in the order they are shown.
enum InsightKind {
  mostWorn('Your favourites'),
  neverWorn('Still waiting to be worn'),
  notWornLately('Not worn in a while'),
  duplicates('You may have enough of these'),
  missingBasics('Basics that are missing'),
  weatherGaps('Weather you are not covered for');

  const InsightKind(this.title);

  final String title;
}

@immutable
class Insight {
  const Insight({
    required this.kind,
    required this.summary,
    this.pieceIds = const [],
  });

  final InsightKind kind;

  /// One plain sentence, e.g. "4 blue shirts".
  final String summary;

  /// The pieces it is about, so the screen can show them.
  final List<String> pieceIds;
}

/// How many of a category make a reasonable wardrobe; fewer is a gap. Only
/// what most people wear most days, so nothing is nagged that is optional.
const Map<String, int> kEssentialCounts = {
  'tops': 3,
  'bottoms': 2,
  'shoes': 2,
  'outerwear': 1,
};

/// Neutral colours that go with everything.
const Set<String> kNeutralColours = {'black', 'white', 'grey', 'beige'};

/// Weather the wardrobe should cover once it has this many pieces.
const int kWeatherCheckFrom = 6;
const List<String> kWeatherKinds = ['hot', 'mild', 'cool', 'cold', 'rainy'];

/// Pieces of the same kind and colour before it is called a duplicate.
const int kDuplicateAt = 3;

/// How many favourites and unworn pieces to list.
const int kInsightListLimit = 3;

String _text(Object? value) => (value ?? '').toString().trim().toLowerCase();

List<String> _list(Object? value) => [
  if (value is Iterable)
    for (final item in value)
      if (_text(item).isNotEmpty) _text(item),
];

int _wearCount(Map<String, dynamic> piece) =>
    (piece['wearCount'] as num?)?.toInt() ?? 0;

String _idOf(Map<String, dynamic> piece) => (piece['id'] ?? '').toString();

String _nameOf(Map<String, dynamic> piece) {
  final name = (piece['name'] ?? '').toString().trim();
  return name.isEmpty ? 'A piece' : name;
}

String _plural(int count, String noun) {
  if (count == 1) return '1 $noun';
  final plural = noun.endsWith('s') ? noun : '${noun}s';
  return '$count $plural';
}

/// The findings for [wardrobe] as of [now], grouped by kind in display order.
/// Empty when there is nothing worth saying.
List<Insight> analyzeWardrobe(
  Iterable<Map<String, dynamic>> wardrobe, {
  required DateTime now,
}) {
  final pieces = wardrobe.where((piece) => _idOf(piece).isNotEmpty).toList();
  if (pieces.isEmpty) return const [];
  final insights = <Insight>[];

  // Favourites: most worn first.
  final worn = pieces.where((p) => _wearCount(p) > 0).toList()
    ..sort((a, b) => _wearCount(b).compareTo(_wearCount(a)));
  for (final piece in worn.take(kInsightListLimit)) {
    final times = _wearCount(piece);
    insights.add(
      Insight(
        kind: InsightKind.mostWorn,
        summary: '${_nameOf(piece)}: worn ${_plural(times, 'time')}',
        pieceIds: [_idOf(piece)],
      ),
    );
  }

  // Never worn, once owned long enough; and not worn for ages.
  final neverWorn = <Map<String, dynamic>>[];
  final notLately = <Map<String, dynamic>>[];
  for (final piece in pieces) {
    final added = asDateTime(piece['createdAt']);
    final lastWorn = asDateTime(piece['lastWornAt']);
    if (_wearCount(piece) == 0 && lastWorn == null) {
      if (added != null && now.difference(added) >= kNewItemGrace) {
        neverWorn.add(piece);
      }
    } else if (lastWorn != null &&
        now.difference(lastWorn) >= kNotWornNudgeAfter) {
      notLately.add(piece);
    }
  }
  for (final piece in neverWorn.take(kInsightListLimit)) {
    insights.add(
      Insight(
        kind: InsightKind.neverWorn,
        summary: _nameOf(piece),
        pieceIds: [_idOf(piece)],
      ),
    );
  }
  for (final piece in notLately.take(kInsightListLimit)) {
    final status = wearStatus(
      lastWorn: asDateTime(piece['lastWornAt']),
      addedAt: asDateTime(piece['createdAt']),
      now: now,
    );
    insights.add(
      Insight(
        kind: InsightKind.notWornLately,
        summary: '${_nameOf(piece)}: ${status.label.toLowerCase()}',
        pieceIds: [_idOf(piece)],
      ),
    );
  }

  // Near-duplicates: the same kind of piece in the same colour.
  final groups = <String, List<Map<String, dynamic>>>{};
  for (final piece in pieces) {
    final colours = _list(piece['colours']);
    if (colours.isEmpty) continue;
    final kind = _text(piece['subcategory']).isNotEmpty
        ? _text(piece['subcategory'])
        : _text(piece['category']);
    if (kind.isEmpty || kind == 'none' || kind == 'other') continue;
    groups.putIfAbsent('$kind|${colours.first}', () => []).add(piece);
  }
  final duplicateGroups =
      groups.entries.where((e) => e.value.length >= kDuplicateAt).toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));
  for (final entry in duplicateGroups) {
    final parts = entry.key.split('|');
    insights.add(
      Insight(
        kind: InsightKind.duplicates,
        summary: _plural(entry.value.length, '${parts[1]} ${parts[0]}'),
        pieceIds: [for (final piece in entry.value) _idOf(piece)],
      ),
    );
  }

  // Missing basics: too few of the everyday categories, and no neutrals.
  final byCategory = <String, int>{};
  for (final piece in pieces) {
    final category = _text(piece['category']);
    if (category.isNotEmpty) {
      byCategory[category] = (byCategory[category] ?? 0) + 1;
    }
  }
  kEssentialCounts.forEach((category, wanted) {
    final have = byCategory[category] ?? 0;
    if (have >= wanted) return;
    insights.add(
      Insight(
        kind: InsightKind.missingBasics,
        summary: have == 0
            ? 'No $category yet'
            : 'Only ${_plural(have, category == 'tops' ? 'top' : category)} '
                  '(most people want $wanted)',
      ),
    );
  });
  final hasNeutral = pieces.any(
    (piece) => _list(piece['colours']).any(kNeutralColours.contains),
  );
  if (!hasNeutral && pieces.length >= 3) {
    insights.add(
      const Insight(
        kind: InsightKind.missingBasics,
        summary: 'Nothing in black, white, grey or beige to mix with',
      ),
    );
  }

  // Weather gaps, once there is enough to judge from.
  if (pieces.length >= kWeatherCheckFrom) {
    final covered = <String>{
      for (final piece in pieces) ..._list(piece['weatherTags']),
    };
    // Pieces nobody tagged tell us nothing about weather.
    final anyTagged = covered.isNotEmpty;
    if (anyTagged) {
      for (final weather in kWeatherKinds) {
        if (covered.contains(weather)) continue;
        insights.add(
          Insight(
            kind: InsightKind.weatherGaps,
            summary: switch (weather) {
              'hot' => 'Nothing for hot days',
              'mild' => 'Nothing for mild days',
              'cool' => 'Nothing for cool days',
              'cold' => 'Nothing for cold days',
              _ => 'Nothing for rainy days',
            },
          ),
        );
      }
    }
  }

  // Keep the display order of the kinds.
  insights.sort((a, b) => a.kind.index.compareTo(b.kind.index));
  return List.unmodifiable(insights);
}

/// A one-line summary of the wardrobe for the top of the screen.
String wardrobeHeadline(
  Iterable<Map<String, dynamic>> wardrobe,
  List<Insight> insights,
) {
  final count = wardrobe.length;
  if (count == 0) return 'Your wardrobe is empty.';
  final issues = insights
      .where(
        (i) =>
            i.kind != InsightKind.mostWorn && i.kind != InsightKind.weatherGaps,
      )
      .length;
  final pieces = _plural(count, 'piece');
  return issues == 0
      ? '$pieces, and nothing needs attention.'
      : '$pieces, with $issues thing${issues == 1 ? '' : 's'} worth a look.';
}
