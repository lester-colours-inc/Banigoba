// Verifies picking garment colours from pixels (W-3).
import 'dart:typed_data';

import 'package:banigoba/core/utils/garment_colour.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [size]x[size] picture filled with [fill], with [patch] in the middle
/// (a share of the width, 0 for none).
Uint8List _picture(
  List<int> fill, {
  List<int>? patch,
  double patchShare = 0.6,
  int size = 20,
  int alpha = 255,
}) {
  final bytes = Uint8List(size * size * 4);
  final lo = (size * (1 - patchShare) / 2).floor();
  final hi = size - lo;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final inPatch = patch != null && x >= lo && x < hi && y >= lo && y < hi;
      final c = inPatch ? patch : fill;
      final i = (y * size + x) * 4;
      bytes[i] = c[0];
      bytes[i + 1] = c[1];
      bytes[i + 2] = c[2];
      bytes[i + 3] = alpha;
    }
  }
  return bytes;
}

void main() {
  group('colourNameOf', () {
    test('names clear colours with the wardrobe words', () {
      const expected = {
        'red': [200, 30, 30],
        'orange': [245, 140, 30],
        'yellow': [240, 220, 40],
        'green': [40, 160, 70],
        'blue': [30, 70, 200],
        'purple': [130, 50, 190],
        'pink': [240, 130, 190],
      };
      expected.forEach((name, rgb) {
        expect(colourNameOf(rgb[0], rgb[1], rgb[2]), name, reason: name);
      });
    });

    test('names neutrals by lightness', () {
      expect(colourNameOf(10, 10, 10), 'black');
      expect(colourNameOf(128, 128, 128), 'grey');
      expect(colourNameOf(250, 250, 250), 'white');
    });

    test('tells brown and beige from orange and yellow', () {
      expect(colourNameOf(110, 70, 40), 'brown');
      expect(colourNameOf(222, 200, 165), 'beige');
      expect(colourNameOf(245, 140, 30), 'orange');
    });

    test('every name it returns is one the form offers', () {
      for (var r = 0; r < 256; r += 51) {
        for (var g = 0; g < 256; g += 51) {
          for (var b = 0; b < 256; b += 51) {
            expect(kGarmentColours, contains(colourNameOf(r, g, b)));
          }
        }
      }
    });
  });

  group('dominantColours', () {
    test('a plain garment gives one colour', () {
      final pixels = _picture([30, 70, 200]);
      expect(dominantColours(pixels, 20, 20), ['blue']);
    });

    test('the middle of the picture beats a different background', () {
      // A red garment against a white wall.
      final pixels = _picture([250, 250, 250], patch: [200, 30, 30]);
      expect(dominantColours(pixels, 20, 20).first, 'red');
    });

    test('a two-colour garment gives both, biggest first', () {
      final pixels = _picture([30, 70, 200], patch: [250, 250, 250]);
      expect(dominantColours(pixels, 20, 20), ['white', 'blue']);
    });

    test('a small speck is not suggested', () {
      final pixels = _picture(
        [30, 70, 200],
        patch: [200, 30, 30],
        patchShare: 0.15,
      );
      expect(dominantColours(pixels, 20, 20), ['blue']);
    });

    test('transparent pixels are ignored', () {
      final pixels = _picture([30, 70, 200], alpha: 0);
      expect(dominantColours(pixels, 20, 20), isEmpty);
    });

    test('at most the requested number of colours', () {
      final pixels = _picture([30, 70, 200], patch: [250, 250, 250]);
      expect(dominantColours(pixels, 20, 20, max: 1), hasLength(1));
    });
  });
}
