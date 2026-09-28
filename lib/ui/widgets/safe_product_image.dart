import 'package:flutter/material.dart';
import 'app_network_image.dart';

class SafeProductImage extends StatelessWidget {
  const SafeProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.iconSize = 48,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl.replaceAll(RegExp(r'\s+'), '');
    if (cleanUrl.isEmpty) {
      return _ProductImageFallback(
        width: width,
        height: height,
        iconSize: iconSize,
      );
    }

    return AppNetworkImage(
      cleanUrl,
      width: width,
      height: height,
      fit: fit,
      fallback: _ProductImageFallback(
        width: width,
        height: height,
        iconSize: iconSize,
      ),
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback({this.width, this.height, this.iconSize = 48});

  final double? width;
  final double? height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.checkroom, size: iconSize, color: Colors.grey),
    );
  }
}
