// "Fashion events" and "In fashion news" on the Community feed (E-2, E-3):
// the latest stories the content engine found, as credited link previews.
// Hidden while loading and when there is nothing to show.
import 'package:flutter/material.dart';

import '../../data/models/content_item.dart';
import '../../data/services/content_service.dart';
import 'content_card.dart';

class FashionNewsSection extends StatefulWidget {
  const FashionNewsSection({
    super.key,
    this.source,
    this.clock = DateTime.now,
    this.onOpen = openContentItem,
    this.maxEvents = 3,
    this.maxNews = 5,
  });

  final ContentSource? source;
  final DateTime Function() clock;
  final Future<void> Function(ContentItem item) onOpen;
  final int maxEvents;
  final int maxNews;

  @override
  State<FashionNewsSection> createState() => _FashionNewsSectionState();
}

class _FashionNewsSectionState extends State<FashionNewsSection> {
  late final Future<List<ContentItem>> _items =
      (widget.source ?? ContentService()).latest();

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ContentItem>>(
      future: _items,
      builder: (context, snapshot) {
        final items = snapshot.data;
        if (items == null || items.isEmpty) return const SizedBox.shrink();
        final split = splitByKind(items);
        final events = split.events.take(widget.maxEvents).toList();
        final news = split.news.take(widget.maxNews).toList();
        final now = widget.clock();
        return Column(
          key: const ValueKey('fashion_news'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
