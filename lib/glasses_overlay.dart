import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:ui' as ui;

class GlassesOverlay extends StatelessWidget {
  final List<Face> faces;
  final Size previewSize;
  final ui.Image? glassesImage;

  const GlassesOverlay({
    super.key,
    required this.faces,
    required this.previewSize,
    this.glassesImage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: GlassesPainter(
          faces: faces,
          previewSize: previewSize,
          glassesImage: glassesImage,
        ),
      ),
    );
  }
}

class GlassesPainter extends CustomPainter {
  final List<Face> faces;
  final Size previewSize;
  final ui.Image? glassesImage;

  GlassesPainter({
    required this.faces,
    required this.previewSize,
    this.glassesImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // With BoxFit.cover on the parent, we ensure aspect ratio is preserved.
    // Coordinates from ML Kit are in the camera's coordinate system.
    // If the sensor is 720x1280 (portrait), ML Kit coordinates will be in that range.
    
    final double scaleX = size.width / previewSize.height;
    final double scaleY = size.height / previewSize.width;

    for (final face in faces) {
      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];

      if (leftEye != null && rightEye != null) {
        // We use the raw coordinates because scaleX/scaleY should be 1.0 or 
        // consistent if we are in the same aspect ratio box.
        final double leftX = leftEye.position.x.toDouble() * scaleX;
        final double leftY = leftEye.position.y.toDouble() * scaleY;
        final double rightX = rightEye.position.x.toDouble() * scaleX;
        final double rightY = rightEye.position.y.toDouble() * scaleY;

        final center = Offset((leftX + rightX) / 2, (leftY + rightY) / 2);
        final eyeVector = Offset(rightX - leftX, rightY - leftY);
        final distance = eyeVector.distance;
        
        // Use a more appropriate width factor for glasses
        final glassesWidth = distance * 2.3;
        
        if (glassesImage != null) {
          final glassesHeight = glassesWidth * (glassesImage!.height / glassesImage!.width);
          final double angle = eyeVector.direction;

          canvas.save();
          
          // Translate to center and rotate
          canvas.translate(center.dx, center.dy);
          canvas.rotate(angle);

          // Position glasses slightly above eye line (typical for bridge of nose)
          final verticalOffset = -glassesHeight * 0.1;

          final imageRect = Rect.fromCenter(
            center: Offset(0, verticalOffset),
            width: glassesWidth,
            height: glassesHeight,
          );

          paintImage(
            canvas: canvas,
            rect: imageRect,
            image: glassesImage!,
            fit: BoxFit.contain,
          );

          canvas.restore();
        }
      }
    }
  }

  @override
  bool shouldRepaint(GlassesPainter oldDelegate) {
    return true; // Repaint always while debugging
  }
}
