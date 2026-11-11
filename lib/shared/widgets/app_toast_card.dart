// The visual body of every in-app toast: icon, message and an optional action.
import 'package:flutter/material.dart';

enum AppToastKind { success, error, warning, info }

class AppToastCard extends StatelessWidget {
  const AppToastCard({
    super.key,
    required this.message,
    required this.kind,
    required this.onDismiss,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? title;
  final AppToastKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  static IconData iconFor(AppToastKind kind) => switch (kind) {
    AppToastKind.success => Icons.check_circle_rounded,
    AppToastKind.error => Icons.error_rounded,
    AppToastKind.warning => Icons.warning_amber_rounded,
    AppToastKind.info => Icons.info_rounded,
  };

  Color _accent(ColorScheme scheme) => switch (kind) {
    AppToastKind.success => const Color(0xFF2E9E6B),
    AppToastKind.error => scheme.error,
    AppToastKind.warning => const Color(0xFFE0A100),
    AppToastKind.info => scheme.primary,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accent(theme.colorScheme);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: 6,
      shadowColor: Colors.black45,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                child: Row(
                  children: [
                    Icon(iconFor(kind), color: accent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (title != null)
                            Text(
                              title!,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          Text(message, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    if (actionLabel != null && onAction != null)
                      TextButton(
                        onPressed: () {
                          onDismiss();
                          onAction!();
                        },
                        child: Text(actionLabel!),
                      ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: onDismiss,
                      tooltip: 'Dismiss',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
