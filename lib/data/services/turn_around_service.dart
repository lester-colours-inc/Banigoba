// "Turn me around" (review: 3D turn-around for the fitting room). From the
// finished front try-on, the person's own photo and the garment pictures, an
// image model makes the same person in the same outfit seen from the right,
// the back and the left, so the result can be turned like a turntable.
//
// These are estimates: a shop usually photographs only the front of a
// garment, so the back and sides are the model's best guess. The UI says so.
import 'dart:typed_data';

import 'gemini_image_api.dart';

enum TurnView {
  front('Front', ''),
  right(
    'Right side',
    'from their right side, a profile view (a quarter turn to the right)',
  ),
  back('Back', 'from directly behind (a half turn)'),
  left(
    'Left side',
    'from their left side, a profile view (a quarter turn to the left)',
  );

  const TurnView(this.label, this.promptPhrase);

  final String label;
  final String promptPhrase;

  /// The three angles generated after the front, in turning order.
  static const List<TurnView> generated = [right, back, left];
}

/// At most this many garment pictures go in a request, to keep it small.
const int kMaxGarmentImages = 3;

/// The instruction for one angle. The images are attached in this order:
/// the front try-on, the person's own photo, then the garments.
String turnAroundPrompt(TurnView view, {required int garmentCount}) {
  assert(view != TurnView.front, 'The front is the try-on itself.');
  return 'The first image is a photo of a person wearing an outfit, seen from '
      'the front. The second image is an original photo of the same person.'
      '${garmentCount > 0 ? ' The remaining $garmentCount image(s) are the '
                'garments in the outfit.' : ''} '
      'Generate one photorealistic full-body image of exactly this person '
      'wearing exactly this outfit, seen ${view.promptPhrase}. Keep the same '
      'person, hair, skin tone, body shape, clothing colours, patterns, '
      'lengths and cut as in the first image, with the same plain background '
      'and lighting. Where the back or side of a garment is not visible in '
      'the references, continue its design naturally and plausibly. No text '
      'or watermarks.';
}

typedef TurnImageGenerator =
    Future<Uint8List> Function(List<GeminiImage> images, String prompt);
typedef TurnImageUploader = Future<String> Function(Uint8List bytes);
typedef TurnImageFetcher = Future<GeminiImage> Function(String url);

class TurnAroundService {
  TurnAroundService({
    required this.generate,
    required this.upload,
    TurnImageFetcher? fetch,
  }) : fetch = fetch ?? GeminiImageApi.fetchImage;

  final TurnImageGenerator generate;
  final TurnImageUploader upload;
  final TurnImageFetcher fetch;

  /// Generates the right, back and left views one at a time, calling
  /// [onView] as each is ready so the page can show them straight away. If an
  /// angle fails, the ones already made are kept and the error is rethrown.
  Future<Map<TurnView, String>> run({
    required String frontUrl,
    required String avatarUrl,
    List<String> garmentUrls = const [],
    void Function(TurnView view, String url)? onView,
  }) async {
    final garments = garmentUrls
        .where((url) => url.isNotEmpty)
        .take(kMaxGarmentImages)
        .toList();
    final images = <GeminiImage>[
      await fetch(frontUrl),
      await fetch(avatarUrl),
      for (final url in garments) await fetch(url),
    ];

    final views = <TurnView, String>{TurnView.front: frontUrl};
    for (final view in TurnView.generated) {
      final bytes = await generate(
        images,
        turnAroundPrompt(view, garmentCount: garments.length),
      );
      final url = await upload(bytes);
      views[view] = url;
      onView?.call(view, url);
    }
    return Map.unmodifiable(views);
  }
}
