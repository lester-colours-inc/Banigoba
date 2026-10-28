// The plain-words consent for gallery suggestions (E-5). Shown before the
// feature is turned on, from the makeover screen or from Settings.
import 'package:flutter/material.dart';

import '../../data/models/gallery_consent.dart';
import 'consent_sheet.dart';

/// True when the person agrees.
Future<bool> showGalleryConsentSheet(BuildContext context) => showConsentSheet(
  context,
  title: 'Suggestions from your photos',
  points: kGalleryConsentText,
);
