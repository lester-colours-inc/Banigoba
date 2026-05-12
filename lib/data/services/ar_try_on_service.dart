import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Service to handle loading and processing images for AR overlays
class ArTryOnService {
  /// Loads an image from a network URL or local asset
  Future<ui.Image?> loadImage(String path) async {
    try {
      Uint8List bytes;
      if (path.startsWith('http')) {
        // Load from network
        final Uri uri = Uri.parse(path);
        final HttpClient client = HttpClient();
        final HttpClientRequest request = await client.getUrl(uri);
        final HttpClientResponse response = await request.close();
        bytes = await consolidateHttpClientResponseBytes(response);
      } else {
        // Load from assets
        final data = await rootBundle.load(path);
        bytes = data.buffer.asUint8List();
      }

      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      return frameInfo.image;
    } catch (e) {
      debugPrint("Error loading AR image: $e");
      return null;
    }
  }
}
