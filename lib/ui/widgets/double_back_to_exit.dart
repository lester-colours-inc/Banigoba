// Wraps the app's root screen so a single back press doesn't close the app:
// the first press shows a hint, a second press within [window] exits.
// Pages and sheets pushed on top handle back themselves. Things inside this
// route (an open drawer) are handled through [onBackFirst], because a
// PopScope that can't pop would otherwise swallow their back press.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String kPressBackAgainToExit = 'Press back again to exit';

class DoubleBackToExit extends StatefulWidget {
  const DoubleBackToExit({
    super.key,
    required this.child,
    this.window = const Duration(seconds: 2),
    this.onExit,
    this.onBackFirst,
  });

  final Widget child;

  /// How long after the first press a second press still exits.
  final Duration window;

  /// Closes the app. Defaults to [SystemNavigator.pop]; tests replace it.
  final VoidCallback? onExit;

  /// Gets the back press first; return true when it was used (for example to
  /// close an open drawer), so it neither shows the hint nor exits.
  final bool Function()? onBackFirst;

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit> {
  Timer? _armed;

  @override
  void dispose() {
    _armed?.cancel();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBackFirst?.call() ?? false) return;
    if (_armed?.isActive ?? false) {
      _armed?.cancel();
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
      final exit = widget.onExit;
      if (exit != null) {
        exit();
      } else {
        unawaited(SystemNavigator.pop());
      }
      return;
    }
    _armed = Timer(widget.window, () {});
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(kPressBackAgainToExit),
          duration: widget.window,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: widget.child,
    );
  }
}
