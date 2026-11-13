// A verified boutique in the marketplace list.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class BoutiqueCard extends StatelessWidget {
  const BoutiqueCard({
    super.key,
    required this.shopName,
    required this.description,
    required this.imageUrl,
    required this.productCount,
    required this.onTap,
    this.previewImageUrls = const [],
    this.fromPrice,
    this.newCount = 0,
  });

  /// Up to four product pictures shown under the header.
  final List<String> previewImageUrls;

  /// Cheapest matching product, shown as "From $X".
  final double? fromPrice;

  /// Pieces listed recently, shown as a "N new" pill.
  final int newCount;

  static const Color _primary = Color(0xFF0D0140);

  final String shopName;
  final String description;
  final String imageUrl;
  final int productCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: _primary,
                backgroundImage: imageUrl.isEmpty
                    ? null
                    : CachedNetworkImageProvider(imageUrl),
                child: imageUrl.isEmpty
                    ? Text(
                        shopName.isEmpty ? 'B' : shopName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '$productCount product${productCount == 1 ? '' : 's'}'
                          '${fromPrice != null && fromPrice! > 0 ? ' · from \$${fromPrice!.toStringAsFixed(0)}' : ''}',
                        ),
                        if (newCount > 0) _NewPill(count: newCount),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
              if (previewImageUrls.isNotEmpty) ...[
                const SizedBox(height: 14),
                _PreviewStrip(urls: previewImageUrls.take(4).toList()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NewPill extends StatelessWidget {
  const _NewPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFE8E4FF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Text(
        '$count new',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0D0140),
        ),
      ),
    ),
  );
}

class _PreviewStrip extends StatelessWidget {
  const _PreviewStrip({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).colorScheme.surfaceContainerLow;
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: fill,
                  child: i < urls.length
                      ? CachedNetworkImage(
                          imageUrl: urls[i],
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) =>
                              const Icon(Icons.checkroom_outlined),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
