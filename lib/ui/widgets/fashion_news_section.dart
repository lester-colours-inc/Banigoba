// "From your idols", "Fashion events" and "In fashion news" on the Community
// feed (E-2, E-3, F-2): the latest stories the content engine found, as
// credited link previews. Events with a date come first, soonest first; a
// story that names one of the person's idols is lifted into "From your idols".
// Hidden while loading and when there is nothing to show.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/content_item.dart';
import '../../data/services/content_service.dart';
import '../../data/services/style_lists_service.dart';
import 'content_card.dart';

class FashionNewsSection extends StatefulWidget {
  const FashionNewsSection({
    super.key,
    this.source,
    this.clock = DateTime.now,
    this.onOpen = openContentItem,
    this.maxEvents = 3,
    this.maxNews = 5,
    this.maxIdolStories = 3,
    this.loadIdolNames = _signedInIdolNames,
  });

  final ContentSource? source;
  final DateTime Function() clock;
  final Future<void> Function(ContentItem item) onOpen;
  final int maxEvents;
  final int maxNews;
  final int maxIdolStories;

  /// The names of the person's Fashion Idols; empty when none or signed out.
  final Future<List<String>> Function() loadIdolNames;

  @override
  State<FashionNewsSection> createState() => _FashionNewsSectionState();
}

Future<List<String>> _signedInIdolNames() async {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final idols = await StyleListsService()
        .watch(userId, StyleList.idols)
        .first;
    return [for (final idol in idols) idol.name];
  } on Object {
    return const [];
  }
}

class _FashionNewsData {
  const _FashionNewsData(this.items, this.idols);

  final List<ContentItem> items;
  final List<String> idols;
}

class _FashionNewsSectionState extends State<FashionNewsSection> {
  late final Future<_FashionNewsData> _data = _load();

  Future<_FashionNewsData> _load() async {
    final items = await (widget.source ?? ContentService()).latest();
    final idols = items.isEmpty
        ? const <String>[]
        : await widget.loadIdolNames();
    return _FashionNewsData(items, idols);
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FashionNewsData>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null || data.items.isEmpty) return const SizedBox.shrink();
        final now = widget.clock();

        // A story naming an idol is shown once, under "From your idols".
        final aboutIdols = <ContentItem>[];
        for (final stories in newsAbout(data.items, data.idols).values) {
          for (final story in stories) {
            if (!aboutIdols.contains(story)) aboutIdols.add(story);
          }
        }
        aboutIdols.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        final idolStories = aboutIdols.take(widget.maxIdolStories).toList();
        final shownIds = {for (final story in idolStories) story.id};

        final split = splitByKind(data.items, now: now);
        final events = split.events
            .where((item) => !shownIds.contains(item.id))
            .take(widget.maxEvents)
            .toList();
        final news = split.news
            .where((item) => !shownIds.contains(item.id))
            .take(widget.maxNews)
            .toList();
        return Column(
          key: const ValueKey('fashion_news'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (idolStories.isNotEmpty) ...[
              _heading('From your idols'),
              for (final item in idolStories)
                ContentCard(item: item, now: now, onOpen: widget.onOpen),
            ],
            if (events.isNotEmpty) ...[
              _heading('Fashion events'),
              for (final item in events)
                ContentCard(item: item, now: now, onOpen: widget.onOpen),
            ],
            if (news.isNotEmpty) ...[
              _heading('In fashion news'),
              for (final item in news)
                ContentCard(item: item, now: now, onOpen: widget.onOpen),
            ],
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
