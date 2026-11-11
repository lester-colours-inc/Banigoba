// Side-by-side before/after comparison with a draggable reveal handle.

import 'package:flutter/material.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

/// Shows [afterImageUrl] over [beforeImageUrl], split by a handle the user can
/// drag left or right to reveal more of either side.
///
/// Both images are drawn with [BoxFit.cover] so the two halves line up; the
/// try-on result keeps the avatar's framing, so the split reads as one photo.
class BeforeAfterView extends StatefulWidget {
  const BeforeAfterView({
    super.key,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.beforeLabel = 'BEFORE',
    this.afterLabel = 'AFTER',
    this.aspectRatio = 3 / 4,
    this.borderRadius = 24,
    this.fit = BoxFit.cover,
    this.background,
    this.onTapAfter,
  });

  final String beforeImageUrl;
  final String afterImageUrl;
  final String beforeLabel;
  final String afterLabel;
  final double aspectRatio;
  final double borderRadius;

  /// How both images fill the frame. [BoxFit.contain] shows each photo whole
  /// on [background].
  final BoxFit fit;
  final Color? background;

  /// Called when the revealed look is tapped, for a full-screen view.
  final VoidCallback? onTapAfter;

  @override
  State<BeforeAfterView> createState() => _BeforeAfterViewState();
}

class _BeforeAfterViewState extends State<BeforeAfterView> {
  /// Keeps the handle away from the very edges so it stays grabbable.
  static const double _minSplit = 0.08;
  static const double _maxSplit = 0.92;

  /// How much of the width the "before" side takes, 0 to 1.
  double _split = 0.5;

  void _dragTo(double dx, double width) {
    if (width <= 0) return;
    setState(() => _split = (dx / width).clamp(_minSplit, _maxSplit));
  }

  @override
  Widget build(BuildContext context) {
    final background =
        widget.background ?? Theme.of(context).colorScheme.surfaceContainerLow;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final splitX = width * _split;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTapAfter,
              onHorizontalDragUpdate: (details) =>
                  _dragTo(details.localPosition.dx, width),
              onHorizontalDragStart: (details) =>
                  _dragTo(details.localPosition.dx, width),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: background),
                  _ComparisonImage(
                    imageUrl: widget.beforeImageUrl,
                    fit: widget.fit,
                  ),
                  ClipRect(
                    clipper: _RevealClipper(splitX),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Hides the before photo wherever the after one is
                        // narrower, so the two sides never mix.
                        ColoredBox(color: background),
                        _ComparisonImage(
                          imageUrl: widget.afterImageUrl,
                          fit: widget.fit,
                        ),
                      ],
                    ),
                  ),
                  _ComparisonLabel(
                    text: widget.beforeLabel,
                    alignment: Alignment.topLeft,
                    isVisible: _split > 0.22,
                    background: Colors.white.withValues(alpha: 0.92),
                    foreground: const Color(0xFF1A1A1A),
                  ),
                  _ComparisonLabel(
                    text: widget.afterLabel,
                    alignment: Alignment.topRight,
                    isVisible: _split < 0.78,
                    background: const Color(0xFF0D0140).withValues(alpha: 0.92),
                    foreground: const Color(0xFFFFC53D),
                  ),
                  Positioned(
                    left: splitX - 1,
                    top: 0,
                    bottom: 0,
                    width: 2,
                    child: const ColoredBox(color: Colors.white),
                  ),
                  Positioned(
                    left: splitX - 26,
                    top: 0,
                    bottom: 0,
                    width: 52,
                    child: const Center(child: _RevealHandle()),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ComparisonImage extends StatelessWidget {
  const _ComparisonImage({required this.imageUrl, required this.fit});

  final String imageUrl;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return AppNetworkImage(
      imageUrl,
      fit: fit,
      fallback: const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Unable to display this look.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _ComparisonLabel extends StatelessWidget {
  const _ComparisonLabel({
    required this.text,
    required this.alignment,
    required this.isVisible,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Alignment alignment;
  final bool isVisible;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AnimatedOpacity(
          opacity: isVisible ? 1 : 0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RevealHandle extends StatelessWidget {
  const _RevealHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0140),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(Icons.swap_horiz, size: 20, color: Colors.white),
    );
  }
}

/// Clips away everything left of [splitX] so the "after" image only shows on
/// the right of the handle.
class _RevealClipper extends CustomClipper<Rect> {
  const _RevealClipper(this.splitX);

  final double splitX;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(splitX, 0, size.width, size.height);

  @override
  bool shouldReclip(_RevealClipper oldClipper) => oldClipper.splitX != splitX;
}
