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
  });

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
          child: Row(
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
                    Text('$productCount products'),
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
