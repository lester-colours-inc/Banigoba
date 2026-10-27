// Picks a garment's colours from its photo (review item W-3), so nobody has
// to choose them by hand. Pure maths on the pixels: each pixel is named with
// the wardrobe's own colour words, the middle of the photo counts for more
// than the edges (the garment is usually in the middle, the wall behind it is
// not), and the colours that take up enough of the picture win.
//
// It is a suggestion: the form pre-selects the colours and the user can
// change them.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// The colour words the wardrobe form offers.
const List<String> kGarmentColours = [
  'black',
  'white',
  'grey',
  'blue',
  'red',
  'green',
  'yellow',
  'orange',
  'pink',
  'purple',
  'brown',
  'beige',
];

/// A colour needs at least this share of the garment to be suggested.
const double kMinColourShare = 0.25;

/// The colour word for one pixel (0 to 255 per channel).
String colourNameOf(int r, int g, int b) {
  final red = r / 255;
  final green = g / 255;
  final blue = b / 255;
  final high = math.max(red, math.max(green, blue));
  final low = math.min(red, math.min(green, blue));
  final lightness = (high + low) / 2;
  final delta = high - low;
  final saturation = delta == 0 ? 0.0 : delta / (1 - (2 * lightness - 1).abs());

  if (saturation < 0.14 || lightness < 0.1 || lightness > 0.93) {
    if (lightness < 0.2) return 'black';
    if (lightness > 0.85) return 'white';
    return 'grey';
  }

  double hue;
  if (delta == 0) {
    hue = 0;
  } else if (high == red) {
    hue = 60 * (((green - blue) / delta) % 6);
  } else if (high == green) {
    hue = 60 * ((blue - red) / delta + 2);
  } else {
    hue = 60 * ((red - green) / delta + 4);
  }
  if (hue < 0) hue += 360;

  // Warm, softly coloured, light: beige. Warm and dark: brown.
  if (hue >= 15 && hue < 50) {
    if (lightness > 0.62 && saturation < 0.6) return 'beige';
    if (lightness < 0.42) return 'brown';
  }
  if (hue < 15 || hue >= 345) {
    if (lightness > 0.72) return 'pink';
    if (lightness < 0.3 && saturation < 0.5) return 'brown';
    return 'red';
  }
  if (hue < 40) return 'orange';
  if (hue < 70) return 'yellow';
  if (hue < 170) return 'green';
  if (hue < 260) return 'blue';
  if (hue < 300) return 'purple';
  return 'pink';
}

/// The colours of the garment in an RGBA pixel buffer, most to least
/// covering, at most [max]. Empty only for a picture with no visible pixels.
List<String> dominantColours(
  Uint8List rgba,
  int width,
  int height, {
  int max = 2,
}) {
  final weights = <String, double>{};
  var total = 0.0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      if (rgba[i + 3] < 128) continue;
      // The middle 60% of the picture counts fully, the edges a third.
      final centre =
          x >= width * 0.2 &&
          x < width * 0.8 &&
          y >= height * 0.2 &&
          y < height * 0.8;
      final weight = centre ? 1.0 : 0.33;
      final name = colourNameOf(rgba[i], rgba[i + 1], rgba[i + 2]);
      weights[name] = (weights[name] ?? 0) + weight;
      total += weight;
    }
  }
  if (total == 0) return const [];
  final ranked = weights.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final chosen = [
    for (final entry in ranked)
      if (entry.value / total >= kMinColourShare) entry.key,
  ];
  return List.unmodifiable(
    (chosen.isEmpty ? [ranked.first.key] : chosen).take(max),
  );
}

/// The colours in a photo file, or empty if it can't be read.
Future<List<String>> coloursFromFile(File file) async {
  try {
    final codec = await ui.instantiateImageCodec(
      await file.readAsBytes(),
      targetWidth: 64,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final colours = data == null
        ? const <String>[]
        : dominantColours(data.buffer.asUint8List(), image.width, image.height);
    image.dispose();
    codec.dispose();
    return colours;
  } on Exception catch (error) {
    debugPrint('Could not read colours from the photo: $error');
    return const [];
  }
}
