import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'dart:ui' as ui;

/// A universal overlay widget that can display glasses or clothes based on detected features
class ArOverlay extends StatelessWidget {
  final List<Face> faces;
  final List<Pose> poses;
  final SegmentationMask? mask;
  final Size previewSize;
  final ui.Image? overlayImage;
  final String category;

  const ArOverlay({
    super.key,
    this.faces = const [],
    this.poses = const [],
    this.mask,
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
          poses: poses,
          mask: mask,
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
  final List<Pose> poses;
  final SegmentationMask? mask;
  final Size previewSize;
  final ui.Image? overlayImage;
  final String category;

  ArPainter({
    required this.faces,
    required this.poses,
    required this.mask,
    required this.previewSize,
    this.overlayImage,
    required this.category,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale coordinates from camera resolution to screen resolution
    final double scaleX = size.width / previewSize.height;
    final double scaleY = size.height / previewSize.width;

    if (mask != null) {
      _paintMask(canvas, size);
    }

    if (overlayImage == null) return;

    final cat = category.toLowerCase();

    if (cat.contains('accessories') || cat.contains('glasses') || cat.contains('hats')) {
      for (final face in faces) {
        _paintGlasses(canvas, face, scaleX, scaleY);
      }
    } else if (cat.contains('tops') || cat.contains('outerwear') || cat.contains('shirts')) {
      for (final pose in poses) {
        _paintShirtOnPose(canvas, pose, scaleX, scaleY);
      }
    } else if (cat.contains('bottoms')) {
      for (final pose in poses) {
        _paintPantsOnPose(canvas, pose, scaleX, scaleY);
      }
    }
  }

  void _paintMask(Canvas canvas, Size size) {
    // Implementation for drawing the segmentation mask could go here
    // For now, we focus on the pose-based overlays
  }

  void _paintShirtOnPose(Canvas canvas, Pose pose, double scaleX, double scaleY) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder != null && rightShoulder != null) {
      final double lsX = leftShoulder.x * scaleX;
      final double lsY = leftShoulder.y * scaleY;
      final double rsX = rightShoulder.x * scaleX;
      final double rsY = rightShoulder.y * scaleY;

      final shoulderCenter = Offset((lsX + rsX) / 2, (lsY + rsY) / 2);
      final shoulderVector = Offset(rsX - lsX, rsY - lsY);
      final shoulderWidth = shoulderVector.distance;
      
      // Calculate rotation based on shoulder slope
      final double angle = shoulderVector.direction;

      // Determine height based on distance to hips if available, otherwise estimate
      double shirtHeight;
      if (leftHip != null && rightHip != null) {
        final double hipY = (leftHip.y + rightHip.y) / 2 * scaleY;
        shirtHeight = (hipY - shoulderCenter.dy) * 1.2; // Extra length for coverage
      } else {
        shirtHeight = shoulderWidth * 1.2; 
      }

      final shirtWidth = shoulderWidth * 1.8; // Broaden for sleeves

      canvas.save();
      canvas.translate(shoulderCenter.dx, shoulderCenter.dy);
      canvas.rotate(angle);

      final rect = Rect.fromCenter(
        center: Offset(0, shirtHeight / 2.5), // Offset downward from shoulder line
        width: shirtWidth,
        height: shirtHeight,
      );

      paintImage(
        canvas: canvas,
        rect: rect,
        image: overlayImage!,
        fit: BoxFit.contain,
      );
      canvas.restore();
    }
  }

  void _paintPantsOnPose(Canvas canvas, Pose pose, double scaleX, double scaleY) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

    if (leftHip != null && rightHip != null) {
      final double lhX = leftHip.x * scaleX;
      final double lhY = leftHip.y * scaleY;
      final double rhX = rightHip.x * scaleX;
      final double rhY = rightHip.y * scaleY;

      final hipCenter = Offset((lhX + rhX) / 2, (lhY + rhY) / 2);
      final hipVector = Offset(rhX - lhX, rhY - lhY);
      final hipWidth = hipVector.distance;
      final double angle = hipVector.direction;

      double pantsHeight;
      if (leftKnee != null && rightKnee != null) {
        final double kneeY = (leftKnee.y + rightKnee.y) / 2 * scaleY;
        pantsHeight = (kneeY - hipCenter.dy) * 2.2; // Extend to feet
      } else {
        pantsHeight = hipWidth * 2.5;
      }

      canvas.save();
      canvas.translate(hipCenter.dx, hipCenter.dy);
      canvas.rotate(angle);

      final rect = Rect.fromCenter(
        center: Offset(0, pantsHeight / 2.2),
        width: hipWidth * 1.5,
        height: pantsHeight,
      );

      paintImage(
        canvas: canvas,
        rect: rect,
        image: overlayImage!,
        fit: BoxFit.contain,
      );
      canvas.restore();
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

  @override
  bool shouldRepaint(ArPainter oldDelegate) => true;
}
