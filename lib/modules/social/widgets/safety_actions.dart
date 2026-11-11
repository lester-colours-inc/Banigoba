// Report and block, offered on other people's looks and profiles (App Store
// guideline 1.2). Each asks first, then confirms with a short message.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/settings/services/safety_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

/// Asks why, then reports. Returns true once the report is sent.
Future<bool> showReportSheet(
  BuildContext context, {
  required String subject,
  required Future<void> Function(ReportReason reason) onReport,
}) async {
  final reason = await showModalBottomSheet<ReportReason>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Why are you reporting this $subject?',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
          ),
          for (final reason in ReportReason.values)
            ListTile(
              title: Text(reason.label),
              onTap: () => Navigator.pop(sheetContext, reason),
            ),
        ],
      ),
    ),
  );
  if (reason == null || !context.mounted) return false;
  return _run(
    context,
    () => onReport(reason),
    'Thanks for telling us. Our team reviews reports within 24 hours.',
  );
}

/// Asks to confirm, then blocks [userId]. Returns true once blocked.
Future<bool> confirmBlock(
  BuildContext context, {
  required String userId,
  required String name,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Block $name?'),
      content: const Text(
        'You will no longer see each other\'s looks or comments, and any '
        'follow between you ends. They are not told. You can unblock them in '
        'Settings.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Block'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  return _run(
    context,
    () => SafetyService.instance.block(userId),
    '$name is blocked.',
  );
}

Future<bool> _run(
  BuildContext context,
  Future<void> Function() action,
  String done,
) async {
  try {
    await action();
    AppToast.say(done);
    return true;
  } on Exception catch (error) {
    debugPrint('Safety action failed: $error');
    AppToast.say('Something went wrong. Please try again.');
    return false;
  }
}
