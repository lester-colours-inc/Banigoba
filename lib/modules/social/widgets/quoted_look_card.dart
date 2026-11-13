// The look being quoted, as it sits under the quote: a bordered card with
// the author, when they posted, their words and the picture (like X).
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:banigoba/shared/widgets/app_network_image.dart';

/// What the quote composer shows of the look being quoted.
class QuotedLookPreview {
  const QuotedLookPreview({
    required this.authorName,
    required this.timeLabel,
    this.authorAvatarUrl = '',
    this.text = '',
    this.imageUrl = '',
  });

  final String authorName;
  final String authorAvatarUrl;
  final String timeLabel;
  final String text;
  final String imageUrl;
}

class QuotedLookCard extends StatelessWidget {
  const QuotedLookCard({super.key, required this.preview});

  final QuotedLookPreview preview;

  static const double _radius = 16;
  static const double _imageMaxHeight = 260;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = preview.text.trim();
    return Container(
      key: const ValueKey('quoted_look_card'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: colors.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(preview: preview),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
          if (preview.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: _imageMaxHeight),
                child: SizedBox(
                  width: double.infinity,
                  child: AppNetworkImage(
                    preview.imageUrl,
                    height: _imageMaxHeight,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.preview});

  final QuotedLookPreview preview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = TextStyle(color: colors.onSurfaceVariant, fontSize: 15);
    final avatar = preview.authorAvatarUrl;
    return Row(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: colors.surfaceContainerHigh,
          backgroundImage: avatar.isEmpty
              ? null
              : CachedNetworkImageProvider(avatar),
          child: avatar.isEmpty
              ? Icon(Icons.person, size: 14, color: colors.onSurfaceVariant)
              : null,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            preview.authorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        if (preview.timeLabel.isNotEmpty)
          Text(' · ${preview.timeLabel}', style: muted),
      ],
    );
  }
}
