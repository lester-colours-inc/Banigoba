// The one way to show a toast in Banigoba. Built on `toastification`; never use
// SnackBar. Needs no BuildContext, so it is safe to call after an `await`.
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import 'package:banigoba/shared/widgets/app_toast_card.dart';

export 'package:banigoba/shared/widgets/app_toast_card.dart' show AppToastKind;

class AppToast {
  const AppToast._();

  /// Tests turn this off so no auto-close timer outlives the widget tree.
  @visibleForTesting
  static bool autoCloseEnabled = true;

  /// Forgets the toast in flight. Tests call this between cases.
  @visibleForTesting
  static void reset() => _current = null;

  static const Duration defaultDuration = Duration(seconds: 4);
  static const Duration actionDuration = Duration(seconds: 6);

  static ToastificationItem? _current;

  static final RegExp _failureWords = RegExp(
    r"unable|couldn'?t|could not|can'?t|cannot|failed|failure|error|wrong|invalid|denied",
    caseSensitive: false,
  );

  static void success(String message, {String? title, Duration? duration}) =>
      show(
        message,
        kind: AppToastKind.success,
        title: title,
        duration: duration,
      );

  static void error(String message, {String? title, Duration? duration}) =>
      show(message, kind: AppToastKind.error, title: title, duration: duration);

  static void warning(String message, {String? title, Duration? duration}) =>
      show(
        message,
        kind: AppToastKind.warning,
        title: title,
        duration: duration,
      );

  static void info(String message, {String? title, Duration? duration}) =>
      show(message, kind: AppToastKind.info, title: title, duration: duration);

  /// Shows [message], picking error vs. info from its wording unless [kind] is
  /// given. Use for legacy one-line messages.
  static void say(String message, {Duration? duration}) => show(
    message,
    kind: _failureWords.hasMatch(message)
        ? AppToastKind.error
        : AppToastKind.info,
    duration: duration,
  );

  static void show(
    String message, {
    AppToastKind kind = AppToastKind.info,
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    final hasAction = actionLabel != null && onAction != null;
    final previous = _current;
    if (previous != null) {
      toastification.dismiss(previous, showRemoveAnimation: false);
    }
    _current = toastification.showCustom(
      alignment: Alignment.bottomCenter,
      autoCloseDuration: !autoCloseEnabled
          ? null
          : duration ?? (hasAction ? actionDuration : defaultDuration),
      animationDuration: const Duration(milliseconds: 250),
      builder: (context, holder) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: AppToastCard(
          message: message,
          title: title,
          kind: kind,
          actionLabel: actionLabel,
          onAction: onAction,
          onDismiss: () => toastification.dismiss(holder),
        ),
      ),
    );
  }

  static void dismissAll() {
    _current = null;
    toastification.dismissAll();
  }
}
