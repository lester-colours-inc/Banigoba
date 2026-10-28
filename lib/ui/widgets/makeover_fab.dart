// The home screen's main call to action: a large, labelled "Create My Fashion
// Makeover" button, a navy-to-violet pill with an amber sparkle. It gives a
// few gentle pulses when the screen opens, like WhatsApp's "Ask Meta AI"
// button, so new users notice it. The pulse is skipped when the system asks
// for reduced motion.
//
// While the feed scrolls down the page folds it to the sparkle alone
// ([isExtended] false), so it covers less of the looks, and unfolds it again
// on the way back up.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

const String kMakeoverFabLabel = 'Create My Fashion Makeover';

/// Whether the button shows its label after the feed reports a scroll in
/// [direction], [offset] pixels from the top: folded while scrolling down
/// (even when that starts at the very top), unfolded while scrolling up or
/// once back at the top, and otherwise as it [wasExtended].
bool makeoverFabExtendedAfter(
  ScrollDirection direction, {
  required bool wasExtended,
  required double offset,
}) {
  return switch (direction) {
    ScrollDirection.reverse => false,
    ScrollDirection.forward => true,
    ScrollDirection.idle => wasExtended || offset <= 0,
  };
}

class MakeoverFab extends StatefulWidget {
  const MakeoverFab({
    super.key,
    required this.color,
    required this.onPressed,
    this.isExtended = true,
  });

  final Color color;
  final VoidCallback onPressed;

  /// Shows the label beside the sparkle.
  final bool isExtended;

  @override
  State<MakeoverFab> createState() => _MakeoverFabState();
}

class _MakeoverFabState extends State<MakeoverFab>
    with SingleTickerProviderStateMixin {
  static const _pulseCount = 3;
  static const _pulseDuration = Duration(milliseconds: 700);
  static const _foldDuration = Duration(milliseconds: 260);
  static const _peakScale = 1.06;
  static const _height = 56.0;
  static const _violet = Color(0xFF6A4CE0);
  static const _sparkle = Color(0xFFF2A93B);

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: _pulseDuration,
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: _peakScale), weight: 1),
    TweenSequenceItem(tween: Tween(begin: _peakScale, end: 1.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

  bool _hasPulsed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasPulsed) return;
    _hasPulsed = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    unawaited(_runPulses());
  }

  Future<void> _runPulses() async {
    try {
      for (var i = 0; i < _pulseCount && mounted; i++) {
        await _pulse.forward(from: 0).orCancel;
      }
    } on TickerCanceled {
      // Disposed mid-pulse; nothing to do.
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final glow = Color.lerp(widget.color, _violet, 0.6) ?? widget.color;

    return ScaleTransition(
      scale: _scale,
      child: Semantics(
        button: true,
        label: kMakeoverFabLabel,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            gradient: LinearGradient(colors: [widget.color, glow]),
            shadows: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: const ValueKey('home_makeover_button'),
              customBorder: const StadiumBorder(),
              onTap: widget.onPressed,
              child: SizedBox(
                height: _height,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: _sparkle),
                      AnimatedSize(
                        duration: reduceMotion ? Duration.zero : _foldDuration,
                        curve: Curves.easeOutCubic,
                        child: widget.isExtended
                            ? const Padding(
                                padding: EdgeInsets.only(left: 10, right: 6),
                                child: Text(
                                  kMakeoverFabLabel,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
