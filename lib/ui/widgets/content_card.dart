// A credited link preview of a fashion story or event (E-2, E-3): the
// source's picture and title, who published it and when. Tapping opens the
// source; nothing is copied.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/content_item.dart';
import 'app_network_image.dart';

Future<void> openContentItem(ContentItem item) async {
  if (!item.opensSafely) return;
  await launchUrl(Uri.parse(item.url), mode: LaunchMode.externalApplication);
}

class ContentCard extends StatelessWidget {
  const ContentCard({
    super.key,
    required this.item,
    required this.now,
    this.onOpen = openContentItem,
  });

  final ContentItem item;
  final DateTime now;
  final Future<void> Function(ContentItem item) onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      key: ValueKey('content_${item.id}'),
      borderRadius: BorderRadius.circular(14),
      onTap: () => onOpen(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 84,
                height: 84,
                child: item.hasImage
                    ? AppNetworkImage(item.imageUrl, fit: BoxFit.cover)
                    : ColoredBox(
                        color: colors.surfaceContainerHighest,
                        child: Icon(
                          item.isEvent ? Icons.event : Icons.article_outlined,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.isEvent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            key: ValueKey('event_tag_${item.id}'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Event',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colors.onPrimary,
                              ),
                            ),
                          ),
                          if (item.dateLabel case final date?) ...[
                            const SizedBox(width: 8),
                            Text(
                              date,
                              key: ValueKey('event_date_${item.id}'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  Text(
                    item.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.sourceLine(now),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.open_in_new, size: 16, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
