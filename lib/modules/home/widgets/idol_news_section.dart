// "In the news" on My Fashion Idols (F-2): the stories whose title names one
// of your idols, as credited link previews. Hidden when there are none.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/home/models/content_item.dart';
import 'package:banigoba/modules/home/services/content_service.dart';
import 'package:banigoba/modules/home/widgets/content_card.dart';

/// Stories shown for each idol.
const int kStoriesPerIdol = 2;

class IdolNewsSection extends StatefulWidget {
  const IdolNewsSection({
    super.key,
    required this.names,
    this.source,
    this.clock = DateTime.now,
    this.onOpen = openContentItem,
  });

  final List<String> names;
  final ContentSource? source;
  final DateTime Function() clock;
  final Future<void> Function(ContentItem item) onOpen;

  @override
  State<IdolNewsSection> createState() => _IdolNewsSectionState();
}

class _IdolNewsSectionState extends State<IdolNewsSection> {
  late final Future<List<ContentItem>> _items =
      (widget.source ?? ContentService()).latest();

  @override
  Widget build(BuildContext context) {
    if (widget.names.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<ContentItem>>(
      future: _items,
      builder: (context, snapshot) {
        final items = snapshot.data;
        if (items == null) return const SizedBox.shrink();
        final about = newsAbout(items, widget.names);
        if (about.isEmpty) return const SizedBox.shrink();
        final now = widget.clock();
        return Column(
          key: const ValueKey('idol_news'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            const Text(
              'In the news',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            for (final entry in about.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final item in entry.value.take(kStoriesPerIdol))
                ContentCard(item: item, now: now, onOpen: widget.onOpen),
            ],
          ],
        );
      },
    );
  }
}
