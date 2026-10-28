// "Try a makeover on a recent photo" on the makeover screen (E-5).
//
//  - Before consent: a small offer, off by default. "Turn on" shows the
//    consent wording first; "Not now" hides the offer for good.
//  - After consent: the phone's recent photos, shown only on the phone. A
//    photo is read in full and uploaded only when the person taps it.
//  - If the phone's own photo permission is refused, it says so and points
//    to the phone's settings instead of nagging.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/gallery_consent_service.dart';
import '../../data/services/gallery_scanner.dart';
import 'gallery_consent_sheet.dart';

const String kGalleryOfferDismissedKey = 'gallery_offer_dismissed';

class GallerySuggestionsStrip extends StatefulWidget {
  const GallerySuggestionsStrip({
    super.key,
    required this.onPick,
    this.consent,
    this.scanner = const PhotoManagerScanner(),
    this.onOpenSettings,
    this.askConsent = showGalleryConsentSheet,
  });

  /// Called with a photo the person tapped; the app uploads it from here.
  final ValueChanged<GalleryPhoto> onPick;
  final GalleryConsentStore? consent;
  final GalleryScanner scanner;
  final VoidCallback? onOpenSettings;
  final Future<bool> Function(BuildContext context) askConsent;

  @override
  State<GallerySuggestionsStrip> createState() =>
      _GallerySuggestionsStripState();
}

enum _Stage { loading, offer, photos, denied, hidden }

class _GallerySuggestionsStripState extends State<GallerySuggestionsStrip> {
  late final GalleryConsentStore _consent =
      widget.consent ?? GalleryConsentService();
  _Stage _stage = _Stage.loading;
  List<GalleryPhoto> _photos = const [];

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final consent = await _consent.load();
      if (consent.isActive) return await _showPhotos();
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(
        () => _stage = prefs.getBool(kGalleryOfferDismissedKey) == true
            ? _Stage.hidden
            : _Stage.offer,
      );
    } on Object {
      // Anything unexpected (signed out, offline): show nothing rather than
      // a half-working offer.
      if (mounted) setState(() => _stage = _Stage.hidden);
    }
  }

  Future<void> _showPhotos() async {
    final access = await widget.scanner.requestAccess();
    if (!mounted) return;
    switch (access) {
      case GalleryAccess.unsupported:
        setState(() => _stage = _Stage.hidden);
      case GalleryAccess.denied:
        setState(() => _stage = _Stage.denied);
      case GalleryAccess.granted:
        final photos = await widget.scanner.recent();
        if (!mounted) return;
        setState(() {
          _photos = photos;
          _stage = photos.isEmpty ? _Stage.hidden : _Stage.photos;
        });
    }
  }

  Future<void> _turnOn() async {
    if (!await widget.askConsent(context)) return;
    await _consent.grant();
    if (!mounted) return;
    setState(() => _stage = _Stage.loading);
    await _showPhotos();
  }

  Future<void> _notNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kGalleryOfferDismissedKey, true);
    if (mounted) setState(() => _stage = _Stage.hidden);
  }

  Future<void> _turnOff() async {
    await _consent.withdraw();
    if (mounted) setState(() => _stage = _Stage.hidden);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return switch (_stage) {
      _Stage.loading || _Stage.hidden => const SizedBox.shrink(),
      _Stage.offer => Card(
        key: const ValueKey('gallery_offer'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Start from a photo on your phone?',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Show your recent photos here to start a makeover in a tap. '
                'Your photos stay on your phone.',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton.tonal(
                    key: const ValueKey('gallery_turn_on'),
                    onPressed: _turnOn,
                    child: const Text('Turn on'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    key: const ValueKey('gallery_not_now'),
                    onPressed: _notNow,
                    child: const Text('Not now'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      _Stage.denied => Card(
        key: const ValueKey('gallery_denied'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Your phone is not letting Banigoba open your photos.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
              TextButton(
                key: const ValueKey('gallery_open_settings'),
                onPressed: widget.onOpenSettings,
                child: const Text('Open settings'),
              ),
            ],
          ),
        ),
      ),
      _Stage.photos => Column(
        key: const ValueKey('gallery_photos'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Try a makeover on a recent photo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                key: const ValueKey('gallery_turn_off'),
                onPressed: _turnOff,
                child: const Text('Turn off'),
              ),
            ],
          ),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => _Thumb(
                photo: _photos[index],
                onTap: () => widget.onPick(_photos[index]),
              ),
            ),
          ),
        ],
      ),
    };
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo, required this.onTap});

  final GalleryPhoto photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('gallery_photo_${photo.id}'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 84,
          height: 84,
          child: FutureBuilder<Uint8List?>(
            future: photo.thumbnail(),
            builder: (context, snapshot) {
              final bytes = snapshot.data;
              return bytes == null
                  ? ColoredBox(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    )
                  : Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    );
            },
          ),
        ),
      ),
    );
  }
}
