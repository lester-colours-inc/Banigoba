// Chat bubbles that carry a product, a look or a design request.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/shop/models/chat_format.dart';
import 'package:banigoba/modules/shop/widgets/chat_basics.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

class ProductReferenceMessage extends StatelessWidget {
  const ProductReferenceMessage({
    required this.data,
    required this.mine,
    required this.timestamp,
  });

  final Map<String, dynamic> data;
  final bool mine;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    final imageUrl = (data['productImageUrl'] ?? '').toString();
    final productName = (data['productName'] ?? 'This product').toString();
    final price = (data['productPrice'] as num?)?.toDouble();
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: mine
              ? const Color(0xFF0D0140)
              : colorScheme.surfaceContainerLow,
          borderRadius: messageBubbleRadius(mine),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageUrl.isEmpty
                      ? ProductReferenceImageFallback(mine: mine)
                      : AppNetworkImage(
                          imageUrl,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          fallback: ProductReferenceImageFallback(mine: mine),
                        ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asked about',
                        style: TextStyle(
                          color: mine
                              ? Colors.white70
                              : colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: mine ? Colors.white : colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (price != null && price > 0) ...[
                        const SizedBox(height: 3),
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: mine
                                ? Colors.white70
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            MessageTimestamp(timestamp: timestamp, mine: mine, system: false),
          ],
        ),
      ),
    );
  }
}

/// A look forwarded from the Home feed: the picture, then its caption.
class LookReferenceMessage extends StatelessWidget {
  const LookReferenceMessage({
    required this.data,
    required this.mine,
    required this.timestamp,
  });

  final Map<String, dynamic> data;
  final bool mine;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    final imageUrl = (data['lookImageUrl'] ?? '').toString();
    final text = (data['text'] ?? 'Forwarded a look').toString();
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width * 0.62;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: mine
              ? const Color(0xFF0D0140)
              : colorScheme.surfaceContainerLow,
          borderRadius: messageBubbleRadius(mine),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: imageUrl.isEmpty
                    ? ProductReferenceImageFallback(mine: mine)
                    : AppNetworkImage(
                        imageUrl,
                        fit: BoxFit.cover,
                        fallback: ProductReferenceImageFallback(mine: mine),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.shortcut_rounded,
                    size: 16,
                    color: mine ? Colors.white70 : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: mine ? Colors.white : colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: MessageTimestamp(
                  timestamp: timestamp,
                  mine: mine,
                  system: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DesignRequestReferenceMessage extends StatelessWidget {
  const DesignRequestReferenceMessage({
    required this.data,
    required this.mine,
    required this.timestamp,
  });

  final Map<String, dynamic> data;
  final bool mine;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final occasion = (data['occasion'] ?? 'Custom design').toString();
    final budget = (data['budget'] ?? '').toString();
    final deadline = (data['deadline'] ?? '').toString();
    final status = (data['status'] ?? '').toString();

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mine
              ? const Color(0xFF0D0140)
              : colorScheme.surfaceContainerLow,
          borderRadius: messageBubbleRadius(mine),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: mine ? Colors.white70 : const Color(0xFF0D0140),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Design request',
                    style: TextStyle(
                      color: mine
                          ? Colors.white70
                          : colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              occasion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: mine ? Colors.white : colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (budget.isNotEmpty || deadline.isNotEmpty || status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (budget.isNotEmpty)
                      RequestReferenceMeta(
                        label: 'Budget',
                        value: budget,
                        mine: mine,
                      ),
                    if (deadline.isNotEmpty)
                      RequestReferenceMeta(
                        label: 'Deadline',
                        value: deadline,
                        mine: mine,
                      ),
                    if (status.isNotEmpty)
                      RequestReferenceMeta(
                        label: 'Status',
                        value: status,
                        mine: mine,
                      ),
                  ],
                ),
              ),
            MessageTimestamp(timestamp: timestamp, mine: mine, system: false),
          ],
        ),
      ),
    );
  }
}

class RequestReferenceMeta extends StatelessWidget {
  const RequestReferenceMeta({
    required this.label,
    required this.value,
    required this.mine,
  });

  final String label;
  final String value;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      '$label: $value',
      style: TextStyle(
        color: mine ? Colors.white70 : colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class ProductReferenceImageFallback extends StatelessWidget {
  const ProductReferenceImageFallback({required this.mine});

  final bool mine;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 58,
      height: 58,
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.checkroom_outlined,
        color: mine ? Colors.white70 : colorScheme.onSurface,
      ),
    );
  }
}
