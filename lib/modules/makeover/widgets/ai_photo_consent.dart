// Asks once before any photo leaves the phone for an AI service (App Store
// guideline 5.1.2(i)): which photos, which services, and what for. The answer
// is kept on the account and can be changed in Settings.
import 'package:flutter/material.dart';

import 'package:banigoba/core/legal_links.dart';
import 'package:banigoba/modules/settings/services/safety_service.dart';

/// What is sent and to whom, shown here and in Settings.
const String kAiPhotoDisclosure =
    'To tag your clothes, remove backgrounds and create makeovers and '
    'try-ons, Banigoba sends the photos you choose (and, for try-ons, your '
    'body photo) to Google Gemini and to our background-removal service. '
    'They are used only to produce the result for you and are not used by '
    'Banigoba to train AI models.';

/// True when the person has allowed it, asking first if they have not.
Future<bool> ensureAiPhotoConsent(BuildContext context) async {
  final safety = SafetyService.instance;
  try {
    if (await safety.hasAiPhotoConsent()) return true;
  } on Exception catch (error) {
    debugPrint('Unable to read AI consent: $error');
  }
  if (!context.mounted) return false;

  final allowed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.auto_awesome_outlined),
      title: const Text('Use AI with your photos?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(kAiPhotoDisclosure),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => openLegalPage(kPrivacyPolicyUrl),
            child: const Text('Read the Privacy Policy'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Allow'),
        ),
      ],
    ),
  );
  if (allowed != true) return false;
  try {
    await safety.setAiPhotoConsent(true);
  } on Exception catch (error) {
    // Allowed for this use even if saving the answer failed; asked again later.
    debugPrint('Unable to save AI consent: $error');
  }
  return true;
}
