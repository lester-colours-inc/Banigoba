import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:ui' as ui;

/// A universal overlay widget that can display glasses or clothes based on detected faces
class ArOverlay extends StatelessWidget {
  final List<Face> faces;
  final Size previewSize;
  final ui.Image? overlayImage;
  final String category;

  const ArOverlay({
    super.key,
    required this.faces,
    required this.previewSize,
    this.overlayImage,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: ArPainter(
          faces: faces,
          previewSize: previewSize,
          overlayImage: overlayImage,
          category: category,
        ),
      ),
    );
  }
}

class ArPainter extends CustomPainter {
  final List<Face> faces;
  final Size previewSize;
  final ui.Image? overlayImage;
  final String category;

  ArPainter({
    required this.faces,
    required this.previewSize,
    this.overlayImage,
    required this.category,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (overlayImage == null) return;

    // Scale coordinates from camera resolution to screen resolution
    final double scaleX = size.width / previewSize.height;
    final double scaleY = size.height / previewSize.width;

    for (final face in faces) {
      if (category.toLowerCase().contains('accessories') || category.toLowerCase().contains('glasses')) {
        _paintGlasses(canvas, face, scaleX, scaleY);
      } else if (category.toLowerCase().contains('tops') || category.toLowerCase().contains('outerwear') || category.toLowerCase().contains('shirts')) {
        _paintClothes(canvas, face, scaleX, scaleY);
      }
    }
  }

  void _paintGlasses(Canvas canvas, Face face, double scaleX, double scaleY) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    if (leftEye != null && rightEye != null) {
      final double leftX = leftEye.position.x.toDouble() * scaleX;
      final double leftY = leftEye.position.y.toDouble() * scaleY;
      final double rightX = rightEye.position.x.toDouble() * scaleX;
      final double rightY = rightEye.position.y.toDouble() * scaleY;

      final center = Offset((leftX + rightX) / 2, (leftY + rightY) / 2);
      final eyeVector = Offset(rightX - leftX, rightY - leftY);
      final distance = eyeVector.distance;
      
      final glassesWidth = distance * 2.3;
      final glassesHeight = glassesWidth * (overlayImage!.height / overlayImage!.width);
      final double angle = eyeVector.direction;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final imageRect = Rect.fromCenter(
        center: Offset(0, -glassesHeight * 0.1),
        width: glassesWidth,
        height: glassesHeight,
      );

      paintImage(
        canvas: canvas,
        rect: imageRect,
        image: overlayImage!,
        fit: BoxFit.contain,
      );
      canvas.restore();
    }
  }

  void _paintClothes(Canvas canvas, Face face, double scaleX, double scaleY) {
    // Estimate neck and torso position based on face bounds
    final Rect faceRect = Rect.fromLTRB(
      face.boundingBox.left * scaleX,
      face.boundingBox.top * scaleY,
      face.boundingBox.right * scaleX,
      face.boundingBox.bottom * scaleY,
    );

    final double faceWidth = faceRect.width;
    final double faceHeight = faceRect.height;
    
    // The top of the shirt is roughly 0.4 face-heights below the bottom of the face
    final double shirtTopY = faceRect.bottom + (faceHeight * 0.2);
    final Offset shirtCenter = Offset(faceRect.center.dx, shirtTopY + (faceHeight * 1.2));
    
    // Shoulders are typically 2.5 to 3 times wider than the face
    final double shirtWidth = faceWidth * 3.5;
    final double shirtHeight = shirtWidth * (overlayImage!.height / overlayImage!.width);

    final imageRect = Rect.fromCenter(
      center: Offset(shirtCenter.dx, shirtCenter.dy),
      width: shirtWidth,
      height: shirtHeight,
    );

    // Simple rotation based on face tilt (if available)
    final double angle = (face.headEulerAngleZ ?? 0) * (3.14159 / 180);

    canvas.save();
    canvas.translate(shirtCenter.dx, shirtCenter.dy);
    canvas.rotate(angle);
    
    final Rect centeredRect = Rect.fromCenter(
      center: Offset.zero,
      width: shirtWidth,
      height: shirtHeight,
    );

    paintImage(
      canvas: canvas,
      rect: centeredRect,
      image: overlayImage!,
      fit: BoxFit.contain,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(ArPainter oldDelegate) => true;
}
