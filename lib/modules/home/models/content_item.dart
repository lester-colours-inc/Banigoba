// A fashion story or event from the content engine (review items E-2, E-3,
// F-2): a credited link preview. It holds the title, a link to the source's
// own picture, the source's name and the link, never the article, so every
// card opens the source.
import 'package:flutter/foundation.dart';

import 'package:banigoba/core/supabase/rows.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'content_item.freezed.dart';

/// Shorter names are too likely to match the wrong person.
const int kMinNameLength = 3;

@freezed
abstract class ContentItem with _$ContentItem {
  const ContentItem._();

  const factory ContentItem({
    required String id,
    required String title,
    required String url,
    required String imageUrl,
    required String sourceName,
    required bool isEvent,
    required List<String> places,
    required List<String> topics,
    required DateTime publishedAt,

    /// The day an event starts, when its title said so. Null otherwise.
    DateTime? startsAt,
  }) = _ContentItem;

  factory ContentItem.fromMap(String id, Map<String, dynamic> data) {
    List<String> strings(Object? value) => value is Iterable
        ? [for (final entry in value) entry.toString()]
        : const [];
    return ContentItem(
      id: id,
      title: (data['title'] ?? '').toString(),
      url: (data['url'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      sourceName: (data['sourceName'] ?? '').toString(),
      isEvent: data['kind'] == 'event',
      places: strings(data['places']),
      topics: strings(data['topics']),
      publishedAt:
          asDateTime(data['publishedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      startsAt: asDateTime(data['startsAt']),
    );
  }

  /// "12 Nov" for an event with a date, else null.
  String? get dateLabel {
    final date = startsAt;
    if (date == null) return null;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  bool get hasImage => imageUrl.isNotEmpty;

  /// Only web links open; anything else stored by mistake is ignored.
  bool get opensSafely {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }

  /// Whether the title names [name], as a whole phrase, ignoring case.
  bool mentions(String name) {
    final wanted = name.trim();
    if (wanted.length < kMinNameLength) return false;
    return RegExp(
      '(^|[^\\p{L}\\p{N}])${RegExp.escape(wanted)}(\$|[^\\p{L}\\p{N}])',
      caseSensitive: false,
      unicode: true,
    ).hasMatch(title);
  }

  /// "Just now", "20 min ago", "3 h ago", "Yesterday", "4 d ago".
  String agoLabel(DateTime now) {
    final age = now.difference(publishedAt);
    if (age.inMinutes < 1) return 'Just now';
    if (age.inMinutes < 60) return '${age.inMinutes} min ago';
    if (age.inHours < 24) return '${age.inHours} h ago';
    if (age.inDays < 2) return 'Yesterday';
    return '${age.inDays} d ago';
  }

  /// "Vogue · 3 h ago": the credit under a card.
  String sourceLine(DateTime now) => '$sourceName · ${agoLabel(now)}';
}

/// The stories that mention each of [names], keyed by the name; names with
/// no story are left out.
Map<String, List<ContentItem>> newsAbout(
  Iterable<ContentItem> items,
  Iterable<String> names,
) {
  final result = <String, List<ContentItem>>{};
  for (final name in names) {
    final found = [
      for (final item in items)
        if (item.mentions(name)) item,
    ];
    if (found.isNotEmpty) result[name] = found;
  }
  return result;
}

/// Events and news. News is newest first. Events with a date that has not
/// passed come first, soonest first; then events with no date, newest first.
/// An event whose day has gone by is left out.
({List<ContentItem> events, List<ContentItem> news}) splitByKind(
  Iterable<ContentItem> items, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final today = DateTime.utc(clock.year, clock.month, clock.day);
  int newestFirst(ContentItem a, ContentItem b) =>
      b.publishedAt.compareTo(a.publishedAt);
  final events = <ContentItem>[
    for (final item in items)
      if (item.isEvent &&
          (item.startsAt == null || !item.startsAt!.toUtc().isBefore(today)))
        item,
  ];
  final dated = events.where((item) => item.startsAt != null).toList()
    ..sort((a, b) => a.startsAt!.compareTo(b.startsAt!));
  final undated = events.where((item) => item.startsAt == null).toList()
    ..sort(newestFirst);
  return (
    events: [...dated, ...undated],
    news: [
      for (final item in items)
        if (!item.isEvent) item,
    ]..sort(newestFirst),
  );
}
