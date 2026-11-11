// Every network image in the app goes through here, so all of them are
// cached (memory and disk, via cached_network_image), show a loader while
// they download, and fail quietly with a placeholder instead of an error.
//
// For places that need an ImageProvider (CircleAvatar, DecorationImage) use
// CachedNetworkImageProvider directly.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.fallbackIcon = Icons.broken_image_outlined,
    this.fallback,
    this.showLoader = true,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  /// Icon on the default fallback when the image is missing or fails.
  final IconData fallbackIcon;

  /// Replaces the default fallback entirely.
  final Widget? fallback;

  /// Tiny images (avatars) can skip the progress ring.
  final bool showLoader;

  static const Duration _fadeIn = Duration(milliseconds: 220);

  /// Off in widget tests (see test/flutter_test_config.dart): there is no
  /// network or disk cache there, so the loader would spin forever and
  /// pumpAndSettle would never settle. Images then show their fallback.
  @visibleForTesting
  static bool loadFromNetwork = true;

  @override
  Widget build(BuildContext context) {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty || !loadFromNetwork) return _fallback();

    return CachedNetworkImage(
      imageUrl: cleanUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      fadeInDuration: _fadeIn,
      fadeOutDuration: Duration.zero,
      progressIndicatorBuilder: showLoader
          ? (context, _, download) => ImageLoader(
              width: width,
              height: height,
              progress: download.progress,
            )
          : null,
      placeholder: showLoader
          ? null
          : (context, _) =>
                ImageLoader(width: width, height: height, showSpinner: false),
      errorWidget: (context, _, error) {
        debugPrint('Unable to load image ${cleanUrl.split('?').first}: $error');
        return _fallback();
      },
    );
  }

  Widget _fallback() =>
      fallback ??
      _ImageFallback(width: width, height: height, icon: fallbackIcon);
}

/// The placeholder while an image downloads: a tinted box with a small
/// progress ring, determinate once the download size is known.
class ImageLoader extends StatelessWidget {
  const ImageLoader({
    super.key,
    this.width,
    this.height,
    this.progress,
    this.showSpinner = true,
  });

  final double? width;
  final double? height;
  final double? progress;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('image_loader'),
      width: width,
      height: height,
      color: colors.surfaceContainerHigh,
      alignment: Alignment.center,
      child: showSpinner
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress,
                color: colors.onSurfaceVariant,
              ),
            )
          : null,
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({this.width, this.height, required this.icon});

  final double? width;
  final double? height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: colors.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Icon(icon, color: colors.outline),
    );
  }
}
