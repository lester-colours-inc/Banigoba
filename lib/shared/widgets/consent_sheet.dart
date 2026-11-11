// A plain-words consent: a title, what will happen in a few points, and a
// clear yes or no. Used before gallery suggestions and before "Near me" uses
// the phone's location.
import 'package:flutter/material.dart';

/// True when the person agrees; closing the sheet counts as no.
Future<bool> showConsentSheet(
  BuildContext context, {
  required String title,
  required List<String> points,
}) async {
  final agreed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => ConsentSheet(title: title, points: points),
  );
  return agreed ?? false;
}

class ConsentSheet extends StatelessWidget {
  const ConsentSheet({super.key, required this.title, required this.points});

  final String title;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final point in points)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(point, style: const TextStyle(height: 1.35)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('consent_no'),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Not now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('consent_yes'),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Turn on'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
