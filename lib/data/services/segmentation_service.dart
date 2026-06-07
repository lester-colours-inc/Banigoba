// Wraps ML Kit selfie segmentation to separate people from camera backgrounds.
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:camera/camera.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';

/// Service for segmenting the user from the background using Google ML Kit
class SegmentationService {
  final SelfieSegmenter _segmenter = SelfieSegmenter(
    mode: SegmenterMode.stream,
    enableRawSizeMask: true,
  );

  /// Processes a single frame and returns a mask where person is segmented
  Future<SegmentationMask?> processImage(CameraImage image, CameraDescription camera) async {
    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: _rotationIntToInputImageRotation(camera.sensorOrientation),
      format: _inputImageFormat(image.format.raw),
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);
    return await _segmenter.processImage(inputImage);
  }

  InputImageRotation _rotationIntToInputImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  InputImageFormat _inputImageFormat(int format) {
    return InputImageFormatValue.fromRawValue(format) ?? InputImageFormat.nv21;
  }

  void dispose() {
    _segmenter.close();
  }
}
