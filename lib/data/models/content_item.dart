// A fashion story or event from the content engine (review items E-2, E-3,
// F-2): a credited link preview. It holds the title, a link to the source's
// own picture, the source's name and the link, never the article, so every
// card opens the source.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Shorter names are too likely to match the wrong person.
const int kMinNameLength = 3;

@immutable
class ContentItem {
  const ContentItem({
    required this.id,
    required this.title,
    required this.url,
    required this.imageUrl,
    required this.sourceName,
    required this.isEvent,
    required this.places,
    required this.topics,
    required this.publishedAt,
  });

  final String id;
  final String title;
  final String url;
  final String imageUrl;
  final String sourceName;
  final bool isEvent;
  final List<String> places;
  final List<String> topics;
  final DateTime publishedAt;

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
      publishedAt: switch (data['publishedAt']) {
        Timestamp(:final seconds) => DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000,
        ),
        final DateTime date => date,
        _ => DateTime.fromMillisecondsSinceEpoch(0),
      },
    );
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

/// Events and news, each newest first.
({List<ContentItem> events, List<ContentItem> news}) splitByKind(
  Iterable<ContentItem> items,
) {
  int newestFirst(ContentItem a, ContentItem b) =>
      b.publishedAt.compareTo(a.publishedAt);
  return (
    events: [
      for (final item in items)
        if (item.isEvent) item,
    ]..sort(newestFirst),
    news: [
      for (final item in items)
        if (!item.isEvent) item,
    ]..sort(newestFirst),
  );
}
