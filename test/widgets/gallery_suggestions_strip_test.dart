import 'dart:typed_data';

import 'package:banigoba/data/models/gallery_consent.dart';
import 'package:banigoba/data/services/gallery_consent_service.dart';
import 'package:banigoba/data/services/gallery_scanner.dart';
import 'package:banigoba/ui/widgets/gallery_consent_sheet.dart';
import 'package:banigoba/ui/widgets/gallery_suggestions_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Consent implements GalleryConsentStore {
  _Consent({bool granted = false})
    : consent = granted
          ? GalleryConsent.granted()
          : const GalleryConsent.none();

  GalleryConsent consent;
  int grants = 0;
  int withdrawals = 0;

  @override
  Future<GalleryConsent> load() async => consent;

  @override
  Future<void> grant() async {
    grants += 1;
    consent = GalleryConsent.granted();
  }

  @override
  Future<void> withdraw() async {
    withdrawals += 1;
    consent = consent.withdrawn();
  }
}

class _Scanner implements GalleryScanner {
  _Scanner({this.access = GalleryAccess.granted, this.count = 3});

  final GalleryAccess access;
  final int count;
  int accessRequests = 0;
  int listings = 0;

  @override
  Future<GalleryAccess> requestAccess() async {
    accessRequests += 1;
    return access;
  }

  @override
  Future<List<GalleryPhoto>> recent({int limit = 12}) async {
    listings += 1;
    return [
      for (var i = 0; i < count; i += 1)
        GalleryPhoto(
          id: 'p$i',
          thumbnail: () async => null,
          bytes: () async => Uint8List.fromList([i]),
        ),
    ];
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required _Consent consent,
  required GalleryScanner scanner,
  ValueChanged<GalleryPhoto>? onPick,
  Future<bool> Function(BuildContext)? askConsent,
  VoidCallback? onOpenSettings,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GallerySuggestionsStrip(
          consent: consent,
          scanner: scanner,
          onPick: onPick ?? (_) {},
          askConsent: askConsent ?? (_) async => true,
          onOpenSettings: onOpenSettings,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('before consent', () {
    testWidgets('offers the feature and reads no photos', (tester) async {
      final scanner = _Scanner();
      await _pump(tester, consent: _Consent(), scanner: scanner);

      expect(find.byKey(const ValueKey('gallery_offer')), findsOneWidget);
      expect(scanner.accessRequests, 0);
      expect(scanner.listings, 0);
    });

    testWidgets('turning it on asks first, then shows the photos', (
      tester,
    ) async {
      final consent = _Consent();
      final scanner = _Scanner();
      var asked = 0;
      await _pump(
        tester,
        consent: consent,
        scanner: scanner,
        askConsent: (_) async {
          asked += 1;
          return true;
        },
      );

      await tester.tap(find.byKey(const ValueKey('gallery_turn_on')));
      await tester.pumpAndSettle();

      expect(asked, 1);
      expect(consent.grants, 1);
      expect(find.byKey(const ValueKey('gallery_photos')), findsOneWidget);
      expect(scanner.listings, 1);
    });

    testWidgets('saying no to the wording grants nothing and reads nothing', (
      tester,
    ) async {
      final consent = _Consent();
      final scanner = _Scanner();
      await _pump(
        tester,
        consent: consent,
        scanner: scanner,
        askConsent: (_) async => false,
      );

      await tester.tap(find.byKey(const ValueKey('gallery_turn_on')));
      await tester.pumpAndSettle();

      expect(consent.grants, 0);
      expect(scanner.accessRequests, 0);
      expect(find.byKey(const ValueKey('gallery_offer')), findsOneWidget);
    });

    testWidgets('"Not now" hides the offer for good', (tester) async {
      await _pump(tester, consent: _Consent(), scanner: _Scanner());

      await tester.tap(find.byKey(const ValueKey('gallery_not_now')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('gallery_offer')), findsNothing);

      await _pump(tester, consent: _Consent(), scanner: _Scanner());
      expect(find.byKey(const ValueKey('gallery_offer')), findsNothing);
    });
  });

  group('after consent', () {
    testWidgets('shows recent photos and hands over the one tapped', (
      tester,
    ) async {
      GalleryPhoto? picked;
      await _pump(
        tester,
        consent: _Consent(granted: true),
        scanner: _Scanner(),
        onPick: (photo) => picked = photo,
      );

      expect(find.byKey(const ValueKey('gallery_photo_p0')), findsOneWidget);
      expect(find.byKey(const ValueKey('gallery_photo_p2')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('gallery_photo_p1')));

      expect(picked?.id, 'p1');
    });

    testWidgets('does not read a photo until it is tapped', (tester) async {
      var fullReads = 0;
      final scanner = _CountingScanner(onFullRead: () => fullReads += 1);
      await _pump(tester, consent: _Consent(granted: true), scanner: scanner);

      expect(fullReads, 0);
    });

    testWidgets('turning it off withdraws consent and hides the photos', (
      tester,
    ) async {
      final consent = _Consent(granted: true);
      await _pump(tester, consent: consent, scanner: _Scanner());

      await tester.tap(find.byKey(const ValueKey('gallery_turn_off')));
      await tester.pumpAndSettle();

      expect(consent.withdrawals, 1);
      expect(consent.consent.isActive, isFalse);
      expect(find.byKey(const ValueKey('gallery_photos')), findsNothing);
    });

    testWidgets(
      'says so when the phone refuses access, and points to settings',
      (tester) async {
        var opened = false;
        await _pump(
          tester,
          consent: _Consent(granted: true),
          scanner: _Scanner(access: GalleryAccess.denied),
          onOpenSettings: () => opened = true,
        );

        expect(find.byKey(const ValueKey('gallery_denied')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('gallery_open_settings')));
        expect(opened, isTrue);
      },
    );

    testWidgets('is hidden where photos cannot be read, or there are none', (
      tester,
    ) async {
      await _pump(
        tester,
        consent: _Consent(granted: true),
        scanner: _Scanner(access: GalleryAccess.unsupported),
      );
      expect(find.byKey(const ValueKey('gallery_photos')), findsNothing);
      expect(find.byKey(const ValueKey('gallery_denied')), findsNothing);

      await _pump(
        tester,
        consent: _Consent(granted: true),
        scanner: _Scanner(count: 0),
      );
      expect(find.byKey(const ValueKey('gallery_photos')), findsNothing);
    });
  });

  group('GalleryConsentSheet', () {
    testWidgets('lists every point and returns the choice', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    result = await showGalleryConsentSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      for (final point in kGalleryConsentText) {
        expect(find.text(point), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('consent_yes')));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('closing without choosing counts as no', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    result = await showGalleryConsentSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('consent_no')));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}

class _CountingScanner implements GalleryScanner {
  _CountingScanner({required this.onFullRead});

  final VoidCallback onFullRead;

  @override
  Future<GalleryAccess> requestAccess() async => GalleryAccess.granted;

  @override
  Future<List<GalleryPhoto>> recent({int limit = 12}) async => [
    GalleryPhoto(
      id: 'a',
      thumbnail: () async => null,
      bytes: () async {
        onFullRead();
        return Uint8List(1);
      },
    ),
  ];
}
