// How a designer looks in a list, on their detail page, and as an avatar.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:banigoba/modules/designers/models/designer_summary.dart';

class DesignerCard extends StatelessWidget {
  const DesignerCard({super.key, required this.designer, required this.onTap});

  final DesignerSummary designer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              DesignerAvatar(designer: designer, radius: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      designer.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (designer.location.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(designer.location),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      designer.specialties.isEmpty
                          ? 'Custom fashion design'
                          : designer.specialties.take(3).join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class DesignerHero extends StatelessWidget {
  const DesignerHero({super.key, required this.designer});

  final DesignerSummary designer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            DesignerAvatar(designer: designer, radius: 38),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    designer.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (designer.location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(designer.location),
                  ],
                  if (designer.priceRange.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('From ${designer.priceRange}'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DesignerAvatar extends StatelessWidget {
  const DesignerAvatar({
    super.key,
    required this.designer,
    required this.radius,
  });

  final DesignerSummary designer;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = designer.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: DesignerColors.primary,
      backgroundImage: imageUrl.isEmpty
          ? null
          : CachedNetworkImageProvider(imageUrl),
      child: imageUrl.isEmpty
          ? Text(
              designer.name.isEmpty ? 'D' : designer.name[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.7,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}
