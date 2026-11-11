// The look being tried on, shown large at the top of the Makeover page when
// it was opened from "Try on" on a post or a saved hairstyle.
import 'package:flutter/material.dart';

import 'package:banigoba/shared/widgets/app_network_image.dart';

/// The picture of the look to copy onto the user, with a caption over its
/// lower edge.
class TryOnLookHero extends StatelessWidget {
  const TryOnLookHero({super.key, required this.imageUrl});

  final String imageUrl;

  static const double _maxHeight = 380;
  static const double _radius = 20;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      image: true,
      label: "The look you're trying on",
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _maxHeight),
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: DecoratedBox(
            key: const ValueKey('try_on_look_hero'),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(_radius),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    fallback: Icon(
                      Icons.broken_image_outlined,
                      color: colors.outline,
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _Caption(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xB3000000)],
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(16, 32, 16, 14),
        child: Row(
          children: [
            Icon(Icons.checkroom, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "The look you're trying on",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
