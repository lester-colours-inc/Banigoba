// Wraps ML Kit face detection for camera frames used by AR overlays.
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';

/// Service for detecting faces in camera images using Google ML Kit
class FaceDetectorService {
  // Initialize the ML Kit Face Detector with high-performance settings
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,   // Allows for overlaying shapes (like glasses) precisely
      enableLandmarks: true,  // Detects eyes, nose, mouth locations
      performanceMode: FaceDetectorMode.fast, // Optimized for real-time video
    ),
  );

  /// Processes a single frame from the camera stream and returns detected faces
  Future<List<Face>> processImage(CameraImage image, CameraDescription camera) async {
    if (image.planes.isEmpty) return [];

    // Convert multi-plane camera image into a flat byte array
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // Set up metadata for ML Kit (size, rotation, and pixel format)
    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: _rotationIntToInputImageRotation(camera.sensorOrientation),
      format: _inputImageFormat(image.format.raw),
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    // Create the input image and process it
    final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);
    return await _faceDetector.processImage(inputImage);
  }

  /// Maps camera sensor orientation to ML Kit InputImageRotation
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

  /// Maps raw camera format integers to ML Kit InputImageFormat
  InputImageFormat _inputImageFormat(int format) {
    return InputImageFormatValue.fromRawValue(format) ?? InputImageFormat.nv21;
  }

  /// Clean up resources when the service is no longer needed
  void dispose() {
    _faceDetector.close();
  }
}
