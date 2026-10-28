// Consent for gallery suggestions (review item E-5). Off until the person
// turns it on, after reading what it does. Banigoba shows their recent
// photos so they can start a makeover from one; nothing is uploaded unless
// they pick a photo, and no photo is analysed or stored by the app.
//
// The wording has a version: if it changes, earlier consent no longer counts
// and the person is asked again.
import 'package:flutter/foundation.dart';

const int kGalleryConsentVersion = 1;

/// What the person is told before turning it on, one point each.
const List<String> kGalleryConsentText = [
  'Banigoba can show your recent photos on the makeover screen, so you can '
      'start a makeover from one in a tap.',
  'Your photos stay on your phone. A photo is uploaded only when you pick '
      'it for a makeover. We never upload all your photos.',
  'We do not scan, sort or keep your photos. Your phone will also ask for '
      'permission to open your photos.',
  'You can turn this off any time in Settings.',
];

@immutable
class GalleryConsent {
  const GalleryConsent({
    required this.granted,
    required this.version,
    this.changedAt,
  });

  const GalleryConsent.none() : this(granted: false, version: 0);

  factory GalleryConsent.granted({DateTime? at}) => GalleryConsent(
    granted: true,
    version: kGalleryConsentVersion,
    changedAt: at ?? DateTime.now(),
  );

  factory GalleryConsent.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const GalleryConsent.none();
    return GalleryConsent(
      granted: data['granted'] == true,
      version: (data['version'] as num?)?.toInt() ?? 0,
    );
  }

  final bool granted;
  final int version;
  final DateTime? changedAt;

  /// True only for consent given to the current wording.
  bool get isActive => granted && version == kGalleryConsentVersion;

  GalleryConsent withdrawn({DateTime? at}) => GalleryConsent(
    granted: false,
    version: version,
    changedAt: at ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {'granted': granted, 'version': version};
}
