// The home screen's main call to action: a large, labelled "Create My Fashion
// Makeover" button. It gives a few gentle pulses when the screen opens, like
// WhatsApp's "Ask Meta AI" button, so new users notice it. The pulse is
// skipped when the system asks for reduced motion.
import 'dart:async';

import 'package:flutter/material.dart';

const String kMakeoverFabLabel = 'Create My Fashion Makeover';

class MakeoverFab extends StatefulWidget {
  const MakeoverFab({super.key, required this.color, required this.onPressed});

  final Color color;
  final VoidCallback onPressed;

  @override
  State<MakeoverFab> createState() => _MakeoverFabState();
}

class _MakeoverFabState extends State<MakeoverFab>
    with SingleTickerProviderStateMixin {
  static const _pulseCount = 3;
  static const _pulseDuration = Duration(milliseconds: 700);
  static const _peakScale = 1.06;

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
    return ScaleTransition(
      scale: _scale,
      child: FloatingActionButton.extended(
        key: const ValueKey('home_makeover_button'),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome),
        label: const Text(
          kMakeoverFabLabel,
          maxLines: 1,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        onPressed: widget.onPressed,
      ),
    );
  }
}
