// A saved outfit drawn as its picture with the garments tiled around it.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:banigoba/modules/shop/widgets/safe_product_image.dart';

class OutfitPlannerVisual extends StatelessWidget {
  const OutfitPlannerVisual({required this.data, this.compact = false});

  final Map<String, dynamic> data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageUrl = _outfitImageUrl(data);
    final products = _products(data);
    if (products.isEmpty) {
      return _mainImage(colors, imageUrl);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomCount = _bottomCount(products.length);
        final tileSize = _tileSize(
          itemCount: products.length,
          bottomCount: bottomCount,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );
        final gap = compact ? 3.0 : 6.0;
        final bottomProducts = products.take(bottomCount).toList();
        final sideProducts = products.skip(bottomCount).toList();
        final bottomGap = _evenGap(
          extent: constraints.maxWidth,
          itemCount: bottomProducts.length,
          tileSize: tileSize,
          fallback: gap,
        );
        final sideAvailableHeight = constraints.maxHeight - tileSize - gap;
        final sideGap = _evenGap(
          extent: sideAvailableHeight,
          itemCount: sideProducts.length,
          tileSize: tileSize,
          fallback: gap,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            _mainImage(colors, imageUrl),
            for (var index = 0; index < sideProducts.length; index++)
              Positioned(
                right: gap,
                top: sideGap + index * (tileSize + sideGap),
                width: tileSize,
                height: tileSize,
                child: _productTile(context, sideProducts[index], compact),
              ),
            for (var index = 0; index < bottomProducts.length; index++)
              Positioned(
                left: bottomGap + index * (tileSize + bottomGap),
                bottom: gap,
                width: tileSize,
                height: tileSize,
                child: _productTile(context, bottomProducts[index], compact),
              ),
          ],
        );
      },
    );
  }

  Widget _mainImage(ColorScheme colors, String imageUrl) {
    if (imageUrl.isEmpty) {
      return Icon(Icons.checkroom_outlined, size: 56, color: colors.outline);
    }
    return SafeProductImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      iconSize: compact ? 24 : 56,
    );
  }

  Widget _productTile(
    BuildContext context,
    Map<String, dynamic> product,
    bool compact,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(compact ? 2 : 5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(compact ? 6 : 10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 4 : 8),
        child: SafeProductImage(
          imageUrl: _productImageUrl(product),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          iconSize: compact ? 18 : 30,
        ),
      ),
    );
  }

  static String _outfitImageUrl(Map<String, dynamic> data) {
    final result = (data['imageUrl'] ?? '').toString().trim();
    if (result.isNotEmpty) return result;
    return (data['avatarImageUrl'] ?? '').toString().trim();
  }

  static List<Map<String, dynamic>> _products(Map<String, dynamic> data) {
    final products = data['products'];
    if (products is! Iterable) return const [];
    return products
        .whereType<Map>()
        .map((product) => Map<String, dynamic>.from(product))
        .where((product) => _productImageUrl(product).isNotEmpty)
        .toList();
  }

  static String _productImageUrl(Map<String, dynamic> product) {
    const fields = [
      'rawImageUrl',
      'imageUrl',
      'imageURL',
      'processedImageUrl',
      'processed_url',
      'raw_url',
    ];
    for (final field in fields) {
      final value = product[field];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static int _bottomCount(int itemCount) {
    if (itemCount <= 3) return itemCount;
    if (itemCount == 4) return 3;
    return math.min(3, itemCount);
  }

  double _tileSize({
    required int itemCount,
    required int bottomCount,
    required double width,
    required double height,
  }) {
    final maxTile = compact ? 38.0 : 96.0;
    final minTile = compact ? 18.0 : 42.0;
    final gap = compact ? 3.0 : 6.0;
    final sideCount = itemCount - bottomCount;
    final bottomFit = bottomCount == 0
        ? maxTile
        : (width - gap * (bottomCount + 1)) / bottomCount;
    final sideFit = sideCount == 0
        ? maxTile
        : (height - bottomFit - gap * (sideCount + 2)) / sideCount;
    final fit = math.min(maxTile, math.min(bottomFit, sideFit));
    return fit.clamp(minTile, maxTile).toDouble();
  }

  static double _evenGap({
    required double extent,
    required int itemCount,
    required double tileSize,
    required double fallback,
  }) {
    if (itemCount <= 0) return fallback;
    final available = extent - itemCount * tileSize;
    if (available <= fallback * (itemCount + 1)) return fallback;
    return available / (itemCount + 1);
  }
}
