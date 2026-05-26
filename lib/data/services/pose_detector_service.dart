import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';

/// Service for detecting body poses in camera images using Google ML Kit
class PoseDetectorService {
  // Initialize the ML Kit Pose Detector
  // Using base PoseDetector with default options (accurate mode)
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    ),
  );

  /// Processes a single frame from the camera stream and returns detected poses
  Future<List<Pose>> processImage(CameraImage image, CameraDescription camera) async {
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
    return await _poseDetector.processImage(inputImage);
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
    _poseDetector.close();
  }
}
