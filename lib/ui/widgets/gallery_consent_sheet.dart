// The plain-words consent for gallery suggestions (E-5). Shown before the
// feature is turned on, from the makeover screen or from Settings.
import 'package:flutter/material.dart';

import '../../data/models/gallery_consent.dart';

/// True when the person agrees.
Future<bool> showGalleryConsentSheet(BuildContext context) async {
  final agreed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const GalleryConsentSheet(),
  );
  return agreed ?? false;
}

class GalleryConsentSheet extends StatelessWidget {
  const GalleryConsentSheet({super.key});

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
            const Text(
              'Suggestions from your photos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final point in kGalleryConsentText)
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
