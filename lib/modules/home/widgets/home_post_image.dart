// The generated try-on image, filling a feed card.
import 'package:flutter/material.dart';

import 'package:banigoba/shared/widgets/app_network_image.dart';

class HomePostImage extends StatelessWidget {
  const HomePostImage({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    if (imageUrl.isEmpty) {
      return Align(
        alignment: Alignment.center,
        child: Icon(Icons.checkroom_outlined, size: 72, color: outline),
      );
    }

    // Fill the rounded frame edge to edge, so a photo never floats as a
    // square-cornered rectangle on the backdrop. Biased upward to keep the
    // face in view when the photo is cropped.
    return AppNetworkImage(
      imageUrl,
      fit: BoxFit.cover,
      alignment: const Alignment(0, -0.3),
      fallback: Align(
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined, size: 54, color: outline),
      ),
    );
  }
}
