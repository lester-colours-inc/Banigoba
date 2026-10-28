import 'package:banigoba/data/models/gallery_consent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GalleryConsent', () {
    test('nothing saved means no consent', () {
      expect(GalleryConsent.fromMap(null).isActive, isFalse);
      expect(GalleryConsent.fromMap(const {}).isActive, isFalse);
    });

    test('is active only when granted for the current wording', () {
      expect(
        GalleryConsent.fromMap({
          'granted': true,
          'version': kGalleryConsentVersion,
        }).isActive,
        isTrue,
      );
      expect(
        GalleryConsent.fromMap({
          'granted': true,
          'version': kGalleryConsentVersion - 1,
        }).isActive,
        isFalse,
        reason: 'the wording changed, so ask again',
      );
      expect(
        GalleryConsent.fromMap({
          'granted': false,
          'version': kGalleryConsentVersion,
        }).isActive,
        isFalse,
      );
    });

    test('granting records the wording the person agreed to', () {
      final granted = GalleryConsent.granted();

      expect(granted.isActive, isTrue);
      expect(granted.toMap()['granted'], isTrue);
      expect(granted.toMap()['version'], kGalleryConsentVersion);
    });

    test('withdrawing switches it off and says so', () {
      final off = GalleryConsent.granted().withdrawn();

      expect(off.isActive, isFalse);
      expect(off.toMap()['granted'], isFalse);
    });
  });

  group('the consent wording', () {
    test('says what is read, where it stays, and how to stop', () {
      final text = kGalleryConsentText.join(' ').toLowerCase();

      expect(text, contains('recent photos'));
      expect(text, contains('stay on your phone'));
      expect(text, contains('turn this off'));
      expect(text, contains('never upload all your photos'));
    });
  });
}
